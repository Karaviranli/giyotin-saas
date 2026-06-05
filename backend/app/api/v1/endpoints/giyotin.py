import os
import io
import tempfile
import zipfile
import openpyxl
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import StreamingResponse, FileResponse
from sqlalchemy.orm import Session
from jose import jwt, JWTError
from pydantic import BaseModel, field_validator
from app.core.config import settings
from app.core.dependencies import get_current_active_user

from app.db.database import get_db
from datetime import datetime
from app.models.subscription import Subscription
from app.models.user import User
from app.models.giyotin import GiyotinRecord
from app.services.giyotin_service import GiyotinService
from app.services.pdf_service import PdfService
from typing import Dict

router = APIRouter()

# --- Abonelik Kontrol Dependency ---
def require_active_subscription(
    current_user: User = Depends(get_current_active_user),
    db: Session = Depends(get_db)
):
    sub = db.query(Subscription).filter(Subscription.company_id == current_user.company_id).first()
    if not sub or not sub.is_active or (sub.end_date and sub.end_date < datetime.utcnow()):
        if sub and sub.is_active:
            sub.is_active = False
            db.commit()
        raise HTTPException(status_code=403, detail="Aktif bir aboneliğiniz bulunmamaktadır. Lütfen aboneliğinizi yenileyin.")
    return current_user

# --- SuperAdmin Kontrol Dependency ---
def get_current_superuser(current_user: User = Depends(get_current_active_user)):
    """Sadece is_superuser=True olan kullanıcıların erişimine izin verir."""
    if not current_user.is_superuser:
        raise HTTPException(status_code=403, detail="Bu işlem için SuperAdmin yetkisi gereklidir.")
    return current_user

class GiyotinRequest(BaseModel):
    project_name: str
    system_type: str
    width: float
    height: float
    quantity: int
    stock_length: float
    kerf: float

    @field_validator("width")
    @classmethod
    def width_valid(cls, v: float) -> float:
        # cam_en = width - 149 → negatif cam olmaması için min 150
        if v <= 149:
            raise ValueError("Genişlik en az 150 mm olmalıdır.")
        if v > 10_000:
            raise ValueError("Genişlik en fazla 10.000 mm olabilir.")
        return v

    @field_validator("height")
    @classmethod
    def height_valid(cls, v: float) -> float:
        # cam_boy = (height - 263) / 3 → negatif cam olmaması için min 264
        if v <= 263:
            raise ValueError("Yükseklik en az 264 mm olmalıdır.")
        if v > 10_000:
            raise ValueError("Yükseklik en fazla 10.000 mm olabilir.")
        return v

    @field_validator("quantity")
    @classmethod
    def quantity_valid(cls, v: int) -> int:
        if v < 1:
            raise ValueError("Adet en az 1 olmalıdır.")
        if v > 500:
            raise ValueError("Adet en fazla 500 olabilir.")
        return v

    @field_validator("kerf")
    @classmethod
    def kerf_valid(cls, v: float) -> float:
        if v < 0:
            raise ValueError("Testere payı (kerf) negatif olamaz.")
        if v > 50:
            raise ValueError("Testere payı (kerf) en fazla 50 mm olabilir.")
        return v

    @field_validator("stock_length")
    @classmethod
    def stock_length_valid(cls, v: float) -> float:
        if v <= 0:
            raise ValueError("Stok uzunluğu pozitif olmalıdır.")
        if v > 20_000:
            raise ValueError("Stok uzunluğu en fazla 20.000 mm olabilir.")
        return v

class CombinedGiyotinRequest(BaseModel):
    project_name: str
    cost_details: dict
    cut_optimization: dict

@router.post("/calculate", response_model_exclude_none=True)
def calculate_giyotin(
    request: GiyotinRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_active_subscription)
):
    cost_details, cut_optimization = GiyotinService.calculate(
        width=request.width, height=request.height, quantity=request.quantity,
        stock_length=request.stock_length, kerf=request.kerf,
        company_id=current_user.company_id, db=db
    )
    new_record = GiyotinRecord(
        company_id=current_user.company_id, user_id=current_user.id,
        project_name=request.project_name, system_type=request.system_type,
        width=request.width, height=request.height, quantity=request.quantity,
        cost_details=cost_details, cut_optimization=cut_optimization
    )
    db.add(new_record)
    db.commit()
    db.refresh(new_record)
    return {
        "record_id": new_record.id,
        "cost_details": cost_details,
        "cut_optimization": cut_optimization
    }

@router.post("/save-combined", response_model_exclude_none=True)
def save_combined_giyotin(
    request: CombinedGiyotinRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_active_subscription)
):
    new_record = GiyotinRecord(
        company_id=current_user.company_id, user_id=current_user.id,
        project_name=request.project_name, system_type="BİRLEŞİK KESİM",
        width=0.0, height=0.0, quantity=1,
        cost_details=request.cost_details, cut_optimization=request.cut_optimization
    )
    db.add(new_record)
    db.commit()
    db.refresh(new_record)
    return {
        "record_id": new_record.id,
        "message": "Birleşik kesim başarıyla kaydedildi."
    }

@router.post("/excel-indir")
def excel_indir(
    request: GiyotinRequest,
    current_user: User = Depends(require_active_subscription)
):
    template_path = os.path.join(os.path.dirname(os.path.dirname(os.path.dirname(__file__))), "services", "templates", "bintelli_template.xlsx")
    if not os.path.exists(template_path):
        # Sunucuda şablon dosyası eksikse boş dosya üretmek yerine hata fırlat
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail="Excel şablon dosyası sunucuda bulunamadı. Lütfen sistem yöneticisiyle iletişime geçin.")

    # Not: Burada paylaştığın ZIP tabanlı XML güncelleme mantığını 
    # services/excel_service.py gibi bir yere taşıyıp çağırmak en temizi olacaktır.
    # Şimdilik direkt FileResponse ile şablonu (veya işlem görmüş hali) dönüyoruz.
    
    fname = f"BINTELLI_{request.project_name}_{int(request.width)}x{int(request.height)}.xlsx"
    return FileResponse(template_path, filename=fname)

@router.get("/records")
def get_giyotin_records(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    # Kullanıcının şirketine ait tüm kayıtları en yeniden en eskiye doğru getirir
    records = db.query(GiyotinRecord).filter(
        GiyotinRecord.company_id == current_user.company_id
    ).order_by(GiyotinRecord.created_at.desc()).all()
    return records

@router.delete("/records/{record_id}")
def delete_giyotin_record(
    record_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    record = db.query(GiyotinRecord).filter(
        GiyotinRecord.id == record_id,
        GiyotinRecord.company_id == current_user.company_id
    ).first()

    if not record:
        raise HTTPException(status_code=404, detail="Kayıt bulunamadı veya silme yetkiniz yok.")

    db.delete(record)
    db.commit()
    return {"message": "Kayıt başarıyla silindi."}

@router.get("/report/{record_id}")
def get_giyotin_report(
    record_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_active_subscription)
):
    record = db.query(GiyotinRecord).filter(
        GiyotinRecord.id == record_id,
        GiyotinRecord.company_id == current_user.company_id
    ).first()

    if not record:
        raise HTTPException(status_code=404, detail="Rapor bulunamadı veya erişim reddedildi.")

    record_data = {
        "project_name": record.project_name, "system_type": record.system_type,
        "width": record.width, "height": record.height, "quantity": record.quantity,
        "cost_details": record.cost_details, "cut_optimization": record.cut_optimization
    }

    company_name = current_user.company.name if current_user.company else "Kavira SaaS"

    try:
        pdf_bytes = PdfService.generate_giyotin_pdf(
            company_name=company_name, record=record_data
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"PDF oluşturulurken sunucu hatası: {str(e)}")

    return StreamingResponse(io.BytesIO(pdf_bytes), media_type="application/pdf", headers={
        "Content-Disposition": f"attachment; filename=rapor_{record_id}.pdf"
    })

@router.get("/settings")
def get_settings(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    from app.models.company_settings import CompanySettings
    # Şirketin özel ayarlarını bul, yoksa varsayılan değerlerle yeni oluştur
    company_settings = db.query(CompanySettings).filter(CompanySettings.company_id == current_user.company_id).first()
    if not company_settings:
        company_settings = CompanySettings(company_id=current_user.company_id)
        db.add(company_settings)
        db.commit()
        db.refresh(company_settings)
        
    return {
        "company_name": current_user.company.name if current_user.company else "Bilinmeyen Şirket",
        "fiyatlar": {
            "Alüminyum (TL/kg)": company_settings.aluminyum_kg_tl,
            "Cam (TL/m²) 4+16+4 DC/C Isı": company_settings.cam_m2_tl,
            "Kayış (TL/m)": company_settings.kayis_m_tl,
            "Sekizgen Boru 70 (TL/m)": company_settings.boru_m_tl,
            "Kayışlı Set (TL/adet)": company_settings.kayisli_set_tl,
            "Kumanda (TL/adet)": company_settings.kumanda_tl,
            "Motor (TL/adet)": company_settings.motor_tl,
            "Genel Gider (%)": company_settings.genel_gider_yuzde
        }
    }

@router.post("/settings")
def update_settings(
    new_settings: Dict[str, float],
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    # Yalnızca şirket yöneticileri fiyat ayarlarını değiştirebilir
    if not current_user.is_company_admin:
        raise HTTPException(status_code=403, detail="Fiyat ayarlarını yalnızca şirket yöneticisi değiştirebilir.")
    from app.models.company_settings import CompanySettings
    company_settings = db.query(CompanySettings).filter(CompanySettings.company_id == current_user.company_id).first()
    if not company_settings:
        company_settings = CompanySettings(company_id=current_user.company_id)
        db.add(company_settings)
        
    # Gelen isimleri veritabanı kolon isimleriyle eşleştirme
    key_map = {
        "Alüminyum (TL/kg)": "aluminyum_kg_tl", "Cam (TL/m²) 4+16+4 DC/C Isı": "cam_m2_tl",
        "Kayış (TL/m)": "kayis_m_tl", "Sekizgen Boru 70 (TL/m)": "boru_m_tl",
        "Kayışlı Set (TL/adet)": "kayisli_set_tl", "Kumanda (TL/adet)": "kumanda_tl",
        "Motor (TL/adet)": "motor_tl", "Genel Gider (%)": "genel_gider_yuzde"
    }
    
    for isim, value in new_settings.items():
        if isim in key_map:
            setattr(company_settings, key_map[isim], float(value))
            
    db.commit()
    return {"message": "Ayarlar başarıyla güncellendi."}

@router.get("/admin/settings/all")
def get_all_company_settings(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser)
):
    from app.models.company import Company
    from app.models.company_settings import CompanySettings
    
    companies = db.query(Company).all()
    results = []
    for comp in companies:
        settings = db.query(CompanySettings).filter(CompanySettings.company_id == comp.id).first()
        results.append({
            "company_id": comp.id,
            "company_name": comp.name,
            "has_custom_settings": settings is not None,
            "settings": {
                "Alüminyum (TL/kg)": settings.aluminyum_kg_tl if settings else 368.0,
                "Cam (TL/m²) 4+16+4 DC/C Isı": settings.cam_m2_tl if settings else 1915.0,
                "Kayış (TL/m)": settings.kayis_m_tl if settings else 150.0,
                "Sekizgen Boru 70 (TL/m)": settings.boru_m_tl if settings else 204.0,
                "Kayışlı Set (TL/adet)": settings.kayisli_set_tl if settings else 4104.0,
                "Kumanda (TL/adet)": settings.kumanda_tl if settings else 860.0,
                "Motor (TL/adet)": settings.motor_tl if settings else 3765.0,
                "Genel Gider (%)": settings.genel_gider_yuzde if settings else 2.5
            }
        })
    return results

@router.post("/admin/settings/reset/{company_id}")
def reset_company_settings(
    company_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_superuser)
):
    from app.models.company_settings import CompanySettings
    settings = db.query(CompanySettings).filter(CompanySettings.company_id == company_id).first()
    if settings:
        db.delete(settings)
        db.commit()
    return {"message": f"Şirket ayarları başarıyla varsayılanlara sıfırlandı."}


# ──────────────────────────────────────────────────────────────────────────────
# PUBLIC TEKLİF — giriş gerektirmez, varsayılan fiyatlarla tahmini hesap
# ──────────────────────────────────────────────────────────────────────────────

class PublicQuoteRequest(BaseModel):
    width: float
    height: float
    quantity: int = 1

    @field_validator("width")
    @classmethod
    def width_ok(cls, v):
        if v <= 149 or v > 10000:
            raise ValueError("Genişlik 150–10.000 mm aralığında olmalıdır.")
        return v

    @field_validator("height")
    @classmethod
    def height_ok(cls, v):
        if v <= 263 or v > 10000:
            raise ValueError("Yükseklik 264–10.000 mm aralığında olmalıdır.")
        return v

    @field_validator("quantity")
    @classmethod
    def qty_ok(cls, v):
        if v < 1 or v > 50:
            raise ValueError("Adet 1–50 aralığında olmalıdır.")
        return v


@router.post("/public-quote")
def public_quote(request: PublicQuoteRequest):
    """Kayıt gerektirmeyen hızlı maliyet tahmini.

    Piyasa varsayılan fiyatları kullanılır; sonuç yüzde 30 perakende
    marjı ve yüzde 20 KDV eklenerek müşteriye sunulacak tahmini fiyattır.
    Kayıt oluşturulmaz.
    """
    import math

    w, h, qty = request.width, request.height, request.quantity

    # Varsayılan birim fiyatlar (giyotin_service.py DEF ile birebir)
    alm_kg_tl     = 368.0
    cam_m2_tl     = 1915.0
    kayis_tl_m    = 150.0
    boru_tl_m     = 204.0
    kayisli_set   = 4104.0
    kumanda       = 860.0
    motor         = 3765.0
    gg_yuzde      = 2.5
    stock_length  = 6500.0
    kerf          = 3.0

    # Profil ağırlık katsayıları (kg/m)
    profil_kg_m = {
        "K-1401": 0.615, "K-1402": 0.615, "K-1403": 0.380,
        "K-1404": 0.520, "K-1405": 0.520, "K-1406": 0.490,
        "K-1407": 0.490, "K-1408": 0.280, "K-1409": 0.280,
        "K-1410": 0.280, "K-1411": 0.280, "K-1412": 0.280,
    }

    cam_en   = w - 149
    cam_boy  = (h - 263) / 3
    cam_adet = qty * 3
    cam_m2   = (cam_en * cam_boy * cam_adet) / 1_000_000

    profiller = [
        {"kod": "K-1401", "olcu": w - 30,         "adet": qty * 1},
        {"kod": "K-1402", "olcu": w - 30,         "adet": qty * 1},
        {"kod": "K-1403", "olcu": w - 45,         "adet": qty * 1},
        {"kod": "K-1405", "olcu": h - 175,        "adet": qty * 2},
        {"kod": "K-1404", "olcu": h - 175,        "adet": qty * 2},
        {"kod": "K-1406", "olcu": (cam_boy*2)+20, "adet": qty * 2},
        {"kod": "K-1407", "olcu": cam_boy + 28,   "adet": qty * 2},
        {"kod": "K-1408", "olcu": w - 177,        "adet": qty * 1},
        {"kod": "K-1409", "olcu": w - 177,        "adet": qty * 6},
        {"kod": "K-1410", "olcu": cam_boy + 29,   "adet": qty * 2},
        {"kod": "K-1411", "olcu": w - 177,        "adet": qty * 3},
        {"kod": "K-1412", "olcu": w - 177,        "adet": qty * 1},
    ]

    profil_tl = 0.0
    for p in profiller:
        stok = math.ceil((p["adet"] * (p["olcu"] + kerf)) / stock_length)
        m    = stok * (stock_length / 1000)
        kg   = m * profil_kg_m.get(p["kod"], 0.4)
        profil_tl += kg * alm_kg_tl

    # Motor borusu
    boru_stok  = math.ceil((qty * (w - 75 + kerf)) / stock_length)
    boru_m     = boru_stok * (stock_length / 1000)
    boru_tl_toplam = boru_m * boru_tl_m

    # Kayış, cam, sabit
    kayis_m   = round((h / 4) * 4.7 * qty / 1000, 3)
    kayis_tl  = kayis_m * kayis_tl_m
    cam_tl    = cam_m2 * cam_m2_tl
    sabit_tl  = qty * (kayisli_set + motor) + kumanda

    ara = profil_tl + boru_tl_toplam + kayis_tl + cam_tl + sabit_tl
    gg  = ara * (gg_yuzde / 100)
    maliyet = ara + gg

    # Perakende marjı (%30) + KDV (%20)
    MARJ = 1.30
    KDV  = 0.20
    kdv_haric = round(maliyet * MARJ, 2)
    kdv_tl    = round(kdv_haric * KDV, 2)
    genel_toplam = round(kdv_haric + kdv_tl, 2)

    return {
        "kdv_haric_tl":   kdv_haric,
        "kdv_tl":         kdv_tl,
        "genel_toplam_tl": genel_toplam,
        "birim_fiyat_tl": round(genel_toplam / qty, 2),
        "not": "Bu fiyat varsayılan piyasa fiyatlarıyla hesaplanmış tahmini bir değerdir."
    }