from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from datetime import datetime
from app.db.database import Base


class PromoCode(Base):
    __tablename__ = "promo_codes"

    id = Column(Integer, primary_key=True, index=True)
    code = Column(String, unique=True, nullable=False, index=True)
    description = Column(String, nullable=True)
    duration_days = Column(Integer, default=30, nullable=False)  # kaç günlük abonelik verir
    max_uses = Column(Integer, nullable=True)   # None = sınırsız kullanım
    used_count = Column(Integer, default=0, nullable=False)
    is_active = Column(Boolean, default=True, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)
    expires_at = Column(DateTime, nullable=True)  # None = süresiz

    usages = relationship("PromoCodeUsage", back_populates="promo_code")


class PromoCodeUsage(Base):
    __tablename__ = "promo_code_usages"

    id = Column(Integer, primary_key=True, index=True)
    promo_code_id = Column(Integer, ForeignKey("promo_codes.id"), nullable=False)
    company_id = Column(Integer, ForeignKey("companies.id"), nullable=False)
    used_at = Column(DateTime, default=datetime.utcnow)

    promo_code = relationship("PromoCode", back_populates="usages")
