from sqlalchemy import Column, Integer, Float, ForeignKey, String
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
    # ── Detaylı aksesuar fiyatları (vendor-spesifik strategy'lerde kullanılır)
    kose_takozu_tl       = Column(Float, default=45.0)
    rulman_yatagi_tl     = Column(Float, default=28.0)
    boru_basi_tl         = Column(Float, default=35.0)
    vasistas_takoz_tl    = Column(Float, default=25.0)
    merkezleme_takozu_tl = Column(Float, default=12.0)
    baza_kapak_tl        = Column(Float, default=18.0)
    cam_fitili_m_tl      = Column(Float, default=8.5)
    kapak_fitili_m_tl    = Column(Float, default=6.0)
    firca_fitili_m_tl    = Column(Float, default=4.5)
    flock_fitili_m_tl    = Column(Float, default=5.0)
    kenet_fitili_m_tl    = Column(Float, default=7.0)
    zincir_m_tl          = Column(Float, default=95.0)
    zincir_dislisi_tl    = Column(Float, default=145.0)
    zincir_yonlendirici_tl = Column(Float, default=65.0)
    kayis_kasnagi_tl     = Column(Float, default=85.0)
    # ── Vasistas mekanizması (silinebilir/açılır panel sistemleri için kritik) ──
    vasistas_makas_tl       = Column(Float, default=180.0)   # gerçek vasistas makas (~150-300 TL)
    vasistas_kol_tl         = Column(Float, default=110.0)   # vasistas kol (~80-150 TL)
    ispanyolet_tl           = Column(Float, default=120.0)   # ispanyolet kilit (~80-200 TL)
    ispanyolet_karsilik_tl  = Column(Float, default=45.0)    # ispanyolet karşılığı (zamak ~30-60 TL)
    # ── Motor/kumanda mekanik aksesuarları ──
    tambur_tl               = Column(Float, default=50.0)    # Saray SC-934 tambur (~40-80 TL)
    push_kol_tl             = Column(Float, default=85.0)    # Tümen push kol (~60-120 TL)
    motor_lazer_tl          = Column(Float, default=130.0)   # motor lazer/boru başı lazer (~100-200 TL)
    # ── Sık kullanılan plastik aksesuarlar ──
    kanat_kose_plastik_tl   = Column(Float, default=8.0)     # Saray SC-935, Tema kanat köşe (~5-15 TL)
    denge_takozu_tl         = Column(Float, default=15.0)    # Saray SC-936 denge takozu (~10-25 TL)

    # ── Fiyatlandırma katmanları
    kar_marji_yuzde   = Column(Float, default=35.0)
    kdv_yuzde         = Column(Float, default=20.0)
    iscilik_sistem_tl = Column(Float, default=1500.0)
    nakliye_montaj_tl = Column(Float, default=0.0)
    preferred_vendor_slug = Column(String, nullable=True)
    preferred_vendor_subcategory = Column(String, nullable=True)

    company = relationship("Company", backref="settings")