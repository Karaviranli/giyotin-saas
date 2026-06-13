"""
Vendor-aware giyotin hesap motoru.

Mantık:
  1. Şirketin aktif vendor + sub_category seçimini al (yoksa default vendor)
  2. O sistemin profillerini DB'den çek → {role: VendorProfile} sözlüğü
  3. CompanySettings'ten birim fiyatları al (motor, kayış, cam vs.)
  4. Hesap formülünü role'lere göre uygula

Bu sayede:
  - Hesap formülü vendor-bağımsız (rol bazlı)
  - Profil kg/m vendor'a özel (DB'den)
  - Birim fiyatlar şirkete özel (settings'ten)
"""
import math
from typing import Optional
from sqlalchemy.orm import Session
from app.models.vendor import Vendor, VendorSystem, VendorProfile
from app.models.company_settings import CompanySettings
from app.models.user import User


# ── Role haritası — Hesap formülünde geometri:
#    her rol için (ölçü_formülü, adet_çarpan) tuple'ı.
#    Formül width(w), height(h), cam_boy değişkenlerini kullanır.
# Vendor farklı profil setine sahip olduğunda bu haritada eksik kalan roller
# atlanır (silent skip). En azından temel profillere göre hesap yapılır.
PROFIL_LAYOUT = {
    # Geometrik formül: (kod, lambda w,h,cb: olcu_mm, adet_carpani)
    "MOTOR_KUTUSU_ALT":      lambda w, h, cb: (w - 30,           1),
    "MOTOR_KUTUSU_UST":      lambda w, h, cb: (w - 30,           1),
    "ALT_KASA":              lambda w, h, cb: (w - 45,           1),
    "YAN_DIKME_ANA":         lambda w, h, cb: (h - 175,          2),
    "YAN_DIKME_ARA":         lambda w, h, cb: (h - 175,          2),
    "YAN_KUTU_BAZA":         lambda w, h, cb: ((cb * 2) + 20,    2),
    "YAN_DIKEY_KAPAK":       lambda w, h, cb: (cb + 28,          2),
    "VASISTAS_UST_BAZA":     lambda w, h, cb: (w - 177,          1),
    "FONKSIYONEL_BAZA":      lambda w, h, cb: (w - 177,          6),
    "ISPANYOLET_BAZA":       lambda w, h, cb: (cb + 29,          2),
    "KENET_CEKME":           lambda w, h, cb: (w - 177,          3),
    "HAREKETLI_UST_KUPESTE": lambda w, h, cb: (w - 177,          1),
    # Saray varyasyonları
    "KASA_KAPAK":            lambda w, h, cb: (w - 30,           1),
    "KASA_KAPAK_ALT":        lambda w, h, cb: (w - 30,           1),
    "YAN_KASA":              lambda w, h, cb: (h - 175,          2),
    "HAREKETLI_PERVAZ":      lambda w, h, cb: (w - 177,          2),
    "PERVAZ":                lambda w, h, cb: (w - 177,          2),
    "YAN_KANAT":             lambda w, h, cb: (cb + 29,          2),
    "SABIT_KANAT":           lambda w, h, cb: (cb + 28,          2),
    "HAREKETLI_RAY":         lambda w, h, cb: (w - 177,          1),
    "YAN_KASA_KAPAMA":       lambda w, h, cb: (h - 175,          2),
    "KAPAK":                 lambda w, h, cb: (w - 177,          1),
    # Zahit varyasyonları
    "SABIT_KUPESTE":         lambda w, h, cb: (w - 177,          1),
    "ALT_BAZA":              lambda w, h, cb: (w - 45,           1),
    "TUTAMAKLI_BAZA":        lambda w, h, cb: (w - 177,          1),
    "ORTA_ALT_BAZA":         lambda w, h, cb: (w - 177,          1),
    "KUPESTE_BAZA":          lambda w, h, cb: (cb + 29,          2),
    "HAREKETLI_KUPESTE":     lambda w, h, cb: (w - 177,          1),
    "VASISTAS_KASA":         lambda w, h, cb: (cb + 29,          2),
    "YAN_KAPAMA":            lambda w, h, cb: (h - 175,          2),
    "KENET_DESTEK":          lambda w, h, cb: (w - 177,          3),
}


def get_active_vendor_system(db: Session, user: User) -> Optional[VendorSystem]:
    """Şirketin aktif vendor + sub_category seçimini döner.
    Yoksa default vendor'ın ilk giyotin sistemini döner.
    """
    settings = db.query(CompanySettings).filter(
        CompanySettings.company_id == user.company_id
    ).first()

    slug = getattr(settings, "preferred_vendor_slug", None) if settings else None
    sub = getattr(settings, "preferred_vendor_subcategory", None) if settings else None

    if slug:
        vendor = db.query(Vendor).filter(
            Vendor.slug == slug, Vendor.is_active == True
        ).first()
    else:
        vendor = db.query(Vendor).filter(
            Vendor.is_default == True, Vendor.is_active == True
        ).first()

    if not vendor:
        return None

    q = db.query(VendorSystem).filter(
        VendorSystem.vendor_id == vendor.id,
        VendorSystem.category == "giyotin",
        VendorSystem.is_active == True,
    )
    if sub:
        q = q.filter(VendorSystem.sub_category == sub)
    system = q.first()
    if not system:
        # sub seçimi eski/geçersiz olabilir — ilk aktif giyotin'i al
        system = db.query(VendorSystem).filter(
            VendorSystem.vendor_id == vendor.id,
            VendorSystem.category == "giyotin",
            VendorSystem.is_active == True,
        ).first()
    return system


def get_pricing(db: Session, user: User) -> dict:
    """Şirketin kendi fiyatları + güvenli default."""
    s = db.query(CompanySettings).filter(
        CompanySettings.company_id == user.company_id
    ).first()
    if not s:
        return {
            "aluminyum_kg_tl": 368.0, "cam_m2_tl": 1915.0,
            "kayis_m_tl": 150.0, "boru_m_tl": 204.0,
            "kayisli_set_tl": 4104.0, "kumanda_tl": 860.0,
            "motor_tl": 3765.0, "genel_gider_yuzde": 2.5,
        }
    return {
        "aluminyum_kg_tl":  s.aluminyum_kg_tl or 368.0,
        "cam_m2_tl":        s.cam_m2_tl or 1915.0,
        "kayis_m_tl":       s.kayis_m_tl or 150.0,
        "boru_m_tl":        s.boru_m_tl or 204.0,
        "kayisli_set_tl":   s.kayisli_set_tl or 4104.0,
        "kumanda_tl":       s.kumanda_tl or 860.0,
        "motor_tl":         s.motor_tl or 3765.0,
        "genel_gider_yuzde": s.genel_gider_yuzde or 2.5,
    }


def calculate(
    db: Session,
    user: User,
    width: float,
    height: float,
    quantity: int,
    stock_length: float = 6500.0,
    kerf: float = 3.0,
    marj: float = 1.30,
    kdv: float = 0.20,
) -> dict:
    """Vendor-aware giyotin hesabı.
    Hesabı yapan kullanıcının şirketinin aktif vendor profil ve fiyat ayarlarını kullanır.
    """
    system = get_active_vendor_system(db, user)
    if not system:
        raise ValueError("Aktif vendor/sistem bulunamadı. Lütfen Ayarlar > Tedarikçi'den seç.")

    # Profil sözlüğü (role -> profil) ve liste
    profiles = db.query(VendorProfile).filter(
        VendorProfile.system_id == system.id
    ).order_by(VendorProfile.sort_order.asc()).all()

    role_to_profile: dict = {}
    for p in profiles:
        if p.role and p.role not in role_to_profile:
            role_to_profile[p.role] = p

    # Stock length sistemden gelir
    stock_length = system.profile_length_mm or stock_length

    p_price = get_pricing(db, user)
    alm_kg_tl = p_price["aluminyum_kg_tl"]

    # Cam ölçüleri (Katar/Saray/Zahit ortak)
    cam_en  = width - 149
    cam_boy = (height - 263) / 3
    cam_adet = quantity * 3
    cam_m2  = (cam_en * cam_boy * cam_adet) / 1_000_000

    # Profil maliyeti — role bazlı
    profil_kalemleri = []
    profil_tl_toplam = 0.0
    profil_kg_toplam = 0.0
    for role, layout_fn in PROFIL_LAYOUT.items():
        prof = role_to_profile.get(role)
        if not prof:
            continue  # bu vendor'da bu rol yok, atla
        olcu_mm, adet_carpan = layout_fn(width, height, cam_boy)
        adet = quantity * adet_carpan
        stok_say = math.ceil((adet * (olcu_mm + kerf)) / stock_length)
        kullanilan_m = stok_say * (stock_length / 1000)
        kg = kullanilan_m * (prof.kg_per_m or 0.0)
        tl = kg * alm_kg_tl
        profil_tl_toplam += tl
        profil_kg_toplam += kg
        profil_kalemleri.append({
            "code": prof.code, "name": prof.name, "role": role,
            "olcu_mm": round(olcu_mm, 1), "adet": adet,
            "stok_say": stok_say, "kullanilan_m": round(kullanilan_m, 2),
            "kg": round(kg, 2), "tl": round(tl, 2),
            "kg_per_m": prof.kg_per_m,
        })

    # Motor borusu (G.AKS1001 vs.) — varsayılan formül
    boru_stok = math.ceil((quantity * (width - 75 + kerf)) / stock_length)
    boru_m = boru_stok * (stock_length / 1000)
    boru_tl = boru_m * p_price["boru_m_tl"]

    # Kayış (formül: (h/4) * 4.7 * qty / 1000)
    kayis_m = round((height / 4) * 4.7 * quantity / 1000, 3)
    kayis_tl = kayis_m * p_price["kayis_m_tl"]

    cam_tl = cam_m2 * p_price["cam_m2_tl"]
    sabit_tl = quantity * (p_price["kayisli_set_tl"] + p_price["motor_tl"]) + p_price["kumanda_tl"]

    ara_toplam = profil_tl_toplam + boru_tl + kayis_tl + cam_tl + sabit_tl
    gg_tl = ara_toplam * (p_price["genel_gider_yuzde"] / 100)
    maliyet = ara_toplam + gg_tl

    kdv_haric = round(maliyet * marj, 2)
    kdv_tl = round(kdv_haric * kdv, 2)
    genel_toplam = round(kdv_haric + kdv_tl, 2)

    return {
        # — Vendor bilgisi —
        "vendor": {
            "slug": system.vendor.slug,
            "name": system.vendor.name,
            "system": system.name,
            "sub_category": system.sub_category,
            "code_prefix": system.code_prefix,
        },
        # — Fiyatlandırma —
        "ara_toplam_tl":  round(ara_toplam, 2),
        "genel_gider_tl": round(gg_tl, 2),
        "maliyet_tl":     round(maliyet, 2),
        "kdv_haric_tl":   kdv_haric,
        "kdv_tl":         kdv_tl,
        "genel_toplam_tl": genel_toplam,
        "birim_fiyat_tl": round(genel_toplam / max(quantity, 1), 2),
        # — Detay —
        "kalemler": {
            "profil_tl": round(profil_tl_toplam, 2),
            "profil_kg": round(profil_kg_toplam, 2),
            "motor_borusu_tl": round(boru_tl, 2),
            "kayis_tl": round(kayis_tl, 2),
            "cam_tl": round(cam_tl, 2),
            "sabit_aksesuar_tl": round(sabit_tl, 2),
        },
        "profil_detay":   profil_kalemleri,
        "cam_detay":      {"en": round(cam_en, 1), "boy": round(cam_boy, 1),
                            "adet": cam_adet, "m2": round(cam_m2, 3)},
        "kullanilan_fiyatlar": p_price,
        "stock_length_mm": stock_length,
    }
