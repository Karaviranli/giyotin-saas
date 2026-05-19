from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List

from app.db.database import get_db
from app.core.dependencies import get_current_active_user
from app.models.user import User
from app.models.giyotin import GiyotinRecord
from app.schemas.giyotin import GiyotinCalculateRequest, GiyotinRecordResponse
from app.services.giyotin_service import GiyotinService
from fastapi.responses import Response

router = APIRouter()

@router.post("/calculate")
def calculate_and_save_giyotin(
    request: GiyotinCalculateRequest, 
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    Giyotin maliyetini hesaplar ve otomatik olarak şirketin geçmişine kaydeder.
    """
    if not current_user.company_id:
        raise HTTPException(status_code=403, detail="Kullanıcı bir şirkete atanmamış.")

    # TODO: İleride şirketin kendi fiyatlarını (CompanySettings tablosundan) çekeceğiz.
    # Şimdilik sistemin varsayılan fiyatlarıyla hesaplıyoruz.
    company_prices = None 
    company_profil_kg = None

    # 1. Servisi çağırıp hesaplamayı yap
    calculation_result = GiyotinService.calculate_system(
        g=request.width,
        y=request.height,
        adet=request.quantity,
        stok_uzunlugu=request.stock_length,
        fire_payi=request.kerf,
        prices=company_prices,
        profil_kg_m=company_profil_kg
    )

    # 2. Veritabanına kaydet
    new_record = GiyotinRecord(
        company_id=current_user.company_id,
        user_id=current_user.id,
        project_name=request.project_name,
        system_type=request.system_type,
        width=request.width,
        height=request.height,
        quantity=request.quantity,
        cost_details=calculation_result["maliyet"], # JSONB olarak doğrudan kaydedilir
        cut_optimization={"profiller": calculation_result["profiller"], "aksesuarlar": calculation_result["aksesuarlar"]}
    )
    
    db.add(new_record)
    db.commit()
    db.refresh(new_record)

    return {
        "status": "success",
        "message": "Hesaplama yapıldı ve başarıyla kaydedildi.",
        "record_id": new_record.id,
        "results": calculation_result
    }

@router.get("/history", response_model=List[GiyotinRecordResponse])
def get_giyotin_history(
    skip: int = 0, 
    limit: int = 50, 
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    Giriş yapan kullanıcının kendi şirketine ait geçmiş hesaplamaları listeler (Multi-tenant izolasyonu).
    """
    records = db.query(GiyotinRecord).filter(
        GiyotinRecord.company_id == current_user.company_id
    ).order_by(GiyotinRecord.created_at.desc()).offset(skip).limit(limit).all()
    
    return records

@router.get("/{record_id}/pdf")
def download_giyotin_pdf(
    record_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user)
):
    """
    Belirli bir giyotin kaydının PDF raporunu üretir ve indirir.
    """
    # Kaydı veritabanından çek ve bu şirkete ait olduğundan emin ol
    record = db.query(GiyotinRecord).filter(
        GiyotinRecord.id == record_id,
        GiyotinRecord.company_id == current_user.company_id
    ).first()

    if not record:
        raise HTTPException(status_code=404, detail="Kayıt bulunamadı veya erişim yetkiniz yok.")

    # SQLAlchemy modelini Dictionary'e çevir
    record_dict = {
        "project_name": record.project_name,
        "system_type": record.system_type,
        "width": record.width,
        "height": record.height,
        "quantity": record.quantity,
        "cost_details": record.cost_details,
        "cut_optimization": record.cut_optimization
    }

    # PDF'i oluştur (Şirket adını dinamik veriyoruz)
    pdf_bytes = PdfService.generate_giyotin_pdf(
        company_name=current_user.company.name, 
        record=record_dict
    )

    # Dosya adını güvenli hale getir
    safe_name = "".join(c for c in record.project_name if c.isalnum() or c in " _-").strip() or "Rapor"
    filename = f"Kavira_{safe_name}_{record_id}.pdf"

    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={"Content-Disposition": f'attachment; filename="{filename}"'},
    )