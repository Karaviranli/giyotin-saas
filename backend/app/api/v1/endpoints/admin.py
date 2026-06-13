from datetime import datetime, timedelta
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy import func, text
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.models.user import User
from app.models.company import Company
from app.models.subscription import Subscription
from app.models.giyotin import GiyotinRecord
from app.models.promo_code import PromoCode, PromoCodeUsage
from app.core.dependencies import get_current_active_user

router = APIRouter()


def _require_admin(current_user: User = Depends(get_current_active_user)) -> User:
    if not current_user.is_superuser:
        raise HTTPException(status_code=403, detail="Bu işlem için yetkiniz yok.")
    return current_user


@router.get("/stats")
def get_admin_stats(
    db: Session = Depends(get_db),
    _: User = Depends(_require_admin),
):
    """Genel platform istatistikleri."""
    now = datetime.utcnow()
    thirty_days_ago = now - timedelta(days=30)
    seven_days_ago = now - timedelta(days=7)

    total_companies = db.query(func.count(Company.id)).scalar() or 0
    total_users = db.query(func.count(User.id)).scalar() or 0
    total_records = db.query(func.count(GiyotinRecord.id)).scalar() or 0
    records_last_30 = (
        db.query(func.count(GiyotinRecord.id))
        .filter(GiyotinRecord.created_at >= thirty_days_ago)
        .scalar() or 0
    )
    records_last_7 = (
        db.query(func.count(GiyotinRecord.id))
        .filter(GiyotinRecord.created_at >= seven_days_ago)
        .scalar() or 0
    )

    # Abonelik dağılımı
    subs = db.query(Subscription).all()
    active_paid = sum(
        1 for s in subs
        if s.is_active and s.plan_name not in ("Deneme", "Deneme Sürümü")
    )
    active_trial = sum(
        1 for s in subs
        if s.is_active and s.plan_name in ("Deneme", "Deneme Sürümü")
    )
    expired = sum(1 for s in subs if not s.is_active)

    # Yeni kayıtlar (son 30 gün) — subscription start_date kullanıyoruz
    new_companies_30 = (
        db.query(func.count(Subscription.id))
        .filter(Subscription.start_date >= thirty_days_ago)
        .scalar() or 0
    )

    # Günlük kayıt trendi (son 14 gün)
    daily_records = []
    for i in range(13, -1, -1):
        day_start = now.replace(hour=0, minute=0, second=0, microsecond=0) - timedelta(days=i)
        day_end = day_start + timedelta(days=1)
        count = (
            db.query(func.count(GiyotinRecord.id))
            .filter(GiyotinRecord.created_at >= day_start, GiyotinRecord.created_at < day_end)
            .scalar() or 0
        )
        daily_records.append({"date": day_start.strftime("%d/%m"), "count": count})

    return {
        "total_companies": total_companies,
        "total_users": total_users,
        "total_records": total_records,
        "records_last_30": records_last_30,
        "records_last_7": records_last_7,
        "new_companies_30": new_companies_30,
        "subscriptions": {
            "active_paid": active_paid,
            "active_trial": active_trial,
            "expired": expired,
            "total": len(subs),
        },
        "daily_records": daily_records,
    }


@router.get("/companies")
def get_admin_companies(
    db: Session = Depends(get_db),
    _: User = Depends(_require_admin),
    page: int = Query(1, ge=1),
    per_page: int = Query(20, ge=1, le=100),
    search: str = Query("", alias="q"),
):
    """Şirket listesi — sayfalı, aranabilir."""
    query = db.query(Company)
    if search:
        query = query.filter(Company.name.ilike(f"%{search}%"))

    total = query.count()
    companies = query.offset((page - 1) * per_page).limit(per_page).all()

    result = []
    for company in companies:
        sub = db.query(Subscription).filter(Subscription.company_id == company.id).first()
        user_count = db.query(func.count(User.id)).filter(User.company_id == company.id).scalar() or 0
        record_count = (
            db.query(func.count(GiyotinRecord.id))
            .filter(GiyotinRecord.company_id == company.id)
            .scalar() or 0
        )
        last_record = (
            db.query(GiyotinRecord.created_at)
            .filter(GiyotinRecord.company_id == company.id)
            .order_by(GiyotinRecord.created_at.desc())
            .first()
        )
        admin_user = (
            db.query(User)
            .filter(User.company_id == company.id, User.is_company_admin == True)
            .first()
        )

        result.append({
            "id": company.id,
            "name": company.name,
            "admin_email": admin_user.email if admin_user else "-",
            "admin_name": admin_user.full_name if admin_user else "-",
            "user_count": user_count,
            "record_count": record_count,
            "last_activity": last_record[0].isoformat() if last_record else None,
            "subscription": {
                "plan_name": sub.plan_name if sub else "Yok",
                "is_active": sub.is_active if sub else False,
                "end_date": sub.end_date.isoformat() if sub and sub.end_date else None,
            } if sub else None,
        })

    return {
        "total": total,
        "page": page,
        "per_page": per_page,
        "pages": max(1, (total + per_page - 1) // per_page),
        "companies": result,
    }


# ── Promo Kod Yönetimi ─────────────────────────────────────────

class PromoCodeCreate(BaseModel):
    code: Optional[str] = None   # boş bırakılırsa otomatik üretilir
    description: Optional[str] = None
    duration_days: int = 30
    max_uses: Optional[int] = None
    expires_at: Optional[str] = None  # ISO format string or None


@router.get("/promo-codes")
def list_promo_codes(
    db: Session = Depends(get_db),
    _: User = Depends(_require_admin),
):
    codes = db.query(PromoCode).order_by(PromoCode.created_at.desc()).all()
    return [
        {
            "id": c.id,
            "code": c.code,
            "description": c.description,
            "duration_days": c.duration_days,
            "max_uses": c.max_uses,
            "used_count": c.used_count,
            "is_active": c.is_active,
            "created_at": c.created_at.isoformat(),
            "expires_at": c.expires_at.isoformat() if c.expires_at else None,
        }
        for c in codes
    ]


def _generate_promo_code(db: Session) -> str:
    """Benzersiz rastgele bir promosyon kodu üretir: KV-XXXX-XXXX"""
    import random, string
    chars = string.ascii_uppercase + string.digits
    for _ in range(20):  # çakışma ihtimaline karşı 20 deneme
        code = "KV-" + "".join(random.choices(chars, k=4)) + "-" + "".join(random.choices(chars, k=4))
        if not db.query(PromoCode).filter(PromoCode.code == code).first():
            return code
    raise HTTPException(status_code=500, detail="Benzersiz kod üretilemedi, tekrar deneyin.")


@router.post("/promo-codes")
def create_promo_code(
    req: PromoCodeCreate,
    db: Session = Depends(get_db),
    _: User = Depends(_require_admin),
):
    code_str = req.code.strip().upper() if req.code else ""
    if not code_str:
        code_str = _generate_promo_code(db)
    elif db.query(PromoCode).filter(PromoCode.code == code_str).first():
        raise HTTPException(status_code=400, detail="Bu kod zaten mevcut.")

    expires_at = None
    if req.expires_at:
        try:
            expires_at = datetime.fromisoformat(req.expires_at)
        except ValueError:
            raise HTTPException(status_code=400, detail="Geçersiz tarih formatı.")

    promo = PromoCode(
        code=code_str,
        description=req.description,
        duration_days=req.duration_days,
        max_uses=req.max_uses,
        expires_at=expires_at,
    )
    db.add(promo)
    db.commit()
    db.refresh(promo)
    return {"id": promo.id, "code": promo.code, "message": "Promosyon kodu oluşturuldu."}


@router.delete("/promo-codes/{code_id}")
def deactivate_promo_code(
    code_id: int,
    db: Session = Depends(get_db),
    _: User = Depends(_require_admin),
):
    promo = db.query(PromoCode).filter(PromoCode.id == code_id).first()
    if not promo:
        raise HTTPException(status_code=404, detail="Kod bulunamadı.")
    promo.is_active = False
    db.commit()
    return {"message": "Kod devre dışı bırakıldı."}


# ═════════════════════════════════════════════════════════════════════════
# /insights — KVKK uyumlu agregat veri havuzu
# Hiçbir kişisel bilgi (email/isim/IP) içermez; sadece sayısal/kategorik.
# ═════════════════════════════════════════════════════════════════════════
@router.get("/insights")
def get_insights(
    db: Session = Depends(get_db),
    _: User = Depends(_require_admin),
):
    """Detaylı agregat veri havuzu — power dashboard için."""
    now = datetime.utcnow()
    d7  = now - timedelta(days=7)
    d30 = now - timedelta(days=30)
    d90 = now - timedelta(days=90)

    # ── Sistem türü dağılımı (en çok kullanılan) ──
    sistem_dist = (
        db.query(GiyotinRecord.system_type, func.count(GiyotinRecord.id).label("n"))
        .group_by(GiyotinRecord.system_type)
        .order_by(func.count(GiyotinRecord.id).desc())
        .all()
    )
    sistem_dagilim = [
        {"sistem": (s or "Belirsiz"), "adet": n}
        for s, n in sistem_dist
    ]

    # ── Proje metrikleri (boyut, miktar, maliyet ortalamaları) ──
    proj = db.query(
        func.avg(GiyotinRecord.width).label("avg_w"),
        func.avg(GiyotinRecord.height).label("avg_h"),
        func.avg(GiyotinRecord.quantity).label("avg_qty"),
        func.max(GiyotinRecord.width).label("max_w"),
        func.max(GiyotinRecord.height).label("max_h"),
        func.sum(GiyotinRecord.quantity).label("toplam_sistem"),
    ).first()

    # Maliyetler cost_details JSON içinden — Python'da toplayalım
    records_with_cost = db.query(GiyotinRecord.cost_details, GiyotinRecord.created_at).all()
    cost_list = []
    profil_freq: dict = {}
    fire_yuzdeleri = []
    cost_last_30 = 0.0
    for cd, ca in records_with_cost:
        if not cd or not isinstance(cd, dict):
            continue
        total = cd.get("total_cost") or cd.get("toplam_tl") or 0
        try:
            total_f = float(total)
        except Exception:
            total_f = 0.0
        if total_f > 0:
            cost_list.append(total_f)
            if ca and ca >= d30:
                cost_last_30 += total_f

        # Profil sıklığı
        profil_detay = cd.get("profil_detay") or cd.get("profiller") or []
        if isinstance(profil_detay, list):
            for p in profil_detay:
                if isinstance(p, dict):
                    kod = (p.get("kod") or "").strip()
                    if kod:
                        profil_freq[kod] = profil_freq.get(kod, 0) + 1

        # Fire payı
        fp = cd.get("fire_payi") or cd.get("fire_yuzde")
        try:
            if fp is not None:
                fire_yuzdeleri.append(float(fp))
        except Exception:
            pass

    ortalama_maliyet = round(sum(cost_list) / len(cost_list), 2) if cost_list else 0
    toplam_maliyet = round(sum(cost_list), 2)
    max_maliyet = round(max(cost_list), 2) if cost_list else 0
    ortalama_fire = round(sum(fire_yuzdeleri) / len(fire_yuzdeleri), 2) if fire_yuzdeleri else 0

    top_profiller = sorted(profil_freq.items(), key=lambda x: x[1], reverse=True)[:10]

    # ── Saatlik aktivite (son 30g — hangi saatlerde yoğun) ──
    saatlik = [0] * 24
    activity_recs = (
        db.query(GiyotinRecord.created_at)
        .filter(GiyotinRecord.created_at >= d30)
        .all()
    )
    for (ca,) in activity_recs:
        if ca:
            saatlik[ca.hour] += 1

    # ── Engagement segmentleri ──
    company_record_counts = (
        db.query(GiyotinRecord.company_id, func.count(GiyotinRecord.id).label("n"))
        .group_by(GiyotinRecord.company_id)
        .all()
    )
    power_users = sum(1 for _c, n in company_record_counts if n >= 10)
    aktif = sum(1 for _c, n in company_record_counts if 3 <= n < 10)
    casual = sum(1 for _c, n in company_record_counts if 1 <= n < 3)
    total_companies = db.query(func.count(Company.id)).scalar() or 0
    silent_count = total_companies - power_users - aktif - casual

    # ── Trial expiration takibi — gelecek 7g'de süresi dolacaklar ──
    upcoming = (
        db.query(Subscription)
        .filter(
            Subscription.is_active == True,
            Subscription.end_date.isnot(None),
            Subscription.end_date >= now,
            Subscription.end_date <= now + timedelta(days=7),
        )
        .order_by(Subscription.end_date.asc())
        .all()
    )
    upcoming_expirations = [
        {
            "company_id": s.company_id,
            "plan_name": s.plan_name,
            "end_date": s.end_date.isoformat() if s.end_date else None,
            "gun_kaldi": (s.end_date - now).days if s.end_date else 0,
        }
        for s in upcoming
    ]

    # Yeni süresi dolanlar (proaktif ulaşım için)
    just_expired = (
        db.query(Subscription)
        .filter(
            Subscription.is_active == False,
            Subscription.end_date.isnot(None),
            Subscription.end_date >= now - timedelta(days=7),
            Subscription.end_date < now,
        )
        .order_by(Subscription.end_date.desc())
        .all()
    )
    recently_expired = [
        {
            "company_id": s.company_id,
            "plan_name": s.plan_name,
            "end_date": s.end_date.isoformat() if s.end_date else None,
            "gun_once": (now - s.end_date).days if s.end_date else 0,
        }
        for s in just_expired
    ]

    # ── Haftalık büyüme (son 12 hafta) ──
    weekly = []
    for i in range(11, -1, -1):
        w_start = now - timedelta(days=(i+1) * 7)
        w_end = now - timedelta(days=i * 7)
        n_rec = db.query(func.count(GiyotinRecord.id)).filter(
            GiyotinRecord.created_at >= w_start,
            GiyotinRecord.created_at < w_end,
        ).scalar() or 0
        n_new_co = db.query(func.count(Subscription.id)).filter(
            Subscription.start_date >= w_start,
            Subscription.start_date < w_end,
        ).scalar() or 0
        weekly.append({
            "hafta": w_start.strftime("%d/%m"),
            "kayit": n_rec,
            "yeni_firma": n_new_co,
        })

    return {
        "sistem_dagilim": sistem_dagilim,
        "proje_metrikleri": {
            "ort_genislik": round(float(proj.avg_w or 0), 1),
            "ort_yukseklik": round(float(proj.avg_h or 0), 1),
            "ort_adet": round(float(proj.avg_qty or 0), 1),
            "max_genislik": round(float(proj.max_w or 0), 1),
            "max_yukseklik": round(float(proj.max_h or 0), 1),
            "toplam_sistem_adet": int(proj.toplam_sistem or 0),
        },
        "finansal": {
            "ortalama_maliyet_tl": ortalama_maliyet,
            "toplam_hesaplanmis_maliyet_tl": toplam_maliyet,
            "max_proje_maliyeti_tl": max_maliyet,
            "son_30g_hesaplanmis_maliyet_tl": round(cost_last_30, 2),
            "ortalama_fire_yuzde": ortalama_fire,
        },
        "top_profiller": [{"kod": k, "frekans": v} for k, v in top_profiller],
        "saatlik_aktivite": saatlik,
        "engagement": {
            "power_users": power_users,
            "aktif": aktif,
            "casual": casual,
            "sessiz": silent_count,
            "toplam_firma": total_companies,
        },
        "yaklasan_bitisler": upcoming_expirations,
        "son_bitenler": recently_expired,
        "haftalik_buyume": weekly,
    }
