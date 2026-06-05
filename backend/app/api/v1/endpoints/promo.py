from datetime import datetime, timedelta
from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel
from sqlalchemy import text
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.models.subscription import Subscription
from app.models.promo_code import PromoCode, PromoCodeUsage
from app.core.dependencies import get_current_active_user
from app.core.limiter import limiter
from app.models.user import User

router = APIRouter()


class RedeemRequest(BaseModel):
    code: str


@router.post("/redeem")
@limiter.limit("10/minute")
def redeem_promo_code(
    request: Request,
    req: RedeemRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    code_str = req.code.strip().upper()
    if not code_str:
        raise HTTPException(status_code=400, detail="Promosyon kodu boş bırakılamaz.")

    # Kodu bul
    promo = db.query(PromoCode).filter(PromoCode.code == code_str).first()
    if not promo:
        raise HTTPException(status_code=404, detail="Geçersiz promosyon kodu.")

    if not promo.is_active:
        raise HTTPException(status_code=400, detail="Bu promosyon kodu artık aktif değil.")

    if promo.expires_at and datetime.utcnow() > promo.expires_at:
        raise HTTPException(status_code=400, detail="Bu promosyon kodunun süresi dolmuş.")

    if promo.max_uses is not None and promo.used_count >= promo.max_uses:
        raise HTTPException(status_code=400, detail="Bu promosyon kodu kullanım limitine ulaştı.")

    # Bu şirket daha önce bu kodu kullandı mı?
    already_used = (
        db.query(PromoCodeUsage)
        .filter(
            PromoCodeUsage.promo_code_id == promo.id,
            PromoCodeUsage.company_id == current_user.company_id,
        )
        .first()
    )
    if already_used:
        raise HTTPException(status_code=400, detail="Bu promosyon kodunu daha önce kullandınız.")

    # Aboneliği uzat
    sub = db.query(Subscription).filter(
        Subscription.company_id == current_user.company_id
    ).first()
    if not sub:
        raise HTTPException(status_code=404, detail="Abonelik kaydı bulunamadı.")

    now = datetime.utcnow()
    # Aktif ve ileriki bitiş tarihi varsa oradan uzat; yoksa bugünden başlat
    if sub.end_date and sub.end_date > now:
        sub.end_date = sub.end_date + timedelta(days=promo.duration_days)
    else:
        sub.end_date = now + timedelta(days=promo.duration_days)

    sub.is_active = True
    if sub.plan_name in ("Deneme", "Deneme Sürümü"):
        sub.plan_name = "Promosyon"

    # Kullanımı kaydet
    db.add(PromoCodeUsage(
        promo_code_id=promo.id,
        company_id=current_user.company_id,
    ))

    # Race condition önleme: used_count atomik artış (SQL seviyesinde)
    # max_uses doluysa güncelleme yapılmaz → rowcount == 0
    if promo.max_uses is not None:
        result = db.execute(
            text("""
                UPDATE promo_codes
                SET used_count = used_count + 1,
                    is_active = CASE
                        WHEN used_count + 1 >= max_uses THEN FALSE
                        ELSE is_active
                    END
                WHERE id = :id AND used_count < max_uses
            """),
            {"id": promo.id},
        )
        db.flush()
        if result.rowcount == 0:
            raise HTTPException(status_code=400, detail="Bu promosyon kodu kullanım limitine ulaştı.")
    else:
        # Limitsiz kod — basit artış yeterli
        db.execute(
            text("UPDATE promo_codes SET used_count = used_count + 1 WHERE id = :id"),
            {"id": promo.id},
        )
        db.flush()

    db.commit()

    new_end = sub.end_date
    formatted = f"{new_end.day:02d}.{new_end.month:02d}.{new_end.year}"
    return {
        "message": f"Promosyon kodu uygulandı! {promo.duration_days} günlük erişim eklendi.",
        "new_end_date": new_end.isoformat(),
        "new_end_date_formatted": formatted,
        "duration_days": promo.duration_days,
    }
