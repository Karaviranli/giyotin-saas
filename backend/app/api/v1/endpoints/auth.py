import random
import string
from datetime import datetime, timedelta
from fastapi import APIRouter, Depends, HTTPException, status, Request
from fastapi.security import OAuth2PasswordRequestForm
from jose import jwt, JWTError
from fastapi_mail import FastMail, MessageSchema, ConnectionConfig, MessageType
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.models.user import User
from app.models.company import Company
from app.core.security import verify_password, get_password_hash, create_access_token
from app.core.config import settings
from pydantic import BaseModel, field_validator, model_validator
from app.core.dependencies import get_current_active_user
from app.core.limiter import limiter

router = APIRouter()

# ── Geçici doğrulama kodu store (in-memory, restart'ta sıfırlanır) ───────
# E-posta -> {"code": "123456", "expires_at": datetime}
_VERIFICATION_CODES: dict = {}
_VERIFICATION_TTL_MIN = 15  # kod 15 dk geçerli
_VERIFICATION_COOLDOWN_SEC = 15  # aynı maile 15sn'den önce tekrar gönderme

# ── Kullanılmış reset token'ları (tek-kullanımlık koruma) ────────────────
# token (JWT) -> kullanım tarihi. 24 saat sonra otomatik temizlenir.
_USED_RESET_TOKENS: dict = {}

def _gc_used_tokens():
    """24 saatten eski kullanılmış token'ları temizler."""
    now = datetime.utcnow()
    expired = [t for t, used_at in _USED_RESET_TOKENS.items()
               if (now - used_at).total_seconds() > 86400]
    for t in expired:
        _USED_RESET_TOKENS.pop(t, None)

def _generate_code() -> str:
    return ''.join(random.choices(string.digits, k=6))

def _verify_code(email: str, code: str) -> bool:
    entry = _VERIFICATION_CODES.get(email.lower().strip())
    if not entry:
        return False
    if datetime.utcnow() > entry["expires_at"]:
        _VERIFICATION_CODES.pop(email.lower().strip(), None)
        return False
    return entry["code"] == code.strip()

# fastapi-mail bağlantı ayarları
mail_conf = ConnectionConfig(
    MAIL_USERNAME=settings.MAIL_USERNAME,
    MAIL_PASSWORD=settings.MAIL_PASSWORD,
    MAIL_FROM=settings.MAIL_FROM,
    MAIL_PORT=settings.MAIL_PORT,
    MAIL_SERVER=settings.MAIL_SERVER,
    MAIL_FROM_NAME=settings.MAIL_FROM_NAME,
    MAIL_STARTTLS=settings.MAIL_STARTTLS,
    MAIL_SSL_TLS=settings.MAIL_SSL_TLS,
    USE_CREDENTIALS=True,
    VALIDATE_CERTS=True
)

# Geçici (Disposable) e-posta servislerinin temel kara listesi
DISPOSABLE_DOMAINS = {
    "10minutemail.com", "temp-mail.org", "guerrillamail.com", "mailinator.com",
    "yopmail.com", "throwawaymail.com", "tempmail.com", "tempmail.net",
    "getairmail.com", "dispostable.com", "maildrop.cc", "sharklasers.com",
    "fakemail.net", "nowhere.com", "trashmail.com", "mailnesia.com"
    # Not: Daha kapsamlı bir koruma için ileride 'mailboxlayer' gibi bir API kullanılabilir.
}

# Flutter'dan gelen JSON verisinin şablonu
class RegisterRequest(BaseModel):
    full_name: str
    email: str
    password: str
    password_confirm: str
    company_name: str
    kvkk_accepted: bool
    verification_code: str  # 6 haneli e-posta doğrulama kodu

    @field_validator('password')
    @classmethod
    def password_min_length(cls, v: str) -> str:
        if len(v) < 8:
            raise ValueError('Şifre en az 8 karakter olmalıdır.')
        return v

    @field_validator('email')
    @classmethod
    def email_format(cls, v: str) -> str:
        if "@" not in v or "." not in v:
            raise ValueError('Geçerli bir e-posta adresi giriniz.')
        
        domain = v.split('@')[-1].lower()
        if domain in DISPOSABLE_DOMAINS:
            raise ValueError('Geçici (tek kullanımlık) e-posta adresleri ile kayıt olunamaz. Lütfen şirket e-postanızı giriniz.')
        return v

    @model_validator(mode='after')
    def check_passwords_match(self) -> 'RegisterRequest':
        if self.password != self.password_confirm:
            raise ValueError('Şifreler birbiriyle eşleşmiyor.')
        return self
        
    @field_validator('kvkk_accepted')
    @classmethod
    def check_kvkk(cls, v: bool) -> bool:
        if not v:
            raise ValueError('Kayıt olmak için Kullanıcı Sözleşmesi ve Gizlilik Politikasını onaylamalısınız.')
        return v

class ForgotPasswordRequest(BaseModel):
    email: str

class ResetPasswordRequest(BaseModel):
    token: str
    new_password: str
    password_confirm: str

    @field_validator('new_password')
    @classmethod
    def password_min_length(cls, v: str) -> str:
        if len(v) < 8:
            raise ValueError('Şifre en az 8 karakter olmalıdır.')
        return v

    @model_validator(mode='after')
    def check_passwords_match(self) -> 'ResetPasswordRequest':
        if self.new_password != self.password_confirm:
            raise ValueError('Şifreler birbiriyle eşleşmiyor.')
        return self

class UpdateProfileRequest(BaseModel):
    full_name: str
    email: str

class UpdatePasswordRequest(BaseModel):
    current_password: str
    new_password: str
    password_confirm: str

@router.post("/register")
@limiter.limit("3/minute")
async def register(request: Request, req: RegisterRequest, db: Session = Depends(get_db)):
    # 0. Doğrulama kodu kontrolü
    if not _verify_code(req.email, req.verification_code):
        raise HTTPException(status_code=400, detail="Doğrulama kodu hatalı veya süresi dolmuş. Lütfen yeni kod isteyin.")

    # 1. E-posta sistemde var mı?
    user = db.query(User).filter(User.email == req.email).first()
    if user:
        raise HTTPException(status_code=400, detail="Bu e-posta zaten kayıtlı.")
    
    # 2. Şirketi oluştur ve veritabanına kaydet
    new_company = Company(name=req.company_name)
    db.add(new_company)
    db.commit()
    db.refresh(new_company)

    # ── YENİ ŞİRKET → OTOMATİK DEFAULT CompanySettings (BUG FIX 2026-06-14) ──
    # Önceden sadece Company yaratılıyordu, CompanySettings yoktu → giyotin hesabı
    # null fiyat alanlarıyla çalışıyordu. Şimdi tüm default değerlerle otomatik kayıt.
    from app.models.company_settings import CompanySettings
    default_settings = CompanySettings(company_id=new_company.id)
    db.add(default_settings)

    # --- YENİ EKLENTİ: YENİ ŞİRKETE OTOMATİK 14 GÜNLÜK DENEME SÜRÜMÜ ---
    from datetime import datetime, timedelta
    from app.models.subscription import Subscription
    trial_sub = Subscription(
        company_id=new_company.id,
        plan_name="14 Günlük Deneme",
        price=0.0,
        start_date=datetime.utcnow(),
        end_date=datetime.utcnow() + timedelta(days=14),
        is_active=True
    )
    db.add(trial_sub)
    # -----------------------------------------------------------------

    # 3. Kullanıcıyı oluştur, şifresini kriptola ve şirkete bağla
    new_user = User(
        email=req.email,
        hashed_password=get_password_hash(req.password),
        full_name=req.full_name,
        company_id=new_company.id,
        is_company_admin=True
    )
    db.add(new_user)
    db.commit()
    
    # Doğrulama kodu kullanıldı, sil
    _VERIFICATION_CODES.pop(req.email.lower().strip(), None)

    # ── Hoş geldin maili gönder (best-effort, başarısız olursa kayıt yine başarılı) ──
    try:
        from app.core.email_templates import welcome_email
        html = welcome_email(full_name=req.full_name, trial_days=14)
        msg = MessageSchema(
            subject="Kavira'ya Hoş Geldin 🎉 — 14 Günlük Deneme Başladı",
            recipients=[req.email],
            body=html,
            subtype=MessageType.html,
        )
        fm = FastMail(mail_conf)
        await fm.send_message(msg)
    except Exception as e:
        import logging
        logging.getLogger(__name__).warning(f"Hoş geldin maili gönderilemedi ({req.email}): {e}")

    return {"message": "Kayıt başarılı. Hoş geldin maili gönderildi 🎉"}


# ── E-POSTA DOĞRULAMA KODU GÖNDERME ─────────────────────────────────────
class SendVerificationCodeRequest(BaseModel):
    email: str

    @field_validator('email')
    @classmethod
    def email_format(cls, v: str) -> str:
        if "@" not in v or "." not in v:
            raise ValueError('Geçerli bir e-posta adresi giriniz.')
        domain = v.split('@')[-1].lower()
        if domain in DISPOSABLE_DOMAINS:
            raise ValueError('Geçici e-posta adresleri kabul edilmez.')
        return v.lower().strip()


@router.post("/send-verification-code")
@limiter.limit("20/minute")
async def send_verification_code(
    request: Request,
    req: SendVerificationCodeRequest,
    db: Session = Depends(get_db),
):
    """Kayıt için 6 haneli doğrulama kodunu maille gönderir."""
    email = req.email

    # Önceden kayıtlıysa, anonim cevap (var olduğunu söylemiyoruz ama
    # yeni kayıt için gönderme — register'da zaten 'zaten var' uyarısı çıkar)
    user = db.query(User).filter(User.email == email).first()
    if user:
        raise HTTPException(status_code=400, detail="Bu e-posta zaten kayıtlı. Giriş yapmayı deneyin.")

    # Cooldown — aynı maile çok sık gönderme
    existing = _VERIFICATION_CODES.get(email)
    if existing:
        gecen = (datetime.utcnow() - existing.get("sent_at", datetime.utcnow())).total_seconds()
        if gecen < _VERIFICATION_COOLDOWN_SEC:
            kalan = int(_VERIFICATION_COOLDOWN_SEC - gecen)
            raise HTTPException(
                status_code=429,
                detail=f"Çok sık talep. {kalan} saniye bekleyip tekrar deneyin."
            )

    code = _generate_code()
    _VERIFICATION_CODES[email] = {
        "code": code,
        "expires_at": datetime.utcnow() + timedelta(minutes=_VERIFICATION_TTL_MIN),
        "sent_at": datetime.utcnow(),
    }

    try:
        from app.core.email_templates import verification_code_email
        html = verification_code_email(code=code, expire_minutes=_VERIFICATION_TTL_MIN)
        msg = MessageSchema(
            subject=f"Kavira — Doğrulama Kodu: {code}",
            recipients=[email],
            body=html,
            subtype=MessageType.html,
        )
        fm = FastMail(mail_conf)
        await fm.send_message(msg)
    except Exception as e:
        _VERIFICATION_CODES.pop(email, None)
        import logging
        logging.getLogger(__name__).warning(f"Doğrulama mail hatası ({email}): {e}")
        raise HTTPException(status_code=500, detail=f"E-posta gönderilemedi: {str(e)[:120]}")

    return {"message": "Doğrulama kodu gönderildi. Lütfen e-posta kutunuzu kontrol edin."}

@router.post("/login")
@limiter.limit("5/minute")
def login(request: Request, form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    # Kullanıcıyı e-posta ile bul
    user = db.query(User).filter(User.email == form_data.username).first()
    
    # Şifreyi kontrol et
    if not user or not verify_password(form_data.password, user.hashed_password):
        raise HTTPException(status_code=400, detail="E-posta veya şifre hatalı")
    
    # JWT Access Token üret
    access_token = create_access_token(data={"sub": str(user.id)})
    return {"access_token": access_token, "token_type": "bearer"}

@router.post("/forgot-password")
@limiter.limit("3/minute")
async def forgot_password(request: Request, req: ForgotPasswordRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == req.email).first()
    if not user:
        # Güvenlik: kullanıcının varlığını sızdırmamak için her zaman olumlu cevap
        return {"message": "E-posta adresi sistemde kayıtlıysa sıfırlama talimatları gönderilecektir."}

    # Tek-kullanımlık + 15 dk geçerli token
    reset_token = create_access_token(
        data={"sub": str(user.id), "scope": "password_reset"},
        expires_delta=timedelta(minutes=15)
    )
    reset_link = f"https://kaviragiyotin.online/app/reset-password?token={reset_token}"

    # İstemci IP + tarayıcı bilgisi (güvenlik için maile dahil edilir)
    client_ip = request.client.host if request.client else "bilinmiyor"
    # Nginx proxy arkasındaysak gerçek IP X-Forwarded-For başlığında
    fwd = request.headers.get("x-forwarded-for")
    if fwd:
        client_ip = fwd.split(",")[0].strip()
    user_agent = request.headers.get("user-agent", "bilinmiyor")[:200]

    try:
        from app.core.email_templates import reset_password_email
        html = reset_password_email(
            full_name=user.full_name or user.email,
            reset_link=reset_link,
        )
        # Template'in sonuna güvenlik bilgisi ekle
        guvenlik_notu = f"""
        <div style="background:#FEF3C7;border:1px solid #FDE68A;border-left:4px solid #F59E0B;border-radius:8px;padding:14px 18px;margin:20px 0;font-size:13px;color:#92400E;">
          <strong>Güvenlik bilgisi</strong><br>
          Bu istek <code>{client_ip}</code> adresinden geldi.<br>
          <span style="font-size:11px;color:#78350F;">Tarayıcı: {user_agent[:80]}...</span><br>
          Bu işlemi sen yapmadıysan bu maili yok say. Şifren değiştirilmedi.
        </div>"""
        # Body'nin sonuna eklemek için </body>'den önce inject
        html = html.replace("</body>", guvenlik_notu + "</body>")

        msg = MessageSchema(
            subject="Kavira — Şifre Sıfırlama (15 dk geçerli)",
            recipients=[user.email],
            body=html,
            subtype=MessageType.html,
        )
        fm = FastMail(mail_conf)
        await fm.send_message(msg)
    except Exception as e:
        import logging
        logging.getLogger(__name__).warning(f"Sıfırlama maili gönderilemedi ({user.email}): {e}")
        raise HTTPException(status_code=500, detail="E-posta gönderilirken bir sorun oluştu. Lütfen tekrar deneyin.")

    return {"message": "Sıfırlama talimatları e-posta adresinize gönderildi. (15 dk geçerli)"}


@router.post("/reset-password")
def reset_password(req: ResetPasswordRequest, db: Session = Depends(get_db)):
    # 1. Token kullanılmış mı kontrolü (tek-kullanımlık koruma)
    _gc_used_tokens()
    if req.token in _USED_RESET_TOKENS:
        raise HTTPException(status_code=400, detail="Bu sıfırlama bağlantısı zaten kullanıldı. Yeni bir bağlantı isteyin.")

    # 2. Token'ı ve scope'u doğrula
    try:
        payload = jwt.decode(req.token, settings.SECRET_KEY, algorithms=["HS256"])
        if payload.get("scope") != "password_reset":
            raise HTTPException(status_code=400, detail="Geçersiz işlem tipi.")
        user_id = payload.get("sub")
    except JWTError:
        raise HTTPException(status_code=400, detail="Geçersiz veya süresi dolmuş bağlantı. Yeni bir tane isteyin.")

    # 3. Kullanıcıyı bul
    user = db.query(User).filter(User.id == int(user_id)).first()
    if not user:
        raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı.")

    # 4. Şifreyi güncelle
    user.hashed_password = get_password_hash(req.new_password)
    db.commit()

    # 5. Token'ı kullanılmış olarak işaretle
    _USED_RESET_TOKENS[req.token] = datetime.utcnow()

    return {"message": "Şifren başarıyla güncellendi 🎉 Yeni şifrenle giriş yapabilirsin."}

@router.get("/me")
def get_me(current_user: User = Depends(get_current_active_user)):
    return {
        "id": current_user.id,
        "full_name": current_user.full_name,
        "email": current_user.email,
        "is_superuser": bool(getattr(current_user, "is_superuser", False)),
        "is_company_admin": bool(getattr(current_user, "is_company_admin", False)),
        "is_active": bool(getattr(current_user, "is_active", True)),
    }

@router.put("/me")
def update_me(req: UpdateProfileRequest, db: Session = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    if req.email != current_user.email:
        existing_user = db.query(User).filter(User.email == req.email).first()
        if existing_user:
            raise HTTPException(status_code=400, detail="Bu e-posta adresi zaten kullanılıyor.")
    
    current_user.full_name = req.full_name
    current_user.email = req.email
    db.commit()
    return {"message": "Profil başarıyla güncellendi."}

@router.put("/me/password")
def update_my_password(req: UpdatePasswordRequest, db: Session = Depends(get_db), current_user: User = Depends(get_current_active_user)):
    if not verify_password(req.current_password, current_user.hashed_password):
        raise HTTPException(status_code=400, detail="Mevcut şifreniz hatalı.")
    
    if req.new_password != req.password_confirm:
        raise HTTPException(status_code=400, detail="Yeni şifreler eşleşmiyor.")
    
    current_user.hashed_password = get_password_hash(req.new_password)
    db.commit()
    return {"message": "Şifreniz başarıyla güncellendi."}


# ── Trial expiry uyarı sistemi ──────────────────────────────────────────
# Hangi (company_id, mail_tipi) kombinasyonu için ne zaman uyarı atıldı?
# Aynı kullanıcıya günde 5 kez "trial bitmek üzere" maili atmamak için.
_TRIAL_NOTIFIED: dict = {}  # (company_id, type) -> datetime

@router.post("/_internal/check-trial-expirations")
@limiter.limit("12/hour")  # cron 1 saatte bir tetikleyebilir, manuel da çalışır
async def check_trial_expirations(request: Request, db: Session = Depends(get_db)):
    """Süresi yakında dolan veya yeni dolan abonelikler için uyarı maili gönderir.
    Cron'dan saat başı veya günde 1 kez çağrılır.
    """
    from app.models.subscription import Subscription
    from app.models.company import Company
    now = datetime.utcnow()
    notify_today_at_3 = now + timedelta(days=3)
    notify_today_at_1 = now + timedelta(days=1)

    sent = {"3_day": 0, "1_day": 0, "expired": 0, "errors": 0}

    # 3 gün kala
    subs_3 = db.query(Subscription).filter(
        Subscription.is_active == True,
        Subscription.end_date.isnot(None),
        Subscription.end_date >= notify_today_at_3 - timedelta(hours=1),
        Subscription.end_date <= notify_today_at_3 + timedelta(hours=23),
    ).all()
    for sub in subs_3:
        key = (sub.company_id, "3_day")
        last = _TRIAL_NOTIFIED.get(key)
        if last and (now - last).total_seconds() < 20 * 3600:
            continue  # son 20 saatte zaten atılmış
        admin = db.query(User).filter(
            User.company_id == sub.company_id,
            User.is_company_admin == True
        ).first()
        if not admin:
            continue
        try:
            html = _trial_warning_email(admin.full_name or "Kullanıcı",
                                       gun_kalan=3,
                                       bitis=sub.end_date.strftime("%d.%m.%Y"))
            await _send_mail(admin.email, "Kavira — Beta sürene 3 gün kaldı ⏳", html)
            _TRIAL_NOTIFIED[key] = now
            sent["3_day"] += 1
        except Exception:
            sent["errors"] += 1

    # 1 gün kala
    subs_1 = db.query(Subscription).filter(
        Subscription.is_active == True,
        Subscription.end_date.isnot(None),
        Subscription.end_date >= notify_today_at_1 - timedelta(hours=1),
        Subscription.end_date <= notify_today_at_1 + timedelta(hours=23),
    ).all()
    for sub in subs_1:
        key = (sub.company_id, "1_day")
        last = _TRIAL_NOTIFIED.get(key)
        if last and (now - last).total_seconds() < 20 * 3600:
            continue
        admin = db.query(User).filter(
            User.company_id == sub.company_id,
            User.is_company_admin == True
        ).first()
        if not admin:
            continue
        try:
            html = _trial_warning_email(admin.full_name or "Kullanıcı",
                                       gun_kalan=1,
                                       bitis=sub.end_date.strftime("%d.%m.%Y"))
            await _send_mail(admin.email, "Kavira — Beta süren yarın doluyor 🔔", html)
            _TRIAL_NOTIFIED[key] = now
            sent["1_day"] += 1
        except Exception:
            sent["errors"] += 1

    # Bugün dolanlar
    subs_expired = db.query(Subscription).filter(
        Subscription.is_active == False,
        Subscription.end_date.isnot(None),
        Subscription.end_date >= now - timedelta(hours=24),
        Subscription.end_date <= now + timedelta(hours=1),
    ).all()
    for sub in subs_expired:
        key = (sub.company_id, "expired")
        last = _TRIAL_NOTIFIED.get(key)
        if last and (now - last).total_seconds() < 20 * 3600:
            continue
        admin = db.query(User).filter(
            User.company_id == sub.company_id,
            User.is_company_admin == True
        ).first()
        if not admin:
            continue
        try:
            html = _trial_expired_email(admin.full_name or "Kullanıcı")
            await _send_mail(admin.email, "Kavira — Beta süren doldu, devam edelim mi? 💬", html)
            _TRIAL_NOTIFIED[key] = now
            sent["expired"] += 1
        except Exception:
            sent["errors"] += 1

    return {"sent": sent, "timestamp": now.isoformat()}


async def _send_mail(to: str, subject: str, html: str):
    msg = MessageSchema(
        subject=subject,
        recipients=[to],
        body=html,
        subtype=MessageType.html,
    )
    fm = FastMail(mail_conf)
    await fm.send_message(msg)


def _trial_warning_email(full_name: str, gun_kalan: int, bitis: str) -> str:
    """Trial 3 / 1 gün kala uyarı maili."""
    aciliyet = "kırmızı" if gun_kalan == 1 else "turuncu"
    renk = "#EF4444" if gun_kalan == 1 else "#F59E0B"
    return f"""<!DOCTYPE html>
<html><head><meta charset="UTF-8"></head>
<body style="margin:0;padding:0;background:#F1F5F9;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#F1F5F9;padding:40px 0;">
    <tr><td align="center">
      <table width="560" cellpadding="0" cellspacing="0" style="background:#FFFFFF;border-radius:16px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.06);">
        <tr><td style="background:linear-gradient(135deg,#1E293B,#0F172A);padding:32px;text-align:center;">
          <div style="font-size:22px;font-weight:800;color:#F8FAFC;">Kavira</div>
        </td></tr>
        <tr><td style="padding:36px 40px;">
          <h1 style="margin:0 0 12px;font-size:22px;color:#0F172A;font-weight:800;">
            Merhaba {full_name} 👋
          </h1>
          <p style="margin:0 0 20px;font-size:15px;line-height:1.6;color:#475569;">
            Kavira beta deneme süren <strong style="color:{renk};">{gun_kalan} gün</strong> içinde doluyor
            (bitiş tarihi: <strong>{bitis}</strong>).
          </p>
          <div style="background:#FFFBEB;border:1px solid #FDE68A;border-left:4px solid {renk};border-radius:8px;padding:16px 20px;margin:24px 0;">
            <strong style="color:{renk};font-size:14px;">Şu an ne yapmalı?</strong>
            <p style="margin:8px 0 0;font-size:14px;color:#78350F;line-height:1.5;">
              Kullanmaya devam etmek istersen <strong>WhatsApp</strong> veya <strong>mail</strong> ile bize ulaş —
              sana özel <strong>promosyon kodu</strong> göndereceğiz, süren uzayacak.
            </p>
          </div>
          <div style="text-align:center;margin:28px 0;">
            <a href="https://wa.me/905015517407?text=Merhaba+Kavira+beta+s%C3%BCremin+bitmesine+yak%C4%B1n%2C+devam+etmek+istiyorum"
               style="display:inline-block;background:#25D366;color:#fff;text-decoration:none;font-weight:700;padding:14px 28px;border-radius:10px;font-size:15px;margin:0 4px;">
              💬 WhatsApp ile Yaz
            </a>
            <a href="mailto:kavirasoftware@gmail.com?subject=Beta+s%C3%BCre+uzatma"
               style="display:inline-block;background:#3B82F6;color:#fff;text-decoration:none;font-weight:700;padding:14px 28px;border-radius:10px;font-size:15px;margin:0 4px;">
              ✉️ Mail Gönder
            </a>
          </div>
          <p style="margin:24px 0 0;font-size:13px;color:#94A3B8;line-height:1.6;">
            Verilerin <strong>asla silinmez</strong>. Süre dolsa bile veri kaybı yaşamazsın,
            sadece yeni hesaplama yapamazsın.
          </p>
        </td></tr>
        <tr><td style="background:#F8FAFC;padding:20px;text-align:center;font-size:12px;color:#94A3B8;">
          Kavira Software · <a href="https://kaviragiyotin.online" style="color:#3B82F6;text-decoration:none;">kaviragiyotin.online</a>
        </td></tr>
      </table>
    </td></tr>
  </table>
</body></html>"""


def _trial_expired_email(full_name: str) -> str:
    """Süre dolduğunda gönderilen mail."""
    return f"""<!DOCTYPE html>
<html><head><meta charset="UTF-8"></head>
<body style="margin:0;padding:0;background:#F1F5F9;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#F1F5F9;padding:40px 0;">
    <tr><td align="center">
      <table width="560" cellpadding="0" cellspacing="0" style="background:#FFFFFF;border-radius:16px;overflow:hidden;box-shadow:0 4px 24px rgba(0,0,0,0.06);">
        <tr><td style="background:linear-gradient(135deg,#1E293B,#0F172A);padding:32px;text-align:center;">
          <div style="font-size:22px;font-weight:800;color:#F8FAFC;">Kavira</div>
        </td></tr>
        <tr><td style="padding:36px 40px;">
          <h1 style="margin:0 0 12px;font-size:22px;color:#0F172A;font-weight:800;">
            {full_name}, sürenin dolduğunu fark ettin mi?
          </h1>
          <p style="margin:0 0 20px;font-size:15px;line-height:1.6;color:#475569;">
            Beta deneme sürdüğü tamamlandı. Kullanmaya devam etmek istersen bize ulaş —
            <strong>ücretsiz promosyon kodu</strong> ile süren uzasın.
          </p>
          <div style="background:#EFF6FF;border:1px solid #BFDBFE;border-radius:10px;padding:18px;margin:24px 0;">
            <p style="margin:0;font-size:14px;color:#1E40AF;line-height:1.6;">
              <strong>Hatırlatma:</strong> Verilerinin tamamı sistemde duruyor.
              Süren uzayınca her şey kaldığın yerden devam eder.
            </p>
          </div>
          <div style="text-align:center;margin:28px 0;">
            <a href="https://wa.me/905015517407?text=Merhaba+Kavira+beta+s%C3%BCrem+doldu%2C+devam+etmek+istiyorum"
               style="display:inline-block;background:#25D366;color:#fff;text-decoration:none;font-weight:700;padding:14px 28px;border-radius:10px;font-size:15px;margin:0 4px;">
              💬 WhatsApp ile Yaz
            </a>
          </div>
          <p style="margin:24px 0 0;font-size:13px;color:#94A3B8;text-align:center;">
            Yardımcı olduğumuz herhangi bir konu varsa bize geri bildirim ver —
            sürekli gelişiyoruz.
          </p>
        </td></tr>
        <tr><td style="background:#F8FAFC;padding:20px;text-align:center;font-size:12px;color:#94A3B8;">
          Kavira Software · <a href="https://kaviragiyotin.online" style="color:#3B82F6;text-decoration:none;">kaviragiyotin.online</a>
        </td></tr>
      </table>
    </td></tr>
  </table>
</body></html>"""