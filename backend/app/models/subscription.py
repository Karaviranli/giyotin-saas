from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey, Float
from sqlalchemy.orm import relationship
from datetime import datetime
from app.db.database import Base

class Subscription(Base):
    __tablename__ = "subscriptions"

    id = Column(Integer, primary_key=True, index=True)
    company_id = Column(Integer, ForeignKey("companies.id"), unique=True, nullable=False)
    
    plan_name = Column(String, default="Deneme Sürümü") # Temel, Pro, Sınırsız vb.
    price = Column(Float, default=0.0)
    
    start_date = Column(DateTime, default=datetime.utcnow)
    end_date = Column(DateTime, nullable=True) # None ise sınırsız
    is_active = Column(Boolean, default=True)
    
    max_users = Column(Integer, default=3) # Bu şirkete kaç personel eklenebilir?

    # İlişkiler
    company = relationship("Company", backref="subscription")