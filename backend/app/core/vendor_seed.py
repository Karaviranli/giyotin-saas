"""
Vendor seed — başlangıç tedarikçi ve profil katalogları.

Çağrılma: backend startup'ta veya manuel /admin/seed-vendors endpoint'inden.
Idempotent: zaten varsa atlar.
"""
from sqlalchemy.orm import Session
from app.models.vendor import Vendor, VendorSystem, VendorProfile

# ──────────────────────────────────────────────────────────────────────
# KATAR ALÜMİNYUM — Giyotin (mevcut sistemin migrate edilmiş hali)
# ──────────────────────────────────────────────────────────────────────
KATAR_GIYOTIN = [
    # (code, name, role, kg_per_m)
    ("K-1401", "Motor Kutusu Alt",          "MOTOR_KUTUSU_ALT",       1.293),
    ("K-1402", "Motor Kutusu Üst",          "MOTOR_KUTUSU_UST",       0.669),
    ("K-1403", "Alt Kasa",                  "ALT_KASA",               1.355),
    ("K-1404", "Yan Ara Dikme",             "YAN_DIKME_ARA",          0.653),
    ("K-1405", "Yan Ana Dikme",             "YAN_DIKME_ANA",          1.650),
    ("K-1406", "Yan Kutu Baza",             "YAN_KUTU_BAZA",          1.005),
    ("K-1407", "Yan Dikey Kapak",           "YAN_DIKEY_KAPAK",        0.203),
    ("K-1408", "Vasistas Üst Baza",         "VASISTAS_UST_BAZA",      0.883),
    ("K-1409", "Fonksiyonel Baza",          "FONKSIYONEL_BAZA",       0.699),
    ("K-1410", "İspanyolet Baza",           "ISPANYOLET_BAZA",        0.726),
    ("K-1411", "Kenet Çekme Profil",        "KENET_CEKME",            0.737),
    ("K-1412", "Hareketli Üst Küpeşte",     "HAREKETLI_UST_KUPESTE",  0.366),
    ("G.AKS1001", "Motor Borusu (Sekizgen)","MOTOR_BORUSU",           0.000),  # ayrı hesap (TL/m)
]

# ──────────────────────────────────────────────────────────────────────
# SARAY MİMARİ SİSTEMLER — GYT-80 Guillotine
# ──────────────────────────────────────────────────────────────────────
SARAY_GYT80 = [
    ("14506", "Kasa Kapak Profili",         "KASA_KAPAK",             2.635),
    ("14507", "Kasa Kapak Profili (Alt)",   "KASA_KAPAK_ALT",         0.950),
    ("14508", "Yatay Alt Kasa",             "ALT_KASA",               1.035),
    ("14509", "Yan Kasa",                   "YAN_KASA",               1.775),
    ("14510", "Hareketli Pervaz",           "HAREKETLI_PERVAZ",       1.225),
    ("14511", "Pervaz",                     "PERVAZ",                 0.575),
    ("14512", "Kenet Profili",              "KENET_CEKME",            1.010),
    ("14513", "Yan Kanat Profili",          "YAN_KANAT",              0.470),
    ("14514", "Sabit Kanat Profili",        "SABIT_KANAT",            0.680),
    ("14515", "Hareketli Ray Profili",      "HAREKETLI_RAY",          0.850),
    ("14516", "Yan Kasa Kapama",            "YAN_KASA_KAPAMA",        0.400),
    ("14517", "Kapak Profili",              "KAPAK",                  0.080),
]

# ──────────────────────────────────────────────────────────────────────
# ZAHİT ALÜMİNYUM — Klasik Giyotin Sistemi
# ──────────────────────────────────────────────────────────────────────
ZAHIT_KLASIK = [
    ("V.GY.106", "Alt Kasa Profili",        "ALT_KASA",               1.295),
    ("V.GY.107", "Alt Baza Profili",        "ALT_BAZA",               0.494),
    ("V.GY.108", "Sabit Küpeşte Profili",   "SABIT_KUPESTE",          0.880),
    ("V.GY.110", "Yan Kapama Profili",      "YAN_KAPAMA",             0.100),
    ("V.GY.207", "Küpeşte Baza Profili",    "KUPESTE_BAZA",           0.575),
    ("V.GY.208", "Hareketli Küpeşte",       "HAREKETLI_KUPESTE",      0.573),
    ("V.ES.109", "Kenet Profili",           "KENET_CEKME",            0.606),
    ("V.ES.112", "Kenet Destek Profili",    "KENET_DESTEK",           0.130),
]

# ──────────────────────────────────────────────────────────────────────
# ZAHİT ALÜMİNYUM — Silinebilir Giyotin Sistemi
# ──────────────────────────────────────────────────────────────────────
ZAHIT_SILINEBILIR = [
    # Vetrina kataloğu sayfa 5 — kg/m değerleri katalogdan bire bir alınmıştır.
    ("V.GY.104", "Motor Kapak Profili",     "MOTOR_KAPAK",            2.430),  # katalog: 2.430 (önceki 2.452 değil)
    ("V.GY.105", "Motor Kapak Kapatma",     "MOTOR_KAPAK_KAPATMA",    0.837),
    ("V.GY.103", "Dikey Baza Profili",      "DIKEY_BAZA",             0.706),
    ("V.GY.111", "Damlalık Profili",        "DAMLALIK",               0.237),  # yeni katalogla eklendi
    ("V.GY.204", "Vasistas Kasa",           "VASISTAS_KASA",          0.342),
    ("V.GY.205", "Alt Kasa Profili",        "ALT_KASA",               1.561),
    ("V.GY.206", "Tutamaklı Baza",          "TUTAMAKLI_BAZA",         0.890),
    ("V.GY.207", "Küpeşte Baza",            "KUPESTE_BAZA",           0.575),
    ("V.GY.208", "Hareketli Küpeşte",       "HAREKETLI_KUPESTE",      0.573),
    ("V.GY.209", "Orta Alt Baza",           "ORTA_ALT_BAZA",          0.655),
    ("V.ES.109", "Kenet Profili",           "KENET_CEKME",            0.606),
    ("V.ES.112", "Kenet Destek",            "KENET_DESTEK",           0.130),
    ("V.GY.110", "Yan Kapama",              "YAN_KAPAMA",             0.100),
    ("2458",     "Motor Kapak (Sekizgen)",  "MOTOR_KAPAK_KECE",       0.065),
]


# ──────────────────────────────────────────────────────────────────────
# TÜMEN ALÜMİNYUM — GI-ART Giyotin Cam Sistemi (G-29XX serisi)
# Kaynak: Tümen Alüminyum Ürün Kataloğu — Klasik/Temizlenebilir varyantları.
# ──────────────────────────────────────────────────────────────────────
TUMEN_GIART = [
    ("G-2924", "Motor Şase",                  "MOTOR_SASE",             2.946),  # en ağır profil (127×165)
    ("G-2918", "Şase Kapak",                  "SASE_KAPAK",             0.881),
    ("G-2919", "Küpeşte Kapak",               "KUPESTE_KAPAK",          0.534),
    ("G-2912", "Alt Kasa",                    "ALT_KASA",               1.450),
    ("G-2917", "Tutamaklı Çekme",             "TUTAMAKLI_CEKME",        1.266),  # silinebilir versiyon için
    ("G-2914", "Çekme Profili",               "CEKME_PROFIL",           0.943),
    ("G-2915", "Yan Baza",                    "YAN_BAZA",               0.566),
    ("G-2921", "Yatay Baza",                  "YATAY_BAZA",             0.767),
    ("G-2922", "Yan Kasa",                    "YAN_KASA",               2.100),  # büyük yan kasa (119.5×94.9)
    ("G-2920", "L Kanal",                     "L_KANAL",                0.686),
    ("G-2913", "Kasa Dış Kapak",              "KASA_DIS_KAPAK",         0.686),
    ("G-2916", "Kilit Baza",                  "KILIT_BAZA",             1.306),
    ("G-2927", "8mm Tek Cam Çıta",            "CAM_CITA",               0.274),
    ("G-2923", "Alın Kapak",                  "ALIN_KAPAK",             0.328),
    ("G-2926", "Motor Borusu (Ø57.9)",        "MOTOR_BORUSU",           1.209),
]


# ──────────────────────────────────────────────────────────────────────
# ASISTAL — G130T Isıcamlı Giyotin Sürme Cam Balkon Sistemi
# Kaynak: g130t-2024 resmi katalog (Profil Listesi + Aksesuar Listesi)
# ──────────────────────────────────────────────────────────────────────
ASISTAL_G130T = [
    ("G130T-01", "Üst Kasa Profili",                "MOTOR_KUTUSU_UST",   2.152),
    ("G130T-02", "Yan Kasa Profili",                "YAN_KASA",           2.054),
    ("G130T-03", "Alt Kasa Profili",                "ALT_KASA",           1.713),
    ("G130T-04", "Kasa Adaptör Profili",            "KASA_ADAPTOR",       0.710),
    ("G130T-05", "İspanyolet Kilitleme Profili",    "ISPANYOLET",         0.659),
    ("G130T-06", "Kapak Profili",                   "KAPAK_UST",          0.528),
    ("G130T-07", "Kapak Profili (Alt)",             "KAPAK_ALT",          0.163),
    ("G130T-08", "Tek Cam Çıta Profili",            "CAM_CITA",           0.277),
    ("G130T-09", "Kanat Profili",                   "KANAT_ALT",          0.716),
    ("G130T-10", "Alt Kanat Profili",               "ALT_KANAT",          0.813),
    ("G130T-11", "Kanat Profili",                   "KANAT_DESTEK",       0.941),
    ("G130T-12", "Takviyeli Kanat Profili",         "KANAT_TAKVIYE",      1.275),
    ("G130T-13", "Kanat Profili (Ana)",             "KANAT_ANA",          1.076),
    ("G100-A12", "Motor Borusu (Sekizgen Galvaniz)", "MOTOR_BORUSU",       0.000),
]

# ──────────────────────────────────────────────────────────────────────
# TEMA ALÜMİNYUM — Isı Camlı Giyotin Sistemleri (T.24xx)
# Kaynak: Tema Alüminyum Isı Camlı Giyotin Sistemleri kataloğu
# ──────────────────────────────────────────────────────────────────────
TEMA_ISICAM = [
    ("T.2401", "Üst Kutu Şase Profili",              "UST_KUTU",           3.182),
    ("T.2402", "Üst Kutu Kapak Profili",             "UST_KUTU_KAPAK",     0.915),
    ("T.2450", "Alt Kasa Profili",                   "ALT_KASA",           1.132),
    ("T.2451", "Yan Ara Profili",                    "YAN_DIKME_ARA",      0.657),
    ("T.2452", "Yan Kapatma Profili",                "YAN_DIKEY_KAPAK",    1.241),
    ("T.2454", "Cam Çıta Profili (Yan)",             "CAM_CITA",           0.633),
    ("T.2455", "Kenet Çekme Profili",                "KENET_CEKME",        1.007),
    ("T.2457", "Cam Çıta Profili (Alt)",             "CAM_CITA_ALT",       0.647),
    ("T.2466", "Alt Kasa Kapağı",                    "ALT_KASA_KAPAK",     0.948),
    ("T.2467", "Yan Bağlantı Profili",               "YAN_BAGLANTI",       0.673),
    ("T.2468", "Vasistas Profili",                   "VASISTAS_PROFIL",    1.346),
    ("T.2490", "1. Kanat Yan Profili",               "KANAT_YAN_1",        0.898),
    ("T.2491", "2. Kanat Yan Profili",               "KANAT_YAN_2",        0.917),
    ("T.2492", "3. Kanat Yan Profili",               "KANAT_YAN_3",        0.871),
    ("T.2493", "1. Kanat Üst/Alt Kapak Profili",     "KANAT_ALT_UST_1",    0.999),
    ("T.2494", "Yardımcı Profil",                    "YARDIMCI_PROFIL",    1.125),
    ("T.2495", "Kanat Sabitleme Aparatı Profili",    "KANAT_SABITLEME",    1.777),
    ("T.2496", "Alt Profil",                         "ALT_CITA",           1.035),
    ("T.2498", "Üst Profil",                         "UST_CITA",           1.191),
    ("T.2499", "Yan Profil (Yardımcı)",              "YAN_KASA",           0.530),
    ("TA.28.01.71.20", "Motor Borusu (70mm Galvanizli)", "MOTOR_BORUSU",   0.000),
]

# ──────────────────────────────────────────────────────────────────────
# MAVERA MİMARLIK (MVR) — Giyotin Cam Sistemi Ürün Kataloğu 2025
# Kaynak: Mavera Mimarlık ürün kataloğu (hem ısı cam hem tek cam alternatifi)
# ──────────────────────────────────────────────────────────────────────
MAVERA_GIYOTIN = [
    ("KIF-0001", "Ana Şase",                         "ANA_SASE",           2.295),
    ("KIF-0002", "Şase Kapak",                       "SASE_KAPAK",         2.166),
    ("TG-103",   "Yan Kasa Alt",                     "YAN_KASA_ALT",       1.169),
    ("TG-104",   "Yan Kasa Üst",                     "YAN_KASA_UST",       2.190),
    ("TG-108",   "Yan Kasa Kapak",                   "YAN_KASA_KAPAK",     0.108),
    ("TG-109",   "Küpeşte Bağlantı Profili",         "KUPESTE_BAGLANTI",   0.282),
    ("TG-102",   "Küpeşte",                          "KUPESTE",            0.580),
    ("TGI-105",  "Baza (Isı Cam)",                   "BAZA_ISI",           0.629),
    ("TGI-106",  "Kenet (Isı Cam)",                  "KENET_CEKME",        0.913),
    ("TGI-107",  "Açılır Cam Baza (Isı Cam)",        "ACILIR_BAZA",        0.886),
    ("TCT-105",  "Baza (Tek Cam)",                   "BAZA_TEK",           0.629),
    ("TCT-106",  "Kenet (Tek Cam)",                  "KENET_CEKME_TEK",    0.913),
    ("TCT-107",  "Açılır Cam Baza (Tek Cam)",        "ACILIR_BAZA_TEK",    0.886),
    ("MVR.MOTOR", "Motor Borusu (Sekizgen Demir)",   "MOTOR_BORUSU",       0.000),
]


VENDORS_SEED = [
    {
        "slug": "katar",
        "name": "Katar Alüminyum",
        "website": "https://katar.com.tr",
        "is_default": True,          # yeni şirketlerin varsayılanı
        "systems": [
            {
                "category": "giyotin",
                "sub_category": "klasik",
                "name": "Klasik Giyotin",
                "code_prefix": "K-14",
                "calc_strategy": "katar",
                "profile_length_mm": 6500,
                "profiles": KATAR_GIYOTIN,
            },
        ],
    },
    {
        "slug": "saray",
        "name": "Saray Mimari Sistemler",
        "website": "https://www.saraymimari.com",
        "is_default": False,
        "systems": [
            {
                "category": "giyotin",
                "sub_category": "gyt80",
                "name": "GYT-80 Guillotine",
                "code_prefix": "145",
                "calc_strategy": "saray_gyt80",
                "profile_length_mm": 6500,
                "profiles": SARAY_GYT80,
            },
        ],
    },
    {
        "slug": "zahit",
        "name": "Zahit Alüminyum",
        "website": "https://zahit.com.tr",
        "is_default": False,
        "systems": [
            {
                "category": "giyotin",
                "sub_category": "klasik",
                "name": "Klasik Giyotin",
                "code_prefix": "V.GY.1",
                "calc_strategy": "zahit_klasik",
                "profile_length_mm": 6500,
                "profiles": ZAHIT_KLASIK,
            },
            {
                "category": "giyotin",
                "sub_category": "silinebilir",
                "name": "Silinebilir Giyotin (Vetrina)",
                "code_prefix": "V.GY.2",
                "calc_strategy": "zahit_silinebilir",
                "profile_length_mm": 6500,
                "profiles": ZAHIT_SILINEBILIR,
            },
        ],
    },
    {
        "slug": "asistal",
        "name": "Asistal Alüminyum",
        "website": "https://www.asistal.com.tr",
        "is_default": False,
        "systems": [
            {
                "category": "giyotin",
                "sub_category": "g130t",
                "name": "G130T Isıcamlı Giyotin",
                "code_prefix": "G130T",
                "calc_strategy": "asistal_g130t",
                "profile_length_mm": 6500,
                "profiles": ASISTAL_G130T,
            },
        ],
    },
    {
        "slug": "tema",
        "name": "Tema Alüminyum",
        "website": "https://temaaluminyum.com.tr",
        "is_default": False,
        "systems": [
            {
                "category": "giyotin",
                "sub_category": "isicam",
                "name": "Isı Camlı Giyotin",
                "code_prefix": "T.24",
                "calc_strategy": "tema_isicam",
                "profile_length_mm": 6500,
                "profiles": TEMA_ISICAM,
            },
        ],
    },
    {
        "slug": "mavera",
        "name": "Mavera Mimarlık (MVR)",
        "website": "https://www.maveramimarlik.com",
        "is_default": False,
        "systems": [
            {
                "category": "giyotin",
                "sub_category": "isicam",
                "name": "Giyotin Cam Sistemi (Isı Cam)",
                "code_prefix": "TG",
                "calc_strategy": "mavera",
                "profile_length_mm": 6500,
                "profiles": MAVERA_GIYOTIN,
            },
        ],
    },
    {
        "slug": "tumen",
        "name": "Tümen Alüminyum",
        "website": "https://www.tumenaluminyum.com",
        "is_default": False,
        "systems": [
            {
                "category": "giyotin",
                "sub_category": "giart",
                "name": "GI-ART Giyotin Cam Sistemi",
                "code_prefix": "G-29",
                "calc_strategy": "tumen_giart",
                "profile_length_mm": 6500,
                "profiles": TUMEN_GIART,
            },
        ],
    },
]


def seed_vendors(db: Session, force: bool = False) -> dict:
    """Vendor + system + profil seed'i çalıştırır.

    force=False: zaten kayıtlı vendor varsa atlar.
    force=True: profile listesini günceller (kg/m güncellemeleri için).
    """
    added_vendors = 0
    added_systems = 0
    added_profiles = 0
    updated_profiles = 0

    for vd in VENDORS_SEED:
        vendor = db.query(Vendor).filter(Vendor.slug == vd["slug"]).first()
        if not vendor:
            vendor = Vendor(
                slug=vd["slug"], name=vd["name"],
                website=vd.get("website"),
                is_default=vd.get("is_default", False),
                is_active=True,
                owner_company_id=None,
            )
            db.add(vendor)
            db.flush()
            added_vendors += 1
        elif not force:
            continue

        for sd in vd["systems"]:
            system = (
                db.query(VendorSystem)
                .filter(
                    VendorSystem.vendor_id == vendor.id,
                    VendorSystem.category == sd["category"],
                    VendorSystem.sub_category == sd.get("sub_category"),
                )
                .first()
            )
            if not system:
                system = VendorSystem(
                    vendor_id=vendor.id,
                    category=sd["category"],
                    sub_category=sd.get("sub_category"),
                    name=sd["name"],
                    code_prefix=sd.get("code_prefix"),
                    calc_strategy=sd.get("calc_strategy", "generic"),
                    profile_length_mm=sd.get("profile_length_mm", 6500),
                    is_active=True,
                )
                db.add(system)
                db.flush()
                added_systems += 1
            elif force:
                # mevcut sistemde calc_strategy/name güncellemesi (yeni katalog gelirse)
                system.name = sd["name"]
                system.code_prefix = sd.get("code_prefix")
                system.calc_strategy = sd.get("calc_strategy", "generic")

            for idx, (code, name, role, kg) in enumerate(sd["profiles"]):
                prof = (
                    db.query(VendorProfile)
                    .filter(VendorProfile.system_id == system.id, VendorProfile.code == code)
                    .first()
                )
                if not prof:
                    db.add(VendorProfile(
                        system_id=system.id, code=code, name=name,
                        role=role, kg_per_m=kg, sort_order=idx,
                    ))
                    added_profiles += 1
                elif force:
                    prof.name = name
                    prof.role = role
                    prof.kg_per_m = kg
                    prof.sort_order = idx
                    updated_profiles += 1

    db.commit()
    return {
        "added_vendors": added_vendors,
        "added_systems": added_systems,
        "added_profiles": added_profiles,
        "updated_profiles": updated_profiles,
    }
