import os
import io
import tempfile
import zipfile
import openpyxl
from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import StreamingResponse, FileResponse
from sqlalchemy.orm import Session
from jose import jwt, JWTError
from pydantic import BaseModel
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
    # GEÇİCİ OLARAK ABONELİK KONTROLÜ DEVRE DIŞI BIRAKILDI (Kullanıcı toplama aşaması)
    # sub = db.query(Subscription).filter(Subscription.company_id == current_user.company_id).first()
    # if not sub or not sub.is_active or (sub.end_date and sub.end_date < datetime.utcnow()):
    #     if sub and sub.is_active: # Süresi dolmuş ama veritabanında aktif kalmışsa
    #         sub.is_active = False
    #         db.commit()
    #     raise HTTPException(status_code=403, detail="Aktif bir aboneliğiniz bulunmamaktadır. Lütfen aboneliğinizi yenileyin.")
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
    # Şirketin özel ayarlarını tablodan sileriz.
    # Böylece şirket ilk girişinde veya hesaplama yaptığında, varsayılan (default) fiyatlarla yeni bir ayar satırı otomatik üretilir.
    settings = db.query(CompanySettings).filter(CompanySettings.company_id == company_id).first()
    if settings:
        db.delete(settings)
        db.commit()
    return {"message": f"Şirket ayarları başarıyla varsayılanlara sıfırlandı."}