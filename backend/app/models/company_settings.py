from sqlalchemy import Column, Integer, Float, ForeignKey
from sqlalchemy.orm import relationship
from app.db.database import Base

class CompanySettings(Base):
    __tablename__ = "company_settings"

    id = Column(Integer, primary_key=True, index=True)
    company_id = Column(Integer, ForeignKey("companies.id"), unique=True, nullable=False)
    
    aluminyum_kg_tl = Column(Float, default=368.0)
    cam_m2_tl = Column(Float, default=1915.0)
    kayis_m_tl = Column(Float, default=150.0)
    boru_m_tl = Column(Float, default=204.0)
    kayisli_set_tl = Column(Float, default=4104.0)
    kumanda_tl = Column(Float, default=860.0)
    motor_tl = Column(Float, default=3765.0)
    genel_gider_yuzde = Column(Float, default=2.5)

    company = relationship("Company", backref="settings")