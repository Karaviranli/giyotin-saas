import math
from typing import List, Dict

class GiyotinService:
    
    @staticmethod
    def optimize_kesim(actual_pieces: List[dict], stock_length: float, kerf: float) -> List[dict]:
        """
        1D Bin Packing (Kesim Optimizasyonu) algoritması. (Eski projenden birebir uyarlandı)
        """
        actual_pieces.sort(key=lambda x: x["length"], reverse=True)

        total_len_with_kerf = sum(p["length"] + kerf for p in actual_pieces)
        teorik_min = math.ceil(total_len_with_kerf / stock_length) if stock_length > 0 else 0

        state = {"best_bins": [], "min_count": float('inf')}
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

        state["best_bins"] = [list(b) for b in bins]
        state["min_count"] = len(bins)

        if state["min_count"] > teorik_min > 0:
            curr = []
            it = [0]

            def backtrack(idx):
                it[0] += 1
                if it[0] > 50000 or state["min_count"] == teorik_min or len(curr) >= state["min_count"]:
                    return
                if idx == len(actual_pieces):
                    if len(curr) < state["min_count"]:
                        state["min_count"] = len(curr)
                        state["best_bins"] = [list(b) for b in curr]
                    return

                p = actual_pieces[idx]
                p_total = p["length"] + kerf

                for i in range(len(curr)):
                    bin_total = sum(item["length"] + kerf for item in curr[i])
                    if bin_total + p_total <= stock_length:
                        curr[i].append(p)
                        backtrack(idx + 1)
                        curr[i].pop()
                        if bin_total + p_total == stock_length:
                            break
                curr.append([p])
                backtrack(idx + 1)
                curr.pop()

            backtrack(0)

        res = []
        for b in state["best_bins"]:
            waste = stock_length - sum(p["length"] + kerf for p in b)
            b_sorted = sorted(b, key=lambda x: x["length"], reverse=True)
            res.append({"pieces": b_sorted, "waste": round(waste, 2)})

        res.sort(key=lambda x: x["waste"])
        return res

    @staticmethod
    def _kod_baz(kod: str) -> str:
        s = (kod or "").strip()
        parts = s.split()
        if len(parts) == 2 and parts[0].startswith("K-") and len(parts[1]) <= 2:
            return parts[0]
        return s

    @staticmethod
    def _profiller_kod_bazli(profiller: list) -> dict:
        gruplar: dict = {}
        for p in profiller:
            kod = str(p["kod"]).strip()
            olcu = float(p["olcu"])
            adet = int(p["adet"])
            if olcu <= 0 or adet <= 0: continue
            
            kodlar = [k.strip() for k in kod.split("/") if k.strip()]
            if not kodlar: continue
            
            if len(kodlar) > 1:
                pay = adet // len(kodlar)
                artan = adet - pay * len(kodlar)
                for i, k in enumerate(kodlar):
                    pay_i = pay + (1 if i < artan else 0)
                    if pay_i > 0:
                        gruplar.setdefault(k, []).append({"uzunluk": olcu, "adet": pay_i})
            else:
                gruplar.setdefault(kodlar[0], []).append({"uzunluk": olcu, "adet": adet})
        return gruplar

    @classmethod
    def _optimizasyon_stok_sayisi(cls, parcalar_per_kod: list, stok_uzunlugu: float, fire_payi: float) -> int:
        tum = []
        for p in parcalar_per_kod:
            for _ in range(int(p["adet"])):
                tum.append({"length": float(p["uzunluk"]), "label": "", "kod": ""})
        if not tum: return 0
        sonuclar = cls.optimize_kesim(tum, stok_uzunlugu, fire_payi)
        return len(sonuclar)

    @classmethod
    def calculate_cost(cls, profiller: list, aksesuarlar: list, cam_m2: float, sistem_adedi: int,
                       stok_uzunlugu: float, fire_payi: float, prices: dict, profil_kg_m: dict) -> dict:
        """
        Şirketin özel fiyatlarına (prices) göre stock-based maliyet hesabı yapar.
        """
        alm_kg_tl = prices.get("aluminyum_kg_tl", 368.0)
        cam_m2_tl = prices.get("cam_m2_tl", 1915.0)
        kayis_tl = prices.get("kayis_m_tl", 150.0)
        boru_tl = prices.get("sekizgen_boru_m_tl", 204.0)
        set_tl = prices.get("kayisli_set_tl", 4104.0)
        kumanda_tl = prices.get("kumanda_tl", 860.0)
        motor_tl = prices.get("motor_tl", 3765.0)
        genel_gider_y = prices.get("genel_gider_yuzde", 2.5)

        stok_m = stok_uzunlugu / 1000
        gruplar = cls._profiller_kod_bazli(profiller)

        profil_tl, profil_toplam_kg = 0.0, 0.0
        profil_detay = []
        
        for kod, parcalar in gruplar.items():
            if not kod.startswith("K-"): continue
            
            kg_per_m = profil_kg_m.get(cls._kod_baz(kod), 0.0)
            if kg_per_m <= 0: continue
            
            stok_say = cls._optimizasyon_stok_sayisi(parcalar, stok_uzunlugu, fire_payi)
            kullanilan_m = stok_say * stok_m
            kg = kullanilan_m * kg_per_m
            kalem_tl = kg * alm_kg_tl
            
            profil_toplam_kg += kg
            profil_tl += kalem_tl
            profil_detay.append({
                "kod": kod, "kg_per_m": kg_per_m, "stok_adedi": stok_say,
                "kullanilan_m": round(kullanilan_m, 2), "kg": round(kg, 2), "tl": round(kalem_tl, 2)
            })

        motor_borusu_tl = 0.0
        motor_borusu_detay = None
        if "G.AKS1001" in gruplar:
            stok_say = cls._optimizasyon_stok_sayisi(gruplar["G.AKS1001"], stok_uzunlugu, fire_payi)
            kullanilan_m = stok_say * stok_m
            motor_borusu_tl = kullanilan_m * boru_tl
            motor_borusu_detay = {"stok_adedi": stok_say, "kullanilan_m": round(kullanilan_m, 2), "tl": round(motor_borusu_tl, 2)}

        kayis_metraj = sum((float(a["adet"]) / 1000) for a in aksesuarlar if str(a["kod"]).strip() == "G.AKS1003")
        kayis_tl_toplam = kayis_metraj * kayis_tl
        cam_tl_toplam = cam_m2 * cam_m2_tl
        sabit_aksesuar_tl = sistem_adedi * (motor_tl + kumanda_tl + set_tl)

        ara_toplam = profil_tl + motor_borusu_tl + kayis_tl_toplam + cam_tl_toplam + sabit_aksesuar_tl
        genel_gider_tl = ara_toplam * (genel_gider_y / 100)
        toplam = ara_toplam + genel_gider_tl

        return {
            "profil_toplam_kg": round(profil_toplam_kg, 2),
            "profil_detay": profil_detay,
            "motor_borusu": motor_borusu_detay,
            "kalemler": {
                "profil_tl": round(profil_tl, 2),
                "motor_borusu_tl": round(motor_borusu_tl, 2),
                "kayis_tl": round(kayis_tl_toplam, 2),
                "cam_tl": round(cam_tl_toplam, 2),
                "sabit_aksesuar_tl": round(sabit_aksesuar_tl, 2),
                "ara_toplam_tl": round(ara_toplam, 2),
                "genel_gider_tl": round(genel_gider_tl, 2),
            },
            "toplam_tl": round(toplam, 2),
        }

    @classmethod
    def calculate_system(cls, g: float, y: float, adet: int, stok_uzunlugu: float = 6500, fire_payi: float = 5, prices: dict = None, profil_kg_m: dict = None) -> dict:
        """
        Kavira'nın ana hesaplama modülü.
        Ölçüleri alır, cam ve profil listelerini üretir, sonrasında calculate_cost'u çağırır.
        """
        # Varsayılan fiyatlar ve kg verileri (Eğer şirketin veritabanında özel fiyatı yoksa bu kullanılır)
        if prices is None:
            prices = {"aluminyum_kg_tl": 368.0, "cam_m2_tl": 1915.0, "kayis_m_tl": 150.0, "sekizgen_boru_m_tl": 204.0, "kayisli_set_tl": 4104.0, "kumanda_tl": 860.0, "motor_tl": 3765.0, "genel_gider_yuzde": 2.5}
        if profil_kg_m is None:
            # Örnek ağırlıklar (Bunu gerçek ayarlarına göre güncelleyebilirsin)
            profil_kg_m = {"K-1401": 1.2, "K-1402": 1.1, "K-1403": 1.5, "K-1404": 0.8, "K-1405": 1.3, "K-1406": 1.0, "K-1407": 0.5, "K-1408": 0.9, "K-1409": 1.4, "K-1410": 1.1, "K-1411": 0.7, "K-1412": 1.6}

        cam_en = g - 149
        cam_boy = (y - 263) / 3
        cam_adet = adet * 3
        sistem_m2 = (g * y * adet) / 1_000_000
        al_kg1 = (((y * 7) / 1000) + ((g * 9.4) / 1000)) * adet
        al_kg2 = al_kg1 * 1.10
        cam_m2 = (cam_en * cam_boy * cam_adet) / 1_000_000

        profiller = [
            {"isim": "Motor Kutusu Alt/Üst", "kod": "K-1401/K-1402", "olcu": g - 30, "adet": adet * 2},
            {"isim": "Alt Kasa", "kod": "K-1403", "olcu": g - 45, "adet": adet * 1},
            {"isim": "Yan Ana Dikme", "kod": "K-1405", "olcu": y - 175, "adet": adet * 2},
            {"isim": "Yan Ara Dikme", "kod": "K-1404", "olcu": y - 175, "adet": adet * 2},
            {"isim": "Yan Kutu Baza", "kod": "K-1406", "olcu": (cam_boy * 2) + 20, "adet": adet * 2},
            {"isim": "Yan Dikey Kapak", "kod": "K-1407", "olcu": cam_boy + 28, "adet": adet * 2},
            {"isim": "Vasistas Üst Baza", "kod": "K-1408", "olcu": g - 177, "adet": adet * 1},
            {"isim": "Fonksiyonel Baza (Yatay)", "kod": "K-1409 Y", "olcu": g - 177, "adet": adet * 2},
            {"isim": "Fonksiyonel Baza (Dikey)", "kod": "K-1409 D", "olcu": cam_boy + 37, "adet": adet * 4},
            {"isim": "İspanyolet Baza", "kod": "K-1410", "olcu": cam_boy + 29, "adet": adet * 2},
            {"isim": "Kenet Çekme Profil", "kod": "K-1411", "olcu": g - 177, "adet": adet * 3},
            {"isim": "Hareketli Üst Küpeşte", "kod": "K-1412", "olcu": g - 177, "adet": adet * 1},
            {"isim": "Motor Borusu", "kod": "G.AKS1001", "olcu": g - 75, "adet": adet * 1},
        ]

        aksesuarlar = [
            {"isim": "Kasa Alt Köşe Takozu", "kod": "G1012", "adet": adet * 2},
            {"isim": "Vasistas Üst Köşe", "kod": "G1013", "adet": adet * 2},
            {"isim": "Motor Köşe", "kod": "G1014", "adet": adet * 2},
            {"isim": "Kanat Köşe Takozu", "kod": "G1015", "adet": adet * 4},
            {"isim": "Vasistas Kilit", "kod": "G1016", "adet": adet * 2},
            {"isim": "İspanyolet Kol", "kod": "G1017", "adet": adet * 2},
            {"isim": "İspanyolet Makas", "kod": "G1018", "adet": adet * 2},
            {"isim": "İspanyolet", "kod": "G1019", "adet": adet * 2},
            {"isim": "Vasistas Kanat Alt Köşe", "kod": "G1020", "adet": adet * 2},
            {"isim": "Orta Kanat Köşe", "kod": "G1021", "adet": adet * 4},
            {"isim": "Boru Başı", "kod": "G1023", "adet": adet * 1},
            {"isim": "Kasnak", "kod": "G.AKS1004", "adet": adet * 2},
            {"isim": "Kayış", "kod": "G.AKS1003", "adet": round((y / 4) * 4.7, 1)},
        ]

        profiller = [{**p, "olcu": round(p["olcu"], 1)} for p in profiller]

        maliyet = cls.calculate_cost(profiller, aksesuarlar, cam_m2, adet, stok_uzunlugu, fire_payi, prices, profil_kg_m)

        return {
            "cam": {"en": round(cam_en, 1), "boy": round(cam_boy, 1), "adet": cam_adet, "m2": round(cam_m2, 3)},
            "sistem_m2": round(sistem_m2, 3),
            "profiller": profiller,
            "aksesuarlar": aksesuarlar,
            "maliyet": maliyet,
        }