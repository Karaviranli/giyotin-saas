"""
Giyotin hesap STRATEGY'leri.

Her tedarikçi sisteminin kendi profil listesi + kesim formülü vardır.
Strateji = tedarikçi-spesifik imalat reçetesi.

Her strategy fonksiyonu:
    Input:  width, height, quantity, role_to_profile
    Output: profiller listesi [{ "isim", "kod", "olcu", "adet", "role", "kg_per_m" }]
            + cam_olculeri (en, boy, adet)
            + eksik_roller (verilen vendor'da olmayan roller)
"""
from typing import Callable


# ─────────────────────────────────────────────────────────────────────────
# KATAR — kataloğa ve mevcut sisteme göre çıkartılmış formüller
# ─────────────────────────────────────────────────────────────────────────
def strategy_katar(width: float, height: float, quantity: int, role_to_profile: dict):
    """Katar Alüminyum 3'lü Temizlenir Giyotin Sistemi."""
    cam_en   = width - 149
    cam_boy  = (height - 263) / 3
    cam_adet = quantity * 3
    cam_olculeri = {"en": round(cam_en, 1), "boy": round(cam_boy, 1),
                    "adet": cam_adet, "m2": round(max(0, cam_en * cam_boy * cam_adet) / 1_000_000, 3)}

    recipe = [
        # (role,                     isim,                      olcu_mm,                adet_carpan)
        ("MOTOR_KUTUSU_ALT",         "Motor Kutusu Alt",        width - 30,             2),
        ("MOTOR_KUTUSU_UST",         "Motor Kutusu Üst",        width - 30,             2),
        ("ALT_KASA",                 "Alt Kasa",                width - 45,             1),
        ("YAN_DIKME_ANA",            "Yan Ana Dikme",           height - 175,           2),
        ("YAN_DIKME_ARA",            "Yan Ara Dikme",           height - 175,           2),
        ("YAN_KUTU_BAZA",            "Yan Kutu Baza",           (cam_boy * 2) + 20,     2),
        ("YAN_DIKEY_KAPAK",          "Yan Dikey Kapak",         cam_boy + 28,           2),
        ("VASISTAS_UST_BAZA",        "Vasistas Üst Baza",       width - 177,            1),
        ("FONKSIYONEL_BAZA",         "Fonksiyonel Baza",        width - 177,            6),
        ("ISPANYOLET_BAZA",          "İspanyolet Baza",         cam_boy + 29,           2),
        ("KENET_CEKME",              "Kenet Çekme Profil",      width - 177,            3),
        ("HAREKETLI_UST_KUPESTE",    "Hareketli Üst Küpeşte",   width - 177,            1),
    ]
    return _materialize(recipe, quantity, role_to_profile,
                        width, height,
                        motor_borusu_olcu=width - 75,
                        cam_olculeri=cam_olculeri)


# ─────────────────────────────────────────────────────────────────────────
# SARAY GYT-80 — kataloğun resmi imalat listesi (sayfa 4)
# ─────────────────────────────────────────────────────────────────────────
def strategy_saray_gyt80(width: float, height: float, quantity: int, role_to_profile: dict):
    """Saray Mimari Sistemler GYT-80 3 Kanatlı Zincirli Giyotin Sistem.
    Kaynak: GYT-80 kataloğu sayfa 4 — Profil İmalat Listesi.
    """
    cam_en   = width - 178   # Yan kasa 89mm × 2
    cam_boy  = (height - 295) / 3
    cam_adet = quantity * 3
    cam_olculeri = {"en": round(cam_en, 1), "boy": round(cam_boy, 1),
                    "adet": cam_adet, "m2": round(max(0, cam_en * cam_boy * cam_adet) / 1_000_000, 3)}

    # Resmi GYT-80 kataloğu sayfa 4 — "3 KANATLI ZİNCİRLİ GİYOTİN SİSTEM Profil İmalat Listesi"
    # Tüm formüller (kesim ölçüsü + miktar) bire bir katalog tablosundan alınmıştır.
    recipe = [
        ("KASA_KAPAK",          "Kasa Kapak Profili (14506)",      width - 12,         1),  # L-12, 1 AD
        ("KASA_KAPAK_ALT",      "Kasa Kapak Profili (14507)",      width - 12,         1),  # L-12, 1 AD
        ("ALT_KASA",            "Yatay Alt Kasa Profili (14508)",  width,              1),  # L (tam), 1 AD
        ("YAN_KASA",            "Yan Kasa Profili (14509)",        height - 145,       2),  # H-145, 2 AD
        ("HAREKETLI_RAY",       "Hareketli Ray Profili (14515)",   height - 145,       4),  # H-145, 4 AD ⚠ ölçü H eksenli
        ("HAREKETLI_PERVAZ",    "Hareketli Pervaz Profili (14510)", width - 188,       1),  # L-188, 1 AD
        ("PERVAZ",              "Pervaz Profili (14511)",          width - 178,        1),  # L-178, 1 AD
        ("YAN_KASA_KAPAMA",     "Yan Kasa Kapama Profili (14516)", height - 145,       2),  # H-145, 2 AD
        ("KAPAK",               "Çıta Profili (14517)",            height - 145,       2),  # H-145, 2 AD ⚠ ölçü H eksenli
        ("KENET_CEKME",         "Kenet Profili (14512)",           width - 188,        4),  # L-188, 4 AD
        ("YAN_KANAT",           "Yan Kanat Profili (14513)",       (height / 3) - 29,  6),  # (H/3)-29, 6 AD
        ("SABIT_KANAT",         "Sabit Kanat Profili (14514)",     width - 188,        1),  # L-188, 1 AD
    ]
    return _materialize(recipe, quantity, role_to_profile,
                        width, height,
                        motor_borusu_olcu=width - 80,
                        cam_olculeri=cam_olculeri)


# ─────────────────────────────────────────────────────────────────────────
# ZAHİT — KLASİK GİYOTİN (Standart 3'lü)
# Katalogdaki profil çizimlerinden ve sektörel standartlardan türettim.
# ─────────────────────────────────────────────────────────────────────────
def strategy_zahit_klasik(width: float, height: float, quantity: int, role_to_profile: dict):
    """Zahit Alüminyum Klasik Giyotin Sistemi (V.GY.1XX).
    V.GY.101 Ana Dikme: 118.7×85mm, V.GY.102 Orta Dikme: 57.5×69.8mm
    """
    cam_en   = width - 250   # V.GY.101 ana dikme 118.7 × 2 + cam payları
    cam_boy  = (height - 280) / 3
    cam_adet = quantity * 3
    cam_olculeri = {"en": round(cam_en, 1), "boy": round(cam_boy, 1),
                    "adet": cam_adet, "m2": round(max(0, cam_en * cam_boy * cam_adet) / 1_000_000, 3)}

    recipe = [
        # Yatay yapı
        ("ALT_KASA",         "Alt Kasa (V.GY.106)",         width - 240,    1),
        ("ALT_BAZA",         "Alt Baza (V.GY.107)",         width - 60,     1),
        ("SABIT_KUPESTE",    "Sabit Küpeşte (V.GY.108)",    width - 240,    1),
        # Dikey yapı (eski seed'de eksikti — kataloğa göre eklendi)
        ("YAN_DIKME_ANA",    "Ana Dikme (V.GY.101)",        height - 100,   2),
        ("YAN_DIKME_ARA",    "Bitiş Dikme (V.GY.100)",      height - 100,   2),
        ("ORTA_DIKME",       "Orta Dikme (V.GY.102)",       height - 100,   2),
        # Yan kapama + hareketli paneller
        ("YAN_KAPAMA",       "Yan Kapama (V.GY.110)",       height - 175,   2),
        ("KUPESTE_BAZA",     "Küpeşte Baza (V.GY.207)",     cam_boy + 30,   2),
        ("HAREKETLI_KUPESTE", "Hareketli Küpeşte (V.GY.208)", width - 240,  3),
        # Kenet
        ("KENET_CEKME",      "Kenet (V.ES.109)",            width - 240,    3),
        ("KENET_DESTEK",     "Kenet Destek (V.ES.112)",     width - 240,    3),
        # CAM ÇITALAR — her cam için 4 köşe (2 yan + 2 alt)
        ("CAM_CITA",         "Cam Çıta Yan (V.ES.103)",     cam_boy - 5,    6),  # 2 per cam × 3 cam
        ("CAM_CITA_ALT",     "Cam Çıta Alt (V.ES.104)",     cam_en - 5,     6),  # 2 per cam × 3 cam
    ]
    return _materialize(recipe, quantity, role_to_profile,
                        width, height,
                        motor_borusu_olcu=width - 80,
                        cam_olculeri=cam_olculeri)


# ─────────────────────────────────────────────────────────────────────────
# ZAHİT — SİLİNEBİLİR GİYOTİN
# Tutamaklı baza ile alt panel silinebilir, vasistas kasa ile üst açılabilir.
# ─────────────────────────────────────────────────────────────────────────
def strategy_zahit_silinebilir(width: float, height: float, quantity: int, role_to_profile: dict):
    """Zahit Alüminyum Silinebilir Giyotin (V.GY.2XX serisi).
    Klasik ile aynı dikme sistemini kullanır, alt tarafta tutamaklı baza ekler.
    """
    cam_en   = width - 250
    cam_boy  = (height - 290) / 3
    cam_adet = quantity * 3
    cam_olculeri = {"en": round(cam_en, 1), "boy": round(cam_boy, 1),
                    "adet": cam_adet, "m2": round(max(0, cam_en * cam_boy * cam_adet) / 1_000_000, 3)}

    recipe = [
        # Yatay yapı
        ("ALT_KASA",         "Alt Kasa (V.GY.205)",        width - 240,    1),
        ("TUTAMAKLI_BAZA",   "Tutamaklı Baza (V.GY.206)",  width - 240,    1),
        # Dikey yapı (Zahit dikme profilleri klasik ile aynı)
        ("YAN_DIKME_ANA",    "Ana Dikme (V.GY.101)",       height - 100,   2),
        ("YAN_DIKME_ARA",    "Bitiş Dikme (V.GY.100)",     height - 100,   2),
        ("ORTA_DIKME",       "Orta Dikme (V.GY.102)",      height - 100,   2),
        # Vasistas + küpeşte + hareketli
        ("VASISTAS_KASA",    "Vasistas Kasa (V.GY.204)",   cam_boy + 30,   2),
        ("KUPESTE_BAZA",     "Küpeşte Baza (V.GY.207)",    cam_boy + 30,   2),
        ("HAREKETLI_KUPESTE", "Hareketli Küpeşte (V.GY.208)", width - 240, 3),
        ("ORTA_ALT_BAZA",    "Orta Alt Baza (V.GY.209)",   width - 240,    2),
        # Kenet
        ("KENET_CEKME",      "Kenet (V.ES.109)",           width - 240,    3),
        ("KENET_DESTEK",     "Kenet Destek (V.ES.112)",    width - 240,    3),
        ("YAN_KAPAMA",       "Yan Kapama (V.GY.110)",      height - 175,   2),
        # CAM ÇITALAR
        ("CAM_CITA",         "Cam Çıta Yan (V.ES.103)",    cam_boy - 5,    6),
        ("CAM_CITA_ALT",     "Cam Çıta Alt (V.ES.104)",    cam_en - 5,     6),
    ]
    return _materialize(recipe, quantity, role_to_profile,
                        width, height,
                        motor_borusu_olcu=width - 80,
                        cam_olculeri=cam_olculeri)


# ─────────────────────────────────────────────────────────────────────────
# ASISTAL G130T — Isıcamlı Giyotin Sürme Cam Balkon Sistemi
# Kaynak: g130t-2024 resmi katalog (Profil Listesi sayfa 2 + Aksesuar Listesi sayfa 3-4)
# Profiller: G130T 01 (üst kasa 2.152), 02 (yan kasa 2.054), 03 (alt kasa 1.713),
#   04 (kasa adaptör 0.710), 05 (ispanyolet 0.659), 06 (kapak 0.528), 07 (kapak 0.163),
#   08 (cam çıta 0.277), 09 (kanat 0.716), 10 (alt kanat 0.813), 11 (kanat 0.941),
#   12 (takviyeli kanat 1.275), 13 (kanat 1.076).
# Sistem 3 kanatlı standart, zincirli/motorlu (G100-A1 120'lik motor).
# ─────────────────────────────────────────────────────────────────────────
def strategy_asistal_g130t(width: float, height: float, quantity: int, role_to_profile: dict):
    """Asistal G130T Isıcamlı Giyotin Sürme Cam Balkon Sistemi (3 kanatlı)."""
    cam_en   = width - 170     # Yan kasa G130T 02 ≈ 85mm × 2
    cam_boy  = (height - 290) / 3
    cam_adet = quantity * 3
    cam_olculeri = {"en": round(cam_en, 1), "boy": round(cam_boy, 1),
                    "adet": cam_adet, "m2": round(max(0, cam_en * cam_boy * cam_adet) / 1_000_000, 3)}

    # Asistal G130T detay çizimleri (sayfa 13-14) — sistem 3 hareketli cam + 1 sabit alt panel.
    # Hareketli kanatlar G130T 11 (FW≤3200mm) veya G130T 12 (FW>3200mm takviyeli).
    # Yan dikme = G130T 13 (her cam panelinin 2 yan tarafı).
    use_takviye = width > 3200  # FW>3200mm büyük pencereler için takviyeli kanat profili
    recipe = [
        # Yatay kasa yapısı — üst motor kutusu (G130T 01) + alt kasa (G130T 03)
        ("MOTOR_KUTUSU_UST",      "Üst Kasa Profili (G130T 01)",      width - 30,        1),
        ("ALT_KASA",              "Alt Kasa Profili (G130T 03)",      width - 30,        1),
        # Yan kasa (G130T 02) — sol+sağ, her biri height-30
        ("YAN_KASA",              "Yan Kasa Profili (G130T 02)",      height - 30,       2),
        # Kasa adaptör (G130T 04) — yan kasanın iç tarafına bağlanır, sol+sağ
        ("KASA_ADAPTOR",          "Kasa Adaptör Profili (G130T 04)",  height - 30,       2),
        # Yan dikme (G130T 13) — her cam panelinin 2 yan tarafı, 3 cam × 2 yan = 6
        ("KANAT_ANA",             "Kanat Yan Dikme (G130T 13)",       cam_boy + 25,      6),
        # Yatay kanat profili (G130T 11 standart, G130T 12 takviyeli) — her cam üst+alt = 6
        ("KANAT_DESTEK" if not use_takviye else "KANAT_TAKVIYE",
         f"Kanat Profili (G130T {'12 takviyeli' if use_takviye else '11'})",
                                                                       cam_en - 5,        6),
        # G130T 10 — üst motor kutusu altı + alt sabit panel üstü = 2 adet width-30
        ("ALT_KANAT",             "Sabit Kanat Profili (G130T 10)",   width - 30,        2),
        # G130T 09 — alt sabit panelin baz profili (1 adet width-30)
        ("KANAT_ALT",             "Alt Sabit Profili (G130T 09)",     width - 30,        1),
        # G130T 06/07 — motor kutusu iç kapakları (1 adet width-30 her biri)
        ("KAPAK_UST",             "Motor Kutusu Kapak (G130T 06)",    width - 30,        1),
        ("KAPAK_ALT",             "Motor Kutusu Kapak (G130T 07)",    width - 30,        1),
        # İspanyolet kilitleme (G130T 05) — alt cam panelin yan tarafları (vasistas için)
        ("ISPANYOLET",            "İspanyolet Kilitleme (G130T 05)",  cam_boy + 25,      2),
        # Cam çıta (G130T 08) — her cam panelin 4 köşesi (2 yan + 2 alt-üst), 3 cam toplam
        ("CAM_CITA",              "Tek Cam Çıta Yan (G130T 08)",      cam_boy - 5,       6),
        ("CAM_CITA_ALT",          "Tek Cam Çıta Üst/Alt (G130T 08)",  cam_en - 5,        6),
    ]
    return _materialize(recipe, quantity, role_to_profile,
                        width, height,
                        motor_borusu_olcu=width - 75,
                        cam_olculeri=cam_olculeri)


# ─────────────────────────────────────────────────────────────────────────
# TEMA ALÜMİNYUM — Isı Camlı Giyotin Sistemleri (T.24xx serisi)
# Kaynak: Tema Alüminyum Isı Camlı Giyotin Sistemleri kataloğu (Profiller + Aksesuarlar + Detaylar)
# Profiller: T.2401 (üst kutu 3.182, en büyük), T.2402 (yan 0.915), T.2450 (alt kasa 1.132),
#   T.2451/2466 (alt çita), T.2452/2454/2455/2457 (cam çita), T.2467/2468 (kanat),
#   T.2490/2491/2492 (orta kanat), T.2493 (1. kanat üst/alt kapak),
#   T.2495 (sabitleme 1.777), T.2494/2496/2498 (alt profil), T.2499 (yardımcı).
# Sistem zincirli/kayışlı çift vasistaslı; motor 120-140Nm.
# ─────────────────────────────────────────────────────────────────────────
def strategy_tema_isicam(width: float, height: float, quantity: int, role_to_profile: dict):
    """Tema Alüminyum Isı Camlı Giyotin Sistemi (3 kanatlı çift vasistaslı)."""
    cam_en   = width - 175    # Yan profil T.2402 ≈ 33×2 + cam payı
    cam_boy  = (height - 295) / 3
    cam_adet = quantity * 3
    cam_olculeri = {"en": round(cam_en, 1), "boy": round(cam_boy, 1),
                    "adet": cam_adet, "m2": round(max(0, cam_en * cam_boy * cam_adet) / 1_000_000, 3)}

    # Tema kataloğunun "Detaylar" sayfasında çift vasistaslı sistem 3 cam panelli:
    # 1. kanat (alt, vasistas): T.2493 üst+alt kapak (2 ad), T.2491+T.2490 yan
    # 2. kanat (orta, vasistas): T.2455 kenet, T.2491+T.2490 yan, T.2495 sabitleme
    # 3. kanat (üst, sabit ısıcam): T.2491+T.2490 yan, T.2495 sabitleme
    # Her kanatın yan profillerinde sadece T.2491 + T.2490 ÇİFTİ var (1 + 1, toplam 6 per system)
    recipe = [
        # Üst kutu (motor + tambur muhafazası)
        ("UST_KUTU",             "Üst Kutu Şase (T.2401)",            width - 30,       1),
        ("UST_KUTU_KAPAK",       "Üst Kutu Kapağı (T.2402)",          width - 30,       1),
        # Alt kasa
        ("ALT_KASA",             "Alt Kasa (T.2450)",                 width - 30,       1),
        ("ALT_KASA_KAPAK",       "Alt Kasa Kapağı (T.2466)",          width - 30,       1),
        # Yan profiller (sabit kasa yan dikme)
        ("YAN_KASA",             "Yan Profil (T.2499)",               height - 145,     2),
        ("YAN_DIKME_ARA",        "Yan Ara Profil (T.2451)",           height - 145,     2),
        ("YAN_DIKEY_KAPAK",      "Yan Kapatma Profili (T.2452)",      height - 145,     2),
        # Kanat yan profilleri — her cam panelinin 1 set (T.2490 + T.2491), toplamda 3 cam × 2 yan = 6
        ("KANAT_YAN_1",          "Kanat Yan Profili (T.2491, dış)",   cam_boy + 25,     6),  # her cam, sağ+sol = 6
        ("KANAT_YAN_2",          "Kanat Yan Profili (T.2490, iç)",    cam_boy + 25,     6),  # her cam, sağ+sol = 6 (eşli kullanım)
        # 1. kanat (alt/vasistas) sadece T.2493 üst+alt kapağa sahip
        ("KANAT_ALT_UST_1",      "1. Kanat Alt/Üst Kapak (T.2493)",   cam_en - 5,       2),  # üst + alt = 2
        # 2. ve 1. kanat sabitleme aparatı
        ("KANAT_SABITLEME",      "Kanat Sabitleme Aparatı (T.2495)",  cam_en - 5,       2),  # 1+2 sabitleme
        # Vasistas profili (üst+orta cam arası, 1. kanat için)
        ("VASISTAS_PROFIL",      "Vasistas Profili (T.2468)",         width - 175,      1),
        # Cam çıta — her cam 2 yan + 2 alt/üst, 3 cam toplam (6 yan, 6 alt-üst değil!)
        ("CAM_CITA",             "Cam Çıta Yan (T.2454)",             cam_boy - 5,      6),  # her cam 2 yan × 3 cam
        ("CAM_CITA_ALT",         "Cam Çıta Üst/Alt (T.2457)",         cam_en - 5,       6),  # her cam 2 alt-üst × 3 cam
        # Kenet (3 cam arası → 2 kenet, ama sistemde 1. ve 2. kanat arasında + 2. ve 3. arasında = 2)
        ("KENET_CEKME",          "Kenet Çekme (T.2455)",              width - 175,      2),
        # Alt yardımcı profilleri (alt kasa içi)
        ("ALT_CITA",             "Alt Profil (T.2496)",               width - 175,      1),
        ("UST_CITA",             "Üst Profil (T.2498)",               width - 175,      1),
        ("YARDIMCI_PROFIL",      "Yardımcı Profil (T.2494)",          width - 175,      1),
        # Yan bağlantı (alt kasa-yan kasa birleşimi)
        ("YAN_BAGLANTI",         "Yan Bağlantı Profili (T.2467)",     height - 145,     2),
    ]
    return _materialize(recipe, quantity, role_to_profile,
                        width, height,
                        motor_borusu_olcu=width - 80,
                        cam_olculeri=cam_olculeri)


# ─────────────────────────────────────────────────────────────────────────
# MAVERA (MVR) — Giyotin Cam Sistemi Ürün Kataloğu 2025
# Kaynak: Mavera Mimarlık katalog (Profiller sayfa 4-5)
# Profiller: TG-103 (yan kasa alt 1.169), TG-104 (yan kasa üst 2.190),
#   KIF-0001 (ana şase 2.295), KIF-0002 (şase kapak 2.166),
#   TG-108 (yan kasa kapak 0.108), TG-109 (küpeşte bağlantı 0.282),
#   TG-102 (küpeşte 0.580),
#   TGI-105/106/107: ısı cam (baza 0.629, kenet 0.913, açılır baza 0.886)
#   TCT-105/106/107: tek cam (aynı kg/m, farklı kod)
# Sistem 2/3/4 panel desteği — varsayılan 3 panel (en yaygın).
# Motor borusu sekizgen demir (galvaniz).
# ─────────────────────────────────────────────────────────────────────────
def strategy_mavera(width: float, height: float, quantity: int, role_to_profile: dict):
    """Mavera (MVR) Giyotin Cam Sistemi — ısıcam standart 3 kanatlı."""
    cam_en   = width - 200    # KIF-0001 ana şase + yan kasa daha geniş
    cam_boy  = (height - 280) / 3
    cam_adet = quantity * 3
    cam_olculeri = {"en": round(cam_en, 1), "boy": round(cam_boy, 1),
                    "adet": cam_adet, "m2": round(max(0, cam_en * cam_boy * cam_adet) / 1_000_000, 3)}

    recipe = [
        # Ana şase (motor kutusu)
        ("ANA_SASE",             "Ana Şase (KIF-0001)",               width - 30,       1),
        ("SASE_KAPAK",           "Şase Kapak (KIF-0002)",             width - 30,       1),
        # Yan kasa
        ("YAN_KASA_UST",         "Yan Kasa Üst (TG-104)",             height - 145,     2),
        ("YAN_KASA_ALT",         "Yan Kasa Alt (TG-103)",             height - 145,     2),
        ("YAN_KASA_KAPAK",       "Yan Kasa Kapak (TG-108)",           height - 145,     2),
        # Küpeşte (kanat üst destek)
        ("KUPESTE",              "Küpeşte (TG-102)",                  width - 200,      3),  # her cam üst
        ("KUPESTE_BAGLANTI",     "Küpeşte Bağlantı Profili (TG-109)", width - 200,      3),
        # Cam paneller — ısı cam serisi
        ("ACILIR_BAZA",          "Açılır Cam Baza (TGI-107)",         width - 200,      1),  # en alt panel açılır
        ("BAZA_ISI",             "Baza Isı Cam (TGI-105)",            width - 200,      2),  # üst + orta panel baza
        ("KENET_CEKME",          "Kenet (TGI-106)",                   width - 200,      2),
    ]
    return _materialize(recipe, quantity, role_to_profile,
                        width, height,
                        motor_borusu_olcu=width - 80,
                        cam_olculeri=cam_olculeri)


# ─────────────────────────────────────────────────────────────────────────
# TÜMEN ALÜMİNYUM — GI-ART Giyotin Cam Sistemi (Klasik / Temizlenebilir)
# Kaynak: Tümen Alüminyum Ürün Kataloğu — GI-ART serisi (G-29XX profiller).
# Profiller: G-2924 motor şase (2.946 kg/m, en ağır), G-2918 şase kapak (0.881),
#   G-2919 küpeşte kapak (0.534), G-2912 alt kasa (1.450), G-2917 tutamaklı çekme (1.266),
#   G-2914 çekme profili (0.943), G-2915 yan baza (0.566), G-2921 yatay baza (0.767),
#   G-2922 yan kasa (2.1, büyük), G-2920 L kanal (0.686), G-2913 kasa dış kapak (0.686),
#   G-2916 kilit baza (1.306), G-2927 8mm tek cam çıta (0.274), G-2923 alın kapak (0.328),
#   G-2926 motor borusu (1.209).
# Sistem 3 kanatlı standart, kayışlı veya zincirli motorlu hareket.
# ─────────────────────────────────────────────────────────────────────────
def strategy_tumen_giart(width: float, height: float, quantity: int, role_to_profile: dict):
    """Tümen Alüminyum GI-ART Giyotin Cam Sistemi (3 kanatlı, kayışlı/zincirli)."""
    cam_en   = width - 240    # G-2922 yan kasa 119.5×2 + cam payı
    cam_boy  = (height - 300) / 3
    cam_adet = quantity * 3
    cam_olculeri = {"en": round(cam_en, 1), "boy": round(cam_boy, 1),
                    "adet": cam_adet, "m2": round(max(0, cam_en * cam_boy * cam_adet) / 1_000_000, 3)}

    recipe = [
        # Motor şase + üst kapak
        ("MOTOR_SASE",            "Motor Şase (G-2924)",             width - 30,        1),
        ("SASE_KAPAK",            "Şase Kapak (G-2918)",             width - 30,        1),
        # Alt kasa + L kanal
        ("ALT_KASA",              "Alt Kasa (G-2912)",               width - 30,        1),
        ("L_KANAL",               "L Kanal (G-2920)",                width - 30,        2),
        ("YATAY_BAZA",            "Yatay Baza (G-2921)",             width - 240,       3),  # her cam alt yatay
        # Yan kasa (G-2922) — büyük yan profili, 2 adet
        ("YAN_KASA",              "Yan Kasa (G-2922)",               height - 150,      2),
        # Dış kapak (G-2913) — yan kasa dış kapağı
        ("KASA_DIS_KAPAK",        "Kasa Dış Kapak (G-2913)",         height - 150,      2),
        # Yan baza (G-2915) — her cam paneli yan tarafı
        ("YAN_BAZA",              "Yan Baza (G-2915)",               cam_boy + 25,      6),
        # Tutamaklı çekme (G-2917) — silinebilir versiyonda alt panel için, klasik versiyonda alt baza
        ("TUTAMAKLI_CEKME",       "Tutamaklı Çekme (G-2917)",        width - 240,       1),
        # Çekme profili (G-2914) — her cam paneli alt çekme
        ("CEKME_PROFIL",          "Çekme Profili (G-2914)",          width - 240,       2),
        # Kilit baza (G-2916) — sabitleme
        ("KILIT_BAZA",            "Kilit Baza (G-2916)",             width - 240,       1),
        # Küpeşte kapak (G-2919) — üst cam paneli üst tarafı
        ("KUPESTE_KAPAK",         "Küpeşte Kapak (G-2919)",          width - 240,       1),
        # Alın kapak (G-2923) — yan birleşim alınları
        ("ALIN_KAPAK",            "Alın Kapak (G-2923)",             cam_boy + 10,      2),
        # Tek cam çıta (G-2927) — her cam panelin 4 köşesi
        ("CAM_CITA",              "8mm Tek Cam Çıta Yan (G-2927)",   cam_boy - 5,       6),
        ("CAM_CITA_ALT",          "8mm Tek Cam Çıta Üst/Alt (G-2927)", cam_en - 5,      6),
    ]
    return _materialize(recipe, quantity, role_to_profile,
                        width, height,
                        motor_borusu_olcu=width - 90,  # G-2926 motor borusu (Ø57.9)
                        cam_olculeri=cam_olculeri)


# ─────────────────────────────────────────────────────────────────────────
# GENERIC — geometry parametreleri olan vendor'lar için fallback
# ─────────────────────────────────────────────────────────────────────────
def strategy_generic(width: float, height: float, quantity: int, role_to_profile: dict,
                     geometry: dict = None):
    """Kataloğu olmayan vendor'lar için geometry-aware fallback strateji."""
    g = {
        "cam_adet": 3, "cam_en_eksiltme_mm": 149, "cam_boy_eksiltme_mm": 263,
        "yatay_profil_yan_pay_mm": 30, "alt_kasa_yan_pay_mm": 45,
        "yan_dikme_dusus_mm": 175, "ic_dikey_dusus_mm": 177,
        "ic_kupeste_boy_ek_mm": 28, "ispanyolet_boy_ek_mm": 29,
        "yan_kutu_baza_ek_mm": 20, "motor_borusu_yan_pay_mm": 75,
        **(geometry or {})
    }
    cam_en = width - g["cam_en_eksiltme_mm"]
    cam_boy = (height - g["cam_boy_eksiltme_mm"]) / g["cam_adet"]
    cam_adet = quantity * g["cam_adet"]
    cam_olculeri = {"en": round(cam_en, 1), "boy": round(cam_boy, 1),
                    "adet": cam_adet, "m2": round(max(0, cam_en * cam_boy * cam_adet) / 1_000_000, 3)}

    recipe = [
        ("MOTOR_KUTUSU_ALT",      "Motor Kutusu Alt",       width - g["yatay_profil_yan_pay_mm"],   1),
        ("MOTOR_KUTUSU_UST",      "Motor Kutusu Üst",       width - g["yatay_profil_yan_pay_mm"],   1),
        ("ALT_KASA",              "Alt Kasa",               width - g["alt_kasa_yan_pay_mm"],       1),
        ("YAN_DIKME_ANA",         "Yan Ana Dikme",          height - g["yan_dikme_dusus_mm"],       2),
        ("YAN_DIKME_ARA",         "Yan Ara Dikme",          height - g["yan_dikme_dusus_mm"],       2),
        ("YAN_KUTU_BAZA",         "Yan Kutu Baza",          (cam_boy * 2) + g["yan_kutu_baza_ek_mm"], 2),
        ("YAN_DIKEY_KAPAK",       "Yan Dikey Kapak",        cam_boy + g["ic_kupeste_boy_ek_mm"],    2),
        ("VASISTAS_UST_BAZA",     "Vasistas Üst Baza",      width - g["ic_dikey_dusus_mm"],         1),
        ("FONKSIYONEL_BAZA",      "Fonksiyonel Baza",       width - g["ic_dikey_dusus_mm"],         6),
        ("ISPANYOLET_BAZA",       "İspanyolet Baza",        cam_boy + g["ispanyolet_boy_ek_mm"],    2),
        ("KENET_CEKME",           "Kenet Çekme Profil",     width - g["ic_dikey_dusus_mm"],         3),
        ("HAREKETLI_UST_KUPESTE", "Hareketli Üst Küpeşte",  width - g["ic_dikey_dusus_mm"],         1),
    ]
    return _materialize(recipe, quantity, role_to_profile,
                        width, height,
                        motor_borusu_olcu=width - g["motor_borusu_yan_pay_mm"],
                        cam_olculeri=cam_olculeri)


# ─────────────────────────────────────────────────────────────────────────
# AKSESUARLAR — her vendor için ayrı reçete
# Her aksesuar: (key, isim, adet_veya_metre, "adet"/"metre", price_field)
# price_field CompanySettings sütun adıdır
# ─────────────────────────────────────────────────────────────────────────
def accessories_katar(width, height, quantity, cam_olculeri):
    """Katar Klasik Giyotin için aksesuar listesi."""
    cam_cevre_m = (2 * cam_olculeri["en"] + 2 * cam_olculeri["boy"]) / 1000  # mm → m, 1 cam çevresi
    cam_adet = cam_olculeri["adet"]
    return [
        # (kod_etiketi, isim, miktar, birim, fiyat_alani)
        ("kose_takozu",       "Kasa Köşe Takozu",          quantity * 4,   "adet", "kose_takozu_tl"),
        ("rulman_yatagi",     "Rulman Yatağı",              quantity * 2,   "adet", "rulman_yatagi_tl"),
        ("boru_basi",         "Boru Başı Kapağı",           quantity * 2,   "adet", "boru_basi_tl"),
        ("merkezleme_takozu", "Merkezleme Takozu",          quantity * 8,   "adet", "merkezleme_takozu_tl"),
        ("vasistas_takoz",    "Vasistas Alt Takoz",         quantity * 2,   "adet", "vasistas_takoz_tl"),
        ("baza_kapak",        "Kenetli Baza Kapak",         quantity * 4,   "adet", "baza_kapak_tl"),
        ("cam_fitili",        "Cam Fitili (EPDM)",          cam_cevre_m * cam_adet, "metre", "cam_fitili_m_tl"),
        ("kapak_fitili",      "Kapak Fitili",               quantity * 4 * (width / 1000), "metre", "kapak_fitili_m_tl"),
        ("kenet_fitili",      "Kenet Fitili",               quantity * 6 * (height / 1000), "metre", "kenet_fitili_m_tl"),
    ]


def accessories_saray(width, height, quantity, cam_olculeri):
    """Saray GYT-80 için aksesuar listesi — kataloğun resmi 'Aksesuar İmalat Listesi' (sayfa 5).
    Kesim ölçüleri + miktarlar bire bir Saray kataloğundan alınmıştır.
    """
    cam_adet = cam_olculeri["adet"]
    return [
        ("zincir_dislisi",    "Zincir Dişlisi (SC-930)",       quantity * 2,   "adet", "zincir_dislisi_tl"),     # 2 AD, sağ ve sol başlarda
        ("sase_yan_kapak",    "14506 Şase Yan Kapakları (SC-931, takım 2 adet)", quantity * 2, "adet", "boru_basi_tl"),  # 1 TK = 2 ad
        ("tapa_mili",         "Tapa Mili (SC-932)",            quantity * 1,   "adet", "merkezleme_takozu_tl"),
        ("tambur_tapasi",     "Tambur Tapası (SC-933)",        quantity * 1,   "adet", "boru_basi_tl"),
        ("tambur",            "Tambur (SC-934, L-61mm)",       quantity * 1,   "adet", "tambur_tl"),            # 1 AD, kendi fiyat alanı
        ("kanat_kose_plastik", "Kanat Köşe Plastiği (SC-935)", quantity * 12,  "adet", "kanat_kose_plastik_tl"), # 12 AD: kendi fiyat alanı
        ("denge_takozu",      "Denge Takozu (SC-936)",         quantity * 12,  "adet", "denge_takozu_tl"),      # 12 AD: kendi fiyat alanı
        ("zincir_kilavuz",    "Zincir Kılavuz Plastiği (SC-937)", quantity * 2, "adet", "zincir_yonlendirici_tl"),
        ("sizdirmazlik_fitili", "Sızdırmazlık Fitili (SC-938, L-188mm)", quantity * 4 * ((width - 188) / 1000), "metre", "kapak_fitili_m_tl"),  # 4 AD × (L-188)
        ("kil_fitili",        "Kıl Fitil (SC-939, H-145mm)",   quantity * 12 * ((height - 145) / 1000), "metre", "firca_fitili_m_tl"),  # 12 AD × (H-145)
        ("pervaz_baski_fitili", "Pervaz Baskı Fitili (SC-940, L-178mm)", quantity * 2 * ((width - 178) / 1000), "metre", "kenet_fitili_m_tl"),  # 2 AD × (L-178)
        ("zincir",            "Zincir (SC-941)",               quantity * 2 * 2.5,   "metre", "zincir_m_tl"),  # 2 AD özel zincir (≥2.5m)
        ("cam_pimi",          "Cam Pimi (SC-942)",             quantity * 12,  "adet", "merkezleme_takozu_tl"),  # 12 AD: 3 üstte + 3 altta × her cam
        ("motor",             "Motor",                         quantity * 1,   "adet", "motor_tl"),
        ("kumanda",           "Kumanda",                       quantity * 1,   "adet", "kumanda_tl"),
    ]


def accessories_zahit_klasik(width, height, quantity, cam_olculeri):
    """Zahit Klasik Giyotin için aksesuar listesi.
    Kaynak: Zahit Klasik Giyotin kataloğu (giyotin-sistem-katalog.pdf) sayfa 28-29 aksesuar tablosu.
    Tüm adetler katalogda 'PAKET METRAJI' sütunundan bire bir alınmıştır.
    """
    cam_cevre_m = (2 * cam_olculeri["en"] + 2 * cam_olculeri["boy"]) / 1000
    cam_adet = cam_olculeri["adet"]
    return [
        # PVC/metal aksesuarlar — katalogda her bir paketteki adet
        ("kose_takozu",       "Kasa Köşe Birleştirme Takozu (GY-01)",  quantity * 2,   "adet", "kose_takozu_tl"),       # katalog: 2
        ("motor_kapak",       "Motor Tarafı Kapak (GY-02)",            quantity * 1,   "adet", "baza_kapak_tl"),         # katalog: 1
        ("boru_basi",         "Boru Başı Kapak (GY-03)",               quantity * 1,   "adet", "boru_basi_tl"),          # katalog: 1
        ("rulman_yatagi",     "Rulman Yatağı (GY-04)",                 quantity * 1,   "adet", "rulman_yatagi_tl"),      # katalog: 1
        ("boru_basi_alm",     "Boru Başı Alüminyum (GY-05)",           quantity * 1,   "adet", "boru_basi_tl"),          # katalog: 1
        ("merkezleme_takozu", "Merkezleme Takozu (GY-07)",             quantity * 8,   "adet", "merkezleme_takozu_tl"),  # katalog: 8
        ("baza_kapak",        "Kenetli Baza Kapak (GY-08, 2L+2R)",     quantity * 4,   "adet", "baza_kapak_tl"),         # katalog: 2L+2R=4
        ("duz_baza_kapak",    "Düz Baza Kapak (GY-9)",                 quantity * 2,   "adet", "baza_kapak_tl"),         # katalog: 2 (klasik özel)
        ("kupeste_kapak",     "Küpeşte Kapak (GY-10, 1L+1R)",          quantity * 2,   "adet", "baza_kapak_tl"),         # katalog: 1L+1R=2
        ("kupeste_takoz",     "Küpeşte Takoz (GY-24)",                 quantity * 2,   "adet", "merkezleme_takozu_tl"),  # katalog: 2
        # Zincirli/kayışlı mekanizma (sistemde her ikisi alternatif olduğu için her ikisinin de adetleri eklendi)
        ("zincir_dislisi",    "Zincir Dişlisi (GY-11)",                quantity * 2,   "adet", "zincir_dislisi_tl"),     # katalog: 2
        ("zincir_yonlendirici", "Zincir Yönlendirici (GY-13)",         quantity * 2,   "adet", "zincir_yonlendirici_tl"), # katalog: 2
        ("zincir",            "Zincir 2.5m (GY-14, 2 adet)",           quantity * 5.0, "metre", "zincir_m_tl"),           # katalog: 2 × 2.5m
        ("kayis_kasnagi",     "Kayış Kasnağı (GY-16)",                 quantity * 2,   "adet", "kayis_kasnagi_tl"),      # katalog: 2
        ("kayis",             "Kayış 2.5m (GY-17, 2 adet)",            quantity * 5.0, "metre", "kayis_m_tl"),            # katalog: 2 × 2.5m
        # Fitiller (paket metrajı katalogdan — kullanılan miktar profil çevresiyle hesaplanır)
        ("cam_fitili",        "EPDM Cam Fitili",                       cam_cevre_m * cam_adet, "metre", "cam_fitili_m_tl"),
        ("kapak_fitili",      "EPDM Kapak Baskı Fitili (Z-94)",        quantity * 4 * (width / 1000), "metre", "kapak_fitili_m_tl"),
        ("firca_fitili",      "Fırça Fitili (LS55520)",                quantity * 4 * (height / 1000), "metre", "firca_fitili_m_tl"),
        ("flock_fitili",      "Flock Fitili (ZF-1)",                   quantity * 2 * (height / 1000), "metre", "flock_fitili_m_tl"),
        ("kenet_fitili",      "EPDM Kenet Fitili (W55.511)",           quantity * 6 * (height / 1000), "metre", "kenet_fitili_m_tl"),
        ("kanat_baski_fitili", "EPDM Kanat Baskı Fitili (Z-63)",       quantity * 6 * (height / 1000), "metre", "kapak_fitili_m_tl"),
    ]


def accessories_zahit_silinebilir(width, height, quantity, cam_olculeri):
    """Zahit Vetrina Silinebilir Giyotin için aksesuar listesi.
    Kaynak: SILINEBILIR-GIYOTIN-SISTEM.pdf sayfa 8-10 + silinebilir-giyotin-sistem-katalog.pdf.
    Silinebilir, klasik aksesuarlarına ek olarak vasistas mekanizması içerir (GY-21..27).
    """
    cam_cevre_m = (2 * cam_olculeri["en"] + 2 * cam_olculeri["boy"]) / 1000
    cam_adet = cam_olculeri["adet"]
    return [
        # Klasik aksesuarlar (Düz Baza Kapak ve Küpeşte Kapak silinebilir'de yok — kataloğa göre)
        ("kose_takozu",       "Kasa Köşe Birleştirme Takozu (GY-01)",  quantity * 2,   "adet", "kose_takozu_tl"),
        ("motor_kapak",       "Motor Tarafı Kapak (GY-02)",            quantity * 1,   "adet", "baza_kapak_tl"),
        ("boru_basi",         "Boru Başı Kapak (GY-03)",               quantity * 1,   "adet", "boru_basi_tl"),
        ("rulman_yatagi",     "Rulman Yatağı (GY-04)",                 quantity * 1,   "adet", "rulman_yatagi_tl"),
        ("boru_basi_alm",     "Boru Başı Alüminyum (GY-05)",           quantity * 1,   "adet", "boru_basi_tl"),
        ("merkezleme_takozu", "Merkezleme Takozu (GY-07)",             quantity * 8,   "adet", "merkezleme_takozu_tl"),
        ("baza_kapak",        "Kenetli Baza Kapak (GY-08, 2L+2R)",     quantity * 4,   "adet", "baza_kapak_tl"),
        # Silinebilir / vasistas mekanizması (klasik'te yok)
        ("vasistas_takoz",        "Vasistas Alt Takoz (GY-19, 1L+1R)",       quantity * 2,   "adet", "vasistas_takoz_tl"),
        ("vasistas_kasa_takoz",   "Vasistas Alt Kasa Takoz (GY-20, 1L+1R)",  quantity * 2,   "adet", "vasistas_takoz_tl"),
        ("tutamakli_baza_kapak",  "Tutamaklı Baza Kapak (GY-21)",            quantity * 2,   "adet", "baza_kapak_tl"),
        ("vasistas_ust_kapak",    "Vasistas Üst Kapak (GY-22, 1L+1R)",       quantity * 2,   "adet", "baza_kapak_tl"),
        ("orta_vasistas_takoz",   "Orta Vasistas Alt Kasa Takoz (GY-23, 1L+1R)", quantity * 2, "adet", "vasistas_takoz_tl"),
        ("kupeste_takoz",         "Küpeşte Takoz (GY-24)",                   quantity * 2,   "adet", "merkezleme_takozu_tl"),
        ("vasistas_kol",          "Vasistas Kol (GY-25)",                    quantity * 2,   "adet", "vasistas_kol_tl"),
        ("vasistas_makas",        "Vasistas Makas (GY-26)",                  quantity * 2,   "adet", "vasistas_makas_tl"),
        ("ispanyolet_kilit",      "İspanyolet Kilit (GY-27)",                quantity * 2,   "adet", "ispanyolet_tl"),
        # Zincirli/kayışlı mekanizma alternatifleri
        ("zincir_dislisi",        "Zincir Dişlisi (GY-11)",                  quantity * 2,   "adet", "zincir_dislisi_tl"),
        ("zincir_yonlendirici",   "Zincir Yönlendirici (GY-13)",             quantity * 2,   "adet", "zincir_yonlendirici_tl"),
        ("zincir",                "Zincir 2.5m (GY-14, 2 adet)",             quantity * 5.0, "metre", "zincir_m_tl"),
        ("zincir_kayis_tutucu",   "Zincir ve Kayış Tutucu (GY-15)",          quantity * 2,   "adet", "zincir_yonlendirici_tl"),
        ("kayis_kasnagi",         "Kayış Kasnağı (GY-16)",                   quantity * 2,   "adet", "kayis_kasnagi_tl"),
        ("kayis",                 "Kayış 2.5m (GY-17, 2 adet)",              quantity * 5.0, "metre", "kayis_m_tl"),
        # Fitiller
        ("cam_fitili",        "EPDM Cam Fitili",                       cam_cevre_m * cam_adet, "metre", "cam_fitili_m_tl"),
        ("kapak_fitili",      "EPDM Kapak Baskı Fitili (Z-94)",        quantity * 4 * (width / 1000), "metre", "kapak_fitili_m_tl"),
        ("firca_fitili",      "Fırça Fitili (LS55520)",                quantity * 4 * (height / 1000), "metre", "firca_fitili_m_tl"),
        ("flock_fitili",      "Flock Fitili (ZF-1)",                   quantity * 2 * (height / 1000), "metre", "flock_fitili_m_tl"),
        ("kenet_fitili",      "EPDM Kenet Fitili (W55.511)",           quantity * 6 * (height / 1000), "metre", "kenet_fitili_m_tl"),
        ("kanat_baski_fitili", "EPDM Kanat Baskı Fitili (Z-63)",       quantity * 6 * (height / 1000), "metre", "kapak_fitili_m_tl"),
    ]


def accessories_asistal_g130t(width, height, quantity, cam_olculeri):
    """Asistal G130T için aksesuar listesi (zincirli/motorlu sistem)."""
    cam_cevre_m = (2 * cam_olculeri["en"] + 2 * cam_olculeri["boy"]) / 1000
    cam_adet = cam_olculeri["adet"]
    return [
        # PVC kapak takımı + motor sistemi
        ("kose_takozu",        "Kasa Köşe Takozu",                       quantity * 4,   "adet", "kose_takozu_tl"),
        ("kapak_takimi",       "PVC Kapak Takımı (EM-G130-TK)",          quantity * 1,   "adet", "baza_kapak_tl"),
        ("rulman_yatagi",      "Rulman Yatağı (EM125-23-1)",             quantity * 2,   "adet", "rulman_yatagi_tl"),
        ("boru_basi",          "Giyotin Tambur Başı (G100-A11-3)",       quantity * 2,   "adet", "boru_basi_tl"),
        ("motor_yan_sac",      "Motor Yan Sacı (G130T-A1)",              quantity * 2,   "adet", "boru_basi_tl"),
        ("teker_destek",       "Kanat Teker Kılavuzu+Destek (G130-STR)", quantity * 6,   "adet", "merkezleme_takozu_tl"),
        # Zincir mekanizması (motorlu hareket)
        ("zincir_kilavuz",     "Zincir Klavuz Yüzüğü (G130-A01)",        quantity * 2,   "adet", "zincir_yonlendirici_tl"),
        ("zincir_aski",        "Zincir Askı Sacı (G130-A05)",            quantity * 2,   "adet", "zincir_dislisi_tl"),
        # İspanyolet (vasistas üst açılma)
        ("ispanyolet",         "İspanyolet 400mm (ASI-MP-ES 400)",       quantity * 2,   "adet", "ispanyolet_tl"),
        ("ispanyolet_pim",     "İspanyolet Pim Karşılığı (ASI-MP-SP 01)", quantity * 2,  "adet", "ispanyolet_karsilik_tl"),
        ("ispanyolet_kol",     "İspanyolet Kol Yerli (ASI-WH 008)",      quantity * 2,   "adet", "vasistas_kol_tl"),
        ("kilit_kol",          "Çift Yönlü Kilitleme Kolu (FDA-K 01)",   quantity * 2,   "adet", "vasistas_takoz_tl"),
        ("vasistas_makas",     "Vasistas Makas Multi-Point (ASI-V 0501)", quantity * 2,  "adet", "vasistas_makas_tl"),
        # Fitiller
        ("firca_fitili",       "Fırça Fitili 6.5mm (KF 67-650)",         quantity * 4 * (height / 1000), "metre", "firca_fitili_m_tl"),
        ("firca_fitili_10",    "Fırça Fitili 10mm (KF 67-1000)",         quantity * 2 * (height / 1000), "metre", "firca_fitili_m_tl"),
        ("kenet_bini_fitili",  "Kenet Bini Fitili (MO-60)",              quantity * 6 * (height / 1000), "metre", "kenet_fitili_m_tl"),
        ("cam_fitili",         "Cam Fitili (EPDM)",                      cam_cevre_m * cam_adet, "metre", "cam_fitili_m_tl"),
    ]


def accessories_tema_isicam(width, height, quantity, cam_olculeri):
    """Tema Alüminyum Isı Camlı Giyotin için aksesuar listesi (zincirli/kayışlı çift vasistas)."""
    cam_cevre_m = (2 * cam_olculeri["en"] + 2 * cam_olculeri["boy"]) / 1000
    cam_adet = cam_olculeri["adet"]
    return [
        # Şase ve kanat aparatları
        ("ust_kutu_kapak",     "Üst Kutu (Şase) Kapağı",                 quantity * 2,   "adet", "baza_kapak_tl"),
        ("rulman_yatagi",      "Rulman Yatağı",                          quantity * 1,   "adet", "rulman_yatagi_tl"),
        ("ust_kupeste_kapak",  "Hareketli Üst Küpeşte Kapağı",           quantity * 2,   "adet", "baza_kapak_tl"),
        ("kanat_kose_kapak",   "Kanat Köşe Kapağı (12 ad)",              quantity * 12,  "adet", "kose_takozu_tl"),
        ("kose_takozu",        "Köşe Takozu (sağ-sol)",                  quantity * 2,   "adet", "kose_takozu_tl"),
        ("yarim_u_aparat",     "Yarım U ve Alın Bağlantı Aparatı",       quantity * 2,   "adet", "merkezleme_takozu_tl"),
        ("kanat_ust_kapak_1",  "T.2493 Üst Kapağı (1. Kanat)",           quantity * 2,   "adet", "baza_kapak_tl"),
        ("kanat_alt_kapak_1",  "T.2493 Alt Kapağı (1. Kanat)",           quantity * 2,   "adet", "baza_kapak_tl"),
        ("kanat_alt_kapak_2",  "T.2491 Alt Kapağı (2. Kanat)",           quantity * 2,   "adet", "baza_kapak_tl"),
        ("kanat_sabitleme_2",  "T.2495 2. Kanat Sabitleme Aparatı",      quantity * 2,   "adet", "merkezleme_takozu_tl"),
        ("kanat_sabitleme_1",  "T.2495 1. Kanat Sabitleme Aparatı",      quantity * 2,   "adet", "merkezleme_takozu_tl"),
        # Mekanizma (zincirli + kayışlı alternatif)
        ("kayis_zincir_aparat", "Kayış ve Zincir Bağlantı Aparatı",      quantity * 2,   "adet", "zincir_yonlendirici_tl"),
        ("kanat_rulman",       "Kanat Rulmanı (4 ad)",                   quantity * 4,   "adet", "rulman_yatagi_tl"),
        ("alt_sizdirmazlik",   "Alt Sızdırmazlık Aksesuarı",             quantity * 2,   "adet", "merkezleme_takozu_tl"),
        ("vasistas_makas",     "Vasistas Makası",                        quantity * 2,   "adet", "vasistas_makas_tl"),
        ("kol",                "Kol (2 ad)",                             quantity * 2,   "adet", "vasistas_takoz_tl"),
        # Motor + boru + zincir/kayış
        ("zincir",             "Zincir 5mt (TA.04.02.01.12)",            quantity * 5,   "metre", "zincir_m_tl"),
        ("triger_kayis",       "Triger Dişli Kayışı (TA.04.03.00.01)",   quantity * 5,   "metre", "kayis_m_tl"),
        ("zincir_dislisi",     "Pimli Boru Başı Zincir Dişlisi",         quantity * 2,   "adet", "zincir_dislisi_tl"),
        ("kayis_kasnagi",      "Kayış Boru Başı Kayış Tanbur",           quantity * 2,   "adet", "kayis_kasnagi_tl"),
        ("guvenlik_anahtari",  "Güvenlik Anahtarı",                      quantity * 1,   "adet", "merkezleme_takozu_tl"),
        # Fitiller ve contalar
        ("kil_fitil",          "Kıl Fitil 67x1000 (TA.26.60.67.10)",     quantity * 4 * (height / 1000), "metre", "firca_fitili_m_tl"),
        ("ust_kutu_conta",     "Üst Kutu Contası (TA.04.01.00.04)",      quantity * (width / 1000), "metre", "kenet_fitili_m_tl"),
        ("giyotin_conta",      "Giyotin Sistem Contası (TA.04.01.00.04)", quantity * 6 * (height / 1000), "metre", "kenet_fitili_m_tl"),
        ("cekme_conta",        "Çekme Profil Contası (TA.26.61.00.02)",  quantity * 4 * (width / 1000), "metre", "kapak_fitili_m_tl"),
        ("cam_fitili",         "Cam Fitili (EPDM)",                      cam_cevre_m * cam_adet, "metre", "cam_fitili_m_tl"),
        # Mastik
        ("mastik",             "Soudal Soudaflex 40FC Mastik 600ml",     quantity * 1,   "adet", "merkezleme_takozu_tl"),
    ]


def accessories_mavera(width, height, quantity, cam_olculeri):
    """Mavera (MVR) için aksesuar listesi (motorlu standart giyotin)."""
    cam_cevre_m = (2 * cam_olculeri["en"] + 2 * cam_olculeri["boy"]) / 1000
    cam_adet = cam_olculeri["adet"]
    return [
        ("kose_takozu",        "Kasa Köşe Takozu",                       quantity * 4,   "adet", "kose_takozu_tl"),
        ("rulman_yatagi",      "Rulman Yatağı",                          quantity * 2,   "adet", "rulman_yatagi_tl"),
        ("boru_basi",          "Boru Başı (sekizgen demir)",             quantity * 2,   "adet", "boru_basi_tl"),
        ("merkezleme_takozu",  "Merkezleme Takozu",                      quantity * 6,   "adet", "merkezleme_takozu_tl"),
        ("vasistas_takoz",     "Vasistas Açılır Baza Takozu",            quantity * 2,   "adet", "vasistas_takoz_tl"),
        ("baza_kapak",         "Baza Kapak (PVC)",                       quantity * 4,   "adet", "baza_kapak_tl"),
        # Fitiller
        ("cam_fitili",         "Cam Fitili (EPDM)",                      cam_cevre_m * cam_adet, "metre", "cam_fitili_m_tl"),
        ("kapak_fitili",       "Kapak Fitili",                           quantity * 4 * (width / 1000), "metre", "kapak_fitili_m_tl"),
        ("firca_fitili",       "Fırça Fitili",                           quantity * 4 * (height / 1000), "metre", "firca_fitili_m_tl"),
        ("kenet_fitili",       "Kenet Fitili",                           quantity * 3 * (height / 1000), "metre", "kenet_fitili_m_tl"),
    ]


def accessories_tumen_giart(width, height, quantity, cam_olculeri):
    """Tümen GI-ART için aksesuar listesi (kayışlı sistem temel kabul edilmiştir).
    Kaynak: Tümen kataloğu sayfa 6-7 (Temizlenebilir) ve sayfa 9-10 (Klasik) aksesuar listesi.
    """
    cam_cevre_m = (2 * cam_olculeri["en"] + 2 * cam_olculeri["boy"]) / 1000
    cam_adet = cam_olculeri["adet"]
    return [
        # GI-ART-A serisi PVC/metal aksesuarlar (sağ + sol = 2 adet)
        ("sase_kapak",        "Şase Kapak (GI-ART-A-1, sağ+sol)",     quantity * 2,   "adet", "baza_kapak_tl"),
        ("zincir_bogma",      "Zincir Boğma (GI-ART-A-2)",             quantity * 2,   "adet", "zincir_yonlendirici_tl"),
        ("alt_kasa_kose",     "Alt Kasa Köşe Takozu (GI-ART-A-3)",     quantity * 2,   "adet", "kose_takozu_tl"),
        ("kupeste_kapak_aks", "Küpeşte Kapak (GI-ART-A-4)",            quantity * 2,   "adet", "baza_kapak_tl"),
        ("cam_ust_profil_2",  "2. Cam Üst Profil (GI-ART-A-5)",        quantity * 2,   "adet", "merkezleme_takozu_tl"),
        ("cam_alt_profil_2",  "2. ve Üst Cam Alt Profil (GI-ART-A-6)", quantity * 4,   "adet", "merkezleme_takozu_tl"),
        ("ust_cam_ust",       "Üst Cam Üst Profil (GI-ART-A-7)",       quantity * 2,   "adet", "merkezleme_takozu_tl"),
        ("alt_cam_alt",       "Alt Cam Alt Profil (GI-ART-A-8)",       quantity * 2,   "adet", "merkezleme_takozu_tl"),
        ("alt_cam_ust_tut",   "Alt Cam Üst Tutamaklı (GI-ART-A-9)",    quantity * 2,   "adet", "vasistas_takoz_tl"),
        ("kanat_orta_bag",    "Kanat Orta Bağlantı (GI-ART-A-10)",     quantity * 2,   "adet", "merkezleme_takozu_tl"),
        ("push_kol",          "Push Kol (GI-ART-A-11)",                quantity * 2,   "adet", "push_kol_tl"),
        ("vasistas_makas",    "Vasistas Makas (GI-ART-A-12)",          quantity * 2,   "adet", "vasistas_makas_tl"),
        ("boru_basi_milli",   "Boru Başı Milli (GI-ART-A-13)",         quantity * 1,   "adet", "boru_basi_tl"),
        ("altigen_kasnak",    "Altıgen Kasnak (GI-ART-A-14)",          quantity * 2,   "adet", "kayis_kasnagi_tl"),
        ("ispanyolet",        "İspanyolet (GI-ART-A-15)",              quantity * 2,   "adet", "ispanyolet_tl"),
        ("ispanyolet_karsi",  "İspanyolet Karşılığı Zamak (GI-ART-A-16)", quantity * 2, "adet", "ispanyolet_karsilik_tl"),
        ("imalat_vidalari",   "İmalat Vidaları (GI-ART-A-17, paket)",  quantity * 1,   "adet", "merkezleme_takozu_tl"),
        ("motor_lazeri",      "Motor Lazeri (GI-ART-A-18)",            quantity * 1,   "adet", "motor_lazer_tl"),
        ("boru_basi_lazer",   "Boru Başı Lazer (GI-ART-A-19)",         quantity * 1,   "adet", "motor_lazer_tl"),
        ("kayis_baglama",     "Kayış Bağlama (GI-ART-A-20)",           quantity * 2,   "adet", "merkezleme_takozu_tl"),
        # Fitil + cam fitili
        ("cam_fitili",        "Cam Fitili (EPDM)",                     cam_cevre_m * cam_adet, "metre", "cam_fitili_m_tl"),
        ("firca_fitili",      "Fırça Fitili",                          quantity * 4 * (height / 1000), "metre", "firca_fitili_m_tl"),
    ]


def accessories_generic(width, height, quantity, cam_olculeri):
    """Bilinmeyen vendor için temel aksesuar setine düş."""
    cam_cevre_m = (2 * cam_olculeri["en"] + 2 * cam_olculeri["boy"]) / 1000
    cam_adet = cam_olculeri["adet"]
    return [
        ("kose_takozu",   "Kasa Köşe Takozu",   quantity * 4,   "adet", "kose_takozu_tl"),
        ("rulman_yatagi", "Rulman Yatağı",       quantity * 2,   "adet", "rulman_yatagi_tl"),
        ("boru_basi",     "Boru Başı Kapağı",    quantity * 2,   "adet", "boru_basi_tl"),
        ("cam_fitili",    "Cam Fitili (EPDM)",   cam_cevre_m * cam_adet, "metre", "cam_fitili_m_tl"),
        ("kapak_fitili",  "Kapak Fitili",        quantity * 4 * (width / 1000), "metre", "kapak_fitili_m_tl"),
    ]


# Registry — strategy adına göre aksesuar fonksiyonu
ACCESSORIES_REGISTRY = {
    "katar":             accessories_katar,
    "saray_gyt80":       accessories_saray,
    "zahit_klasik":      accessories_zahit_klasik,
    "zahit_silinebilir": accessories_zahit_silinebilir,
    "asistal_g130t":     accessories_asistal_g130t,
    "tema_isicam":       accessories_tema_isicam,
    "mavera":            accessories_mavera,
    "tumen_giart":       accessories_tumen_giart,
    "generic":           accessories_generic,
}


# ─────────────────────────────────────────────────────────────────────────
# YARDIMCI — recipe'i somut profil listesine çevir
# ─────────────────────────────────────────────────────────────────────────
def _materialize(recipe, quantity, role_to_profile,
                 width, height, motor_borusu_olcu, cam_olculeri):
    """Recipe + vendor profiller → çıktı."""
    TEMEL_ROLLER = {
        "MOTOR_KUTUSU_ALT", "KASA_KAPAK", "ALT_KASA",
        "YAN_DIKME_ANA", "YAN_KASA",
        "KENET_CEKME",
    }
    profiller = []
    eksik_roller = []
    uyarilar = []   # ölçü uyarıları (çok kısa parça vs)
    for role, isim, olcu_mm, adet_carpan in recipe:
        prof = role_to_profile.get(role)
        if not prof:
            if role in TEMEL_ROLLER:
                if role == "MOTOR_KUTUSU_ALT" and "KASA_KAPAK" in role_to_profile:
                    continue
                if role == "ALT_KASA" and "ALT_BAZA" in role_to_profile:
                    continue
                eksik_roller.append({"role": role, "isim": isim})
            continue
        adet = quantity * adet_carpan
        if adet <= 0 or olcu_mm <= 0:
            continue
        # Üretim açısından < 200mm parça mantıksız — uyarı bırak, hesabı yine yap
        if olcu_mm < 200:
            uyarilar.append({
                "kod": prof.code, "isim": isim,
                "olcu_mm": round(olcu_mm, 1),
                "mesaj": "Çok küçük parça — pencere boyutu doğru girildi mi?",
            })
        profiller.append({
            "isim": isim, "kod": prof.code, "olcu": olcu_mm,
            "adet": adet, "role": role, "kg_per_m": prof.kg_per_m or 0.0,
        })

    # ── MOTOR BORUSU — akıllı routing ──
    # Tedarikçinin MOTOR_BORUSU profili kg/m>0 ise alüminyum, bin-packing'e girer.
    # kg/m=0 ise galvaniz çelik/demir boru → ayrı aksesuar olarak metre fiyatlı işlenir.
    motor_bor_prof = role_to_profile.get("MOTOR_BORUSU")
    motor_borusu_metre = 0.0
    motor_borusu_kod = "G.AKS1001"
    if motor_bor_prof:
        motor_borusu_kod = motor_bor_prof.code
        if (motor_bor_prof.kg_per_m or 0) > 0:
            # Alüminyum motor borusu → profil listesine ekle (kg fiyatlı, bin-packing)
            profiller.append({
                "isim": f"Motor Borusu ({motor_bor_prof.name})",
                "kod": motor_bor_prof.code,
                "olcu": motor_borusu_olcu,
                "adet": quantity * 1,
                "role": "MOTOR_BORUSU",
                "kg_per_m": motor_bor_prof.kg_per_m,
            })
        else:
            # Galvaniz/çelik motor borusu → aksesuar olarak metre fiyatlı (boru_m_tl)
            motor_borusu_metre = (motor_borusu_olcu / 1000.0) * quantity
    else:
        # Tedarikçi profili yoksa varsayılan galvaniz olarak aksesuara koy
        motor_borusu_metre = (motor_borusu_olcu / 1000.0) * quantity

    return {
        "profiller": profiller,
        "cam_olculeri": cam_olculeri,
        "eksik_roller": eksik_roller,
        "uyarilar": uyarilar,
        "motor_borusu_metre": round(motor_borusu_metre, 3),
        "motor_borusu_kod": motor_borusu_kod,
    }


# ─────────────────────────────────────────────────────────────────────────
# REGISTRY — strategy adı → fonksiyon
# ─────────────────────────────────────────────────────────────────────────
STRATEGIES: dict[str, Callable] = {
    "katar":              strategy_katar,
    "saray_gyt80":        strategy_saray_gyt80,
    "zahit_klasik":       strategy_zahit_klasik,
    "zahit_silinebilir":  strategy_zahit_silinebilir,
    "asistal_g130t":      strategy_asistal_g130t,
    "tema_isicam":        strategy_tema_isicam,
    "mavera":             strategy_mavera,
    "tumen_giart":        strategy_tumen_giart,
    "generic":            strategy_generic,
}


def run_strategy(strategy_name: str, width, height, quantity, role_to_profile, geometry=None):
    """Strategy adına göre uygun fonksiyonu çağırır + aksesuar listesi ekler."""
    fn = STRATEGIES.get(strategy_name) or strategy_generic
    if fn is strategy_generic:
        result = fn(width, height, quantity, role_to_profile, geometry=geometry)
    else:
        result = fn(width, height, quantity, role_to_profile)

    # Aksesuar listesi ekle
    acc_fn = ACCESSORIES_REGISTRY.get(strategy_name, accessories_generic)
    result["aksesuarlar"] = acc_fn(width, height, quantity, result["cam_olculeri"])

    # Galvaniz/çelik motor borusu (kg/m=0 olan tedarikçilerde) → metre fiyatlı aksesuar
    # Tümen GI-ART gibi alüminyum motor borusu kullananlarda bin-packing'e dahil edilir,
    # bu listede metre kalemi 0 gelir ve eklenmez.
    motor_metre = result.get("motor_borusu_metre", 0)
    if motor_metre and motor_metre > 0:
        motor_kod = result.get("motor_borusu_kod", "G.AKS1001")
        result["aksesuarlar"].insert(0, (
            "motor_borusu",
            f"Motor Borusu ({motor_kod}, sekizgen galvaniz çelik)",
            motor_metre,
            "metre",
            "boru_m_tl",
        ))

    return result
