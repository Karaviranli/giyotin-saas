"""
Vendor (Tedarikçi) sistemi.

3 katmanlı:
  Vendor (Katar, Saray, Zahit, Tümen, ...)
    └─ VendorSystem (Giyotin, Silinebilir Giyotin, GYT-80, ...)
         └─ VendorProfile (kod + kg/m + rol)

Profil rolleri tüm vendor'lar arasında ortaktır → hesaplama mantığı vendor-agnostic.

Bir Company kendi özel vendor'ını ekleyebilir (owner_company_id != NULL).
NULL = publike (sistemde gömülü) vendor.
"""
from datetime import datetime
from sqlalchemy import Column, Integer, String, Float, Boolean, DateTime, ForeignKey, JSON, UniqueConstraint
from sqlalchemy.orm import relationship
from app.db.database import Base


class Vendor(Base):
    """Alüminyum tedarikçisi (Katar, Saray, Zahit, vs.)"""
    __tablename__ = "vendors"

    id = Column(Integer, primary_key=True, index=True)
    slug = Column(String, unique=True, index=True, nullable=False)   # "katar", "saray", "zahit"
    name = Column(String, nullable=False)                            # "Katar Alüminyum"
    logo_url = Column(String, nullable=True)
    website = Column(String, nullable=True)
    is_active = Column(Boolean, default=True)
    is_default = Column(Boolean, default=False)                      # yeni şirket için varsayılan
    owner_company_id = Column(Integer, ForeignKey("companies.id"), nullable=True)  # NULL = publike
    created_at = Column(DateTime, default=datetime.utcnow)

    systems = relationship("VendorSystem", back_populates="vendor", cascade="all, delete-orphan")


class VendorSystem(Base):
    """Tedarikçinin sahip olduğu bir sistem (Giyotin, Silinebilir Giyotin, ...).
    Aynı vendor'ın birden fazla giyotin alt-türü olabilir (Zahit: Klasik + Silinebilir).
    """
    __tablename__ = "vendor_systems"

    id = Column(Integer, primary_key=True, index=True)
    vendor_id = Column(Integer, ForeignKey("vendors.id", ondelete="CASCADE"), nullable=False, index=True)
    category = Column(String, index=True, nullable=False)             # "giyotin" | "aluminyum" | "kepenk" ...
    sub_category = Column(String, nullable=True)                      # "klasik" | "silinebilir" | "isicamli"
    name = Column(String, nullable=False)                             # "Klasik Giyotin Sistemi"
    code_prefix = Column(String, nullable=True)                       # "K-14" | "V.GY.1" | "145" — UI'da gösterim
    profile_length_mm = Column(Float, default=6500)                   # Stok bar boyu (mm)
    geometry = Column(JSON, nullable=True)
    calc_strategy = Column(String, default="generic")  # katar / saray_gyt80 / zahit_klasik / zahit_silinebilir / generic                            # vendor-spesifik geometri parametreleri
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    vendor = relationship("Vendor", back_populates="systems")
    profiles = relationship("VendorProfile", back_populates="system", cascade="all, delete-orphan")

    __table_args__ = (UniqueConstraint("vendor_id", "category", "sub_category", name="uq_vendor_cat_subcat"),)


class VendorProfile(Base):
    """Tek bir profil — kod + ağırlık + rol.

    Role: hesaplama mantığında kullanılan semantik etiket.
      MOTOR_KUTUSU_ALT, MOTOR_KUTUSU_UST, ALT_KASA, YAN_KASA,
      YAN_DIKME_ANA, YAN_DIKME_ARA, YAN_KUTU_BAZA, YAN_DIKEY_KAPAK,
      VASISTAS_UST_BAZA, FONKSIYONEL_BAZA_YATAY, FONKSIYONEL_BAZA_DIKEY,
      ISPANYOLET_BAZA, KENET_CEKME, HAREKETLI_UST_KUPESTE, MOTOR_BORUSU,
      HAREKETLI_KUPESTE, KUPESTE_BAZA, ALT_BAZA, KAPAK, KENET, VS.
    """
    __tablename__ = "vendor_profiles"

    id = Column(Integer, primary_key=True, index=True)
    system_id = Column(Integer, ForeignKey("vendor_systems.id", ondelete="CASCADE"), nullable=False, index=True)
    code = Column(String, index=True, nullable=False)                # "K-1401", "14506", "V.GY.106"
    name = Column(String, nullable=False)                            # "Motor Kutusu Alt/Üst"
    role = Column(String, index=True, nullable=True)                 # "MOTOR_KUTUSU_ALT" — hesaplama anahtarı
    kg_per_m = Column(Float, nullable=False)                         # 1.293
    dimensions = Column(JSON, nullable=True)                         # {"en": 38.3, "boy": 142, "et": 7.8}
    notes = Column(String, nullable=True)
    sort_order = Column(Integer, default=0)

    system = relationship("VendorSystem", back_populates="profiles")

    __table_args__ = (UniqueConstraint("system_id", "code", name="uq_system_code"),)
