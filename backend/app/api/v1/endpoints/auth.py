from datetime import timedelta
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
def register(request: Request, req: RegisterRequest, db: Session = Depends(get_db)):
    # 1. E-posta sistemde var mı?
    user = db.query(User).filter(User.email == req.email).first()
    if user:
        raise HTTPException(status_code=400, detail="Bu e-posta zaten kayıtlı.")
    
    # 2. Şirketi oluştur ve veritabanına kaydet
    new_company = Company(name=req.company_name)
    db.add(new_company)
    db.commit()
    db.refresh(new_company)
    
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
    
    return {"message": "Kayıt başarılı"}

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
        # Güvenlik: Kullanıcının varlığını sızdırmamak için her zaman olumlu döneriz.
        return {"message": "E-posta adresi sistemde kayıtlıysa sıfırlama talimatları gönderilecektir."}
    
    # Sıfırlama token'ı üret (Sadece 15 dakika geçerli ve özel scope)
    reset_token = create_access_token(
        data={"sub": str(user.id), "scope": "password_reset"},
        expires_delta=timedelta(minutes=15)
    )
    
    # E-posta içeriğini hazırla
    # Not: Deep Link için mobil cihazların tanıyabileceği bir domain gereklidir.
    reset_link = f"https://kaviragiyotin.com/reset-password?token={reset_token}"
    
    message = MessageSchema(
        subject="Kavira SaaS - Şifre Sıfırlama Talebi",
        recipients=[user.email],
        body=f"Merhaba {user.full_name},<br><br>Şifrenizi sıfırlamak için aşağıdaki bağlantıya tıklayın:<br>"
             f"<a href='{reset_link}'>{reset_link}</a><br><br>"
             f"Bu bağlantı 15 dakika içinde geçerliliğini yitirecektir.",
        subtype=MessageType.html
    )

    fm = FastMail(mail_conf)
    await fm.send_message(message)
    
    return {"message": "Sıfırlama talimatları e-posta adresinize gönderildi."}

@router.post("/reset-password")
def reset_password(req: ResetPasswordRequest, db: Session = Depends(get_db)):
    # 1. Token'ı ve scope'u doğrula
    try:
        payload = jwt.decode(req.token, settings.SECRET_KEY, algorithms=["HS256"])
        if payload.get("scope") != "password_reset":
            raise HTTPException(status_code=400, detail="Geçersiz işlem tipi")
        user_id = payload.get("sub")
    except JWTError:
        raise HTTPException(status_code=400, detail="Geçersiz veya süresi dolmuş token")

    # 2. Kullanıcıyı bul
    user = db.query(User).filter(User.id == int(user_id)).first()
    if not user:
        raise HTTPException(status_code=404, detail="Kullanıcı bulunamadı")

    # 3. Şifreyi güncelle ve kaydet
    user.hashed_password = get_password_hash(req.new_password)
    db.commit()

    return {"message": "Şifreniz başarıyla güncellendi. Yeni şifrenizle giriş yapabilirsiniz."}

@router.get("/me")
def get_me(current_user: User = Depends(get_current_active_user)):
    return {
        "full_name": current_user.full_name,
        "email": current_user.email
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