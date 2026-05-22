from sqlalchemy import Column, Integer, String, Float
from app.db.database import Base

class ProductSystem(Base):
    __tablename__ = "product_systems"
    
    id = Column(Integer, primary_key=True, index=True)
    kategori = Column(String, index=True, nullable=False)
    isim = Column(String, index=True, nullable=False)
    kg_katsayi = Column(Float, default=0.0)
    ozel_katsayi = Column(Float, default=1.0)
    ekstra_ayar = Column(String, nullable=True) # JSON verisi olarak saklanabilir