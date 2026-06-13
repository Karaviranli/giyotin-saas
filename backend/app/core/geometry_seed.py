"""
Vendor geometry + profil dimensions seed.

Katar referans değerleri kataloga göre.
Saray ve Zahit için makul tahminler (admin daha sonra düzenleyebilir).
"""

# Katar Alüminyum — kataloga göre exact ölçüler
KATAR_GEOMETRY = {
    "cam_adet": 3,
    "cam_en_eksiltme_mm": 149,
    "cam_boy_eksiltme_mm": 263,
    "yatay_profil_yan_pay_mm": 30,      # K-1401, K-1402
    "alt_kasa_yan_pay_mm": 45,           # K-1403
    "yan_dikme_dusus_mm": 175,           # K-1404, K-1405
    "ic_dikey_dusus_mm": 177,            # K-1408 ve sonrası
    "ic_kupeste_boy_ek_mm": 28,          # K-1407
    "ispanyolet_boy_ek_mm": 29,          # K-1410
    "yan_kutu_baza_ek_mm": 20,           # K-1406
    "fonksiyonel_baza_dikey_ek_mm": 37,  # K-1409 D
    "motor_borusu_yan_pay_mm": 75,
    "fire_payi_yuzde": 5,
}

KATAR_DIMENSIONS = {
    "K-1401": {"en": 142.0,    "boy": 38.3,  "tip": "kasa"},
    "K-1402": {"en": 123.21,   "boy": 7.8,   "tip": "kapak"},
    "K-1403": {"en": 120.25,   "boy": 32.25, "tip": "kasa", "et": 20.0},
    "K-1404": {"en": 69.46,    "boy": 29.86, "tip": "dikme"},
    "K-1405": {"en": 120.18,   "boy": 82.42, "tip": "dikme"},
    "K-1406": {"en": 55.46,    "boy": 35.9,  "tip": "baza"},
    "K-1407": {"en": 22.13,    "boy": 8.73,  "tip": "kapak"},
    "K-1408": {"en": 44.92,    "boy": 25.0,  "tip": "baza"},
    "K-1409": {"en": 25.0,     "boy": 39.61, "tip": "baza"},
    "K-1410": {"en": 71.07,    "boy": 38.64, "tip": "baza"},
    "K-1411": {"en": 71.37,    "boy": 48.27, "tip": "kanat"},
    "K-1412": {"en": 65.0,     "boy": 76.6,  "tip": "kupeste"},
}

# Saray GYT-80 — kataloğa göre (gyt80-1.png'den okudum)
SARAY_GEOMETRY = {
    "cam_adet": 3,
    "cam_en_eksiltme_mm": 178,           # Saray yan dikmesi 89mm derinliğinde, 2× = 178
    "cam_boy_eksiltme_mm": 280,
    "yatay_profil_yan_pay_mm": 30,
    "alt_kasa_yan_pay_mm": 45,
    "yan_dikme_dusus_mm": 200,
    "ic_dikey_dusus_mm": 195,
    "ic_kupeste_boy_ek_mm": 30,
    "ispanyolet_boy_ek_mm": 32,
    "yan_kutu_baza_ek_mm": 22,
    "fonksiyonel_baza_dikey_ek_mm": 40,
    "motor_borusu_yan_pay_mm": 80,
    "fire_payi_yuzde": 5,
}

SARAY_DIMENSIONS = {
    "14506": {"en": 130.0,    "boy": 127.4,  "tip": "kasa"},     # Kasa Kapak Ana
    "14507": {"en": 18.3,     "boy": 145.4,  "tip": "kapak"},    # Kasa Kapak Alt
    "14516": {"en": 16.1,     "boy": 75.9,   "tip": "kasa"},     # Yan Kasa Kapama
    "14517": {"en": 16.1,     "boy": 5.3,    "tip": "kapak"},    # Kapak Profili
    "14508": {"en": 17.5,     "boy": 108.4,  "tip": "kasa"},     # Yatay Alt Kasa
    "14509": {"en": 89.1,     "boy": 108.6,  "tip": "dikme"},    # Yan Kasa
    "14511": {"en": 22.0,     "boy": 108.3,  "tip": "pervaz"},   # Pervaz
    "14515": {"en": 35.2,     "boy": 74.8,   "tip": "ray"},      # Hareketli Ray
    "14510": {"en": 100.1,    "boy": 46.0,   "tip": "pervaz"},   # Hareketli Pervaz
    "14512": {"en": 35.3,     "boy": 41.5,   "tip": "kenet"},    # Kenet
    "14513": {"en": 17.1,     "boy": 31.9,   "tip": "kanat"},    # Yan Kanat
    "14514": {"en": 17.1,     "boy": 41.5,   "tip": "kanat"},    # Sabit Kanat
}

# Zahit Alüminyum — kataloga göre
ZAHIT_KLASIK_GEOMETRY = {
    "cam_adet": 3,
    "cam_en_eksiltme_mm": 145,
    "cam_boy_eksiltme_mm": 260,
    "yatay_profil_yan_pay_mm": 30,
    "alt_kasa_yan_pay_mm": 45,
    "yan_dikme_dusus_mm": 170,
    "ic_dikey_dusus_mm": 175,
    "ic_kupeste_boy_ek_mm": 28,
    "ispanyolet_boy_ek_mm": 29,
    "yan_kutu_baza_ek_mm": 20,
    "fonksiyonel_baza_dikey_ek_mm": 37,
    "motor_borusu_yan_pay_mm": 75,
    "fire_payi_yuzde": 5,
}

ZAHIT_KLASIK_DIMENSIONS = {
    "V.GY.106": {"en": 118.7, "boy": 44.2,  "tip": "kasa"},
    "V.GY.107": {"en": 28.5,  "boy": 32.0,  "tip": "baza"},
    "V.GY.108": {"en": 112.3, "boy": 34.3,  "tip": "kupeste"},
    "V.GY.110": {"en": 24.4,  "boy": 12.0,  "tip": "kapama"},
    "V.GY.207": {"en": 28.5,  "boy": 32.0,  "tip": "baza"},
    "V.GY.208": {"en": 106.9, "boy": 12.0,  "tip": "kupeste"},
    "V.ES.109": {"en": 36.0,  "boy": 32.0,  "tip": "kenet"},
    "V.ES.112": {"en": 30.4,  "boy": 12.0,  "tip": "kenet"},
}

ZAHIT_SILINEBILIR_GEOMETRY = {
    "cam_adet": 3,
    "cam_en_eksiltme_mm": 145,
    "cam_boy_eksiltme_mm": 260,
    "yatay_profil_yan_pay_mm": 30,
    "alt_kasa_yan_pay_mm": 45,
    "yan_dikme_dusus_mm": 170,
    "ic_dikey_dusus_mm": 175,
    "ic_kupeste_boy_ek_mm": 28,
    "ispanyolet_boy_ek_mm": 29,
    "yan_kutu_baza_ek_mm": 20,
    "fonksiyonel_baza_dikey_ek_mm": 37,
    "motor_borusu_yan_pay_mm": 75,
    "fire_payi_yuzde": 5,
}

ZAHIT_SILINEBILIR_DIMENSIONS = {
    "V.GY.204": {"en": 30.5,  "boy": 14.5,  "tip": "vasistas"},
    "V.GY.205": {"en": 118.6, "boy": 28.4,  "tip": "kasa"},
    "V.GY.206": {"en": 69.2,  "boy": 32.0,  "tip": "baza"},
    "V.GY.207": {"en": 28.5,  "boy": 32.0,  "tip": "baza"},
    "V.GY.208": {"en": 106.9, "boy": 12.0,  "tip": "kupeste"},
    "V.GY.209": {"en": 36.0,  "boy": 32.0,  "tip": "baza"},
    "V.ES.109": {"en": 36.0,  "boy": 32.0,  "tip": "kenet"},
    "V.ES.112": {"en": 30.4,  "boy": 12.0,  "tip": "kenet"},
    "V.GY.110": {"en": 24.4,  "boy": 12.0,  "tip": "kapama"},
}


def seed_geometry_and_dimensions(db):
    """Mevcut vendor sistemlerine geometry ve profil dimensions ekler."""
    from app.models.vendor import Vendor, VendorSystem, VendorProfile

    updated_systems = 0
    updated_profiles = 0

    mapping = [
        # (vendor_slug, sub_category, geometry_dict, dimensions_dict)
        ("katar",  "klasik",      KATAR_GEOMETRY,             KATAR_DIMENSIONS),
        ("saray",  "gyt80",       SARAY_GEOMETRY,             SARAY_DIMENSIONS),
        ("zahit",  "klasik",      ZAHIT_KLASIK_GEOMETRY,      ZAHIT_KLASIK_DIMENSIONS),
        ("zahit",  "silinebilir", ZAHIT_SILINEBILIR_GEOMETRY, ZAHIT_SILINEBILIR_DIMENSIONS),
    ]

    for slug, sub, geo, dims in mapping:
        vendor = db.query(Vendor).filter(Vendor.slug == slug).first()
        if not vendor:
            continue
        sys = db.query(VendorSystem).filter(
            VendorSystem.vendor_id == vendor.id,
            VendorSystem.sub_category == sub,
        ).first()
        if not sys:
            continue
        sys.geometry = geo
        updated_systems += 1

        # Profil dimensions güncelle
        for code, d in dims.items():
            p = db.query(VendorProfile).filter(
                VendorProfile.system_id == sys.id,
                VendorProfile.code == code,
            ).first()
            if p:
                p.dimensions = d
                updated_profiles += 1

    db.commit()
    return {
        "systems_updated": updated_systems,
        "profiles_updated": updated_profiles,
    }
