import math
from sqlalchemy.orm import Session

class GiyotinService:

    @staticmethod
    def _kod_baz(kod: str) -> str:
        s = (kod or "").strip()
        parts = s.split()
        if len(parts) == 2 and parts[0].startswith("K-") and len(parts[1]) <= 2:
            return parts[0]
        return s

    @staticmethod
    def optimize_kesim(actual_pieces: list, stock_length: float, kerf: float) -> list:
        actual_pieces.sort(key=lambda x: x["length"], reverse=True)
        bins = []
        for p in actual_pieces:
            fit = -1
            m_l = float('inf')
            p_total = p["length"] + kerf
            for i, b in enumerate(bins):
                bin_total = sum(item["length"] + kerf for item in b)
                l = stock_length - (bin_total + p_total)
                if 0 <= l < m_l:
                    m_l, fit = l, i
            if fit != -1:
                bins[fit].append(p)
            else:
                bins.append([p])
        
        res = []
        for b in bins:
            waste = stock_length - sum(p["length"] + kerf for p in b)
            res.append({"pieces": sorted(b, key=lambda x: x["length"], reverse=True), "waste": round(waste, 2)})
        return sorted(res, key=lambda x: x["waste"])

    @classmethod
    def calculate(cls, width: float, height: float, quantity: int, stock_length: float, kerf: float, company_id: int, db: Session):
        # Dinamik Ayarları Veritabanından Oku
        from app.db.seed import giyotin_ayarlari_oku
        from app.models.company_settings import CompanySettings
        
        # Profil ağırlıkları (Fiziksel sabit oldukları için global olarak bırakıyoruz)
        ayarlar = giyotin_ayarlari_oku()
        profil_kg_m = ayarlar.get("profil_kg_m", {})

        # Şirkete Özel Fiyatları Çek
        company_settings = db.query(CompanySettings).filter(CompanySettings.company_id == company_id).first()
        if not company_settings:
            company_settings = CompanySettings(company_id=company_id)
        
        alm_kg_tl = company_settings.aluminyum_kg_tl
        cam_m2_tl = company_settings.cam_m2_tl
        kayis_tl_m = company_settings.kayis_m_tl
        boru_tl_m = company_settings.boru_m_tl
        sabit_aksesuar_set_tl = company_settings.kayisli_set_tl + company_settings.kumanda_tl + company_settings.motor_tl
        genel_gider_yuzde = company_settings.genel_gider_yuzde

        # 1. Parça Ölçülerini Hesapla
        cam_en = width - 149
        cam_boy = (height - 263) / 3
        cam_adet = quantity * 3
        cam_m2 = (cam_en * cam_boy * cam_adet) / 1_000_000

        profiller = [
            {"isim": "Motor Kutusu Alt/Üst",      "kod": "K-1401/K-1402", "olcu": width - 30,          "adet": quantity * 2},
            {"isim": "Alt Kasa",                  "kod": "K-1403",        "olcu": width - 45,          "adet": quantity * 1},
            {"isim": "Yan Ana Dikme",             "kod": "K-1405",        "olcu": height - 175,        "adet": quantity * 2},
            {"isim": "Yan Ara Dikme",             "kod": "K-1404",        "olcu": height - 175,        "adet": quantity * 2},
            {"isim": "Yan Kutu Baza",             "kod": "K-1406",        "olcu": (cam_boy * 2) + 20,  "adet": quantity * 2},
            {"isim": "Yan Dikey Kapak",           "kod": "K-1407",        "olcu": cam_boy + 28,        "adet": quantity * 2},
            {"isim": "Vasistas Üst Baza",         "kod": "K-1408",        "olcu": width - 177,         "adet": quantity * 1},
            {"isim": "Fonksiyonel Baza (Yatay)",  "kod": "K-1409 Y",      "olcu": width - 177,         "adet": quantity * 2},
            {"isim": "Fonksiyonel Baza (Dikey)",  "kod": "K-1409 D",      "olcu": cam_boy + 37,        "adet": quantity * 4},
            {"isim": "İspanyolet Baza",           "kod": "K-1410",        "olcu": cam_boy + 29,        "adet": quantity * 2},
            {"isim": "Kenet Çekme Profil",        "kod": "K-1411",        "olcu": width - 177,         "adet": quantity * 3},
            {"isim": "Hareketli Üst Küpeşte",     "kod": "K-1412",        "olcu": width - 177,         "adet": quantity * 1},
            {"isim": "Motor Borusu",              "kod": "G.AKS1001",     "olcu": width - 75,          "adet": quantity * 1},
        ]

        # 2. Kod Bazlı Gruplama ve Optimizasyon
        gruplar = {}
        for p in profiller:
            kodlar = [k.strip() for k in p["kod"].split("/")]
            for k in kodlar:
                # K-1401/1402 gibi slash'lı kodları bölüştür
                pay_adet = p["adet"] // len(kodlar)
                gruplar.setdefault(k, []).extend([{"length": p["olcu"], "label": p["isim"]}] * pay_adet)

        profil_detay = []
        profil_tl = 0.0
        motor_borusu_tl = 0.0
        kesim_plani_ozet = {"kodlar": {}, "toplam_stok": 0, "toplam_fire": 0.0}

        for kod, parcalar in gruplar.items():
            if not parcalar: continue
            bins = cls.optimize_kesim(parcalar, stock_length, kerf)
            stok_sayisi = len(bins)
            kod_fire = sum(b["waste"] for b in bins)
            
            kesim_plani_ozet["kodlar"][kod] = {
                "bins": bins,
                "stok_adedi": stok_sayisi,
                "fire_mm": round(kod_fire, 2)
            }
            kesim_plani_ozet["toplam_stok"] += stok_sayisi
            kesim_plani_ozet["toplam_fire"] += kod_fire

            # Maliyet ekle
            kullanilan_m = stok_sayisi * (stock_length / 1000)
            if kod == "G.AKS1001":
                motor_borusu_tl = kullanilan_m * boru_tl_m
            elif kod.startswith("K-"):
                kg = kullanilan_m * profil_kg_m.get(cls._kod_baz(kod), 0.0)
                profil_tl += kg * alm_kg_tl

        # 3. Diğer Maliyetler
        kayis_m = (height / 4) * 4.7 * quantity / 1000
        kayis_tl = kayis_m * kayis_tl_m
        cam_tl = cam_m2 * cam_m2_tl
        sabit_tl = quantity * sabit_aksesuar_set_tl
        
        ara_toplam = profil_tl + motor_borusu_tl + kayis_tl + cam_tl + sabit_tl
        genel_gider = ara_toplam * (genel_gider_yuzde / 100)

        cost_details = {
            "total_profile_cost": round(profil_tl, 2),
            "total_accessory_cost": round(motor_borusu_tl + kayis_tl + sabit_tl, 2),
            "cam_cost": round(cam_tl, 2),
            "overhead": round(genel_gider, 2),
            "total_cost": round(ara_toplam + genel_gider, 2),
        }

        return cost_details, kesim_plani_ozet