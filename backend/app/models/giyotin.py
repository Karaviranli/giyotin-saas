from sqlalchemy import Column, Integer, String, Float, ForeignKey, DateTime
from sqlalchemy import JSON  # PostgreSQL için JSON saklama
from sqlalchemy.orm import relationship
from datetime import datetime
from app.db.database import Base

class GiyotinRecord(Base):
    __tablename__ = "giyotin_records"

    id = Column(Integer, primary_key=True, index=True)
    company_id = Column(Integer, ForeignKey("companies.id"), nullable=False)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False) # İşlemi yapan personel
    
    project_name = Column(String, index=True, nullable=False) # Eski musteri_notu
    system_type = Column(String, default="3LÜ TEMİZLENİR")
    width = Column(Float, nullable=False)
    height = Column(Float, nullable=False)
    quantity = Column(Integer, default=1)
    
    # Hesaplama Çıktıları (Eski router.py'daki _hesapla fonksiyonunun sonuçları buraya JSON olarak yazılacak)
    cost_details = Column(JSON, nullable=True)       # Maliyet detayları ve kalemler
    cut_optimization = Column(JSON, nullable=True)   # Kesim planı ve fire oranları
    
    created_at = Column(DateTime, default=datetime.utcnow)

    # İlişkiler
    company = relationship("Company")
    user = relationship("User")