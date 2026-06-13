"""
Giyotin hesap motoru — strategy pattern.

Mantık:
  1) Aktif vendor sistemi al → calc_strategy adını oku
  2) strategies.run_strategy() ile uygun strategy'i çağır
  3) Strategy → profil listesi + cam ölçüleri + eksik roller
  4) Bin-packing kesim optimizasyonu
  5) Şirket settings'ten birim fiyatlar → maliyet

Her vendor sisteminin KENDİ imalat reçetesi var (strategy fonksiyonu).
Bu sayede Saray'da L-188, Katar'da w-177 farklı olabilir — engine değişmez.
"""
import math
from sqlalchemy.orm import Session
from app.services.giyotin_strategies import run_strategy


def _get_active_vendor_system(db: Session, company_id: int):
    from app.models.vendor import Vendor, VendorSystem
    from app.models.company_settings import CompanySettings

    s = db.query(CompanySettings).filter(CompanySettings.company_id == company_id).first()
    slug = getattr(s, "preferred_vendor_slug", None) if s else None
    sub = getattr(s, "preferred_vendor_subcategory", None) if s else None

    vendor = None
    if slug:
        vendor = db.query(Vendor).filter(Vendor.slug == slug, Vendor.is_active == True).first()
    if not vendor:
        vendor = db.query(Vendor).filter(Vendor.is_default == True, Vendor.is_active == True).first()
    if not vendor:
        return None

    q = db.query(VendorSystem).filter(
        VendorSystem.vendor_id == vendor.id,
        VendorSystem.category == "giyotin",
        VendorSystem.is_active == True,
    )
    if sub:
        sys = q.filter(VendorSystem.sub_category == sub).first()
        if sys:
            return sys
    return q.first()


class GiyotinService:

    @staticmethod
    def _kod_baz(kod: str) -> str:
        s = (kod or "").strip()
        parts = s.split()
        if len(parts) == 2 and len(parts[1]) <= 2:
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
            res.append({"pieces": sorted(b, key=lambda x: x["length"], reverse=True),
                        "waste": round(waste, 2)})
        return sorted(res, key=lambda x: x["waste"])

    @classmethod
    def calculate(cls, width: float, height: float, quantity: int,
                  stock_length: float, kerf: float, company_id: int, db: Session):
        from app.models.company_settings import CompanySettings
        from app.models.vendor import VendorProfile

        cs = db.query(CompanySettings).filter(CompanySettings.company_id == company_id).first()
        if not cs:
            cs = CompanySettings(company_id=company_id)
        alm_kg_tl  = cs.aluminyum_kg_tl or 368.0
        cam_m2_tl  = cs.cam_m2_tl or 1915.0
        kayis_tl_m = cs.kayis_m_tl or 150.0
        boru_tl_m  = cs.boru_m_tl or 204.0
        sabit_set  = (cs.kayisli_set_tl or 4104.0) + (cs.kumanda_tl or 860.0) + (cs.motor_tl or 3765.0)
        gg_yuzde   = cs.genel_gider_yuzde or 2.5

        system = _get_active_vendor_system(db, company_id)
        vendor_info = None
        role_to_profile = {}
        geometry = None
        strategy_name = "generic"
        if system:
            stock_length = system.profile_length_mm or stock_length
            strategy_name = system.calc_strategy or "generic"
            geometry = system.geometry
            vendor_info = {
                "vendor_slug":  system.vendor.slug,
                "vendor_name":  system.vendor.name,
                "system_name":  system.name,
                "sub_category": system.sub_category,
                "code_prefix":  system.code_prefix,
                "strategy":     strategy_name,
                "geometry":     geometry,
            }
            profiles = db.query(VendorProfile).filter(
                VendorProfile.system_id == system.id
            ).all()
            for p in profiles:
                if p.role and p.role not in role_to_profile:
                    role_to_profile[p.role] = p

        # ── Strategy'i çalıştır ────────────────────────────────────
        result = run_strategy(
            strategy_name, width, height, quantity, role_to_profile,
            geometry=geometry,
        ) if strategy_name == "generic" else run_strategy(
            strategy_name, width, height, quantity, role_to_profile,
        )
        profiller     = result["profiller"]
        cam_olculeri  = result["cam_olculeri"]
        eksik_roller  = result["eksik_roller"]
        aksesuarlar   = result.get("aksesuarlar", [])
        uyarilar_olcu = result.get("uyarilar", [])

        # ── Gruplama + Optimizasyon + Maliyet ──────────────────────
        gruplar = {}
        for p in profiller:
            gruplar.setdefault(p["kod"], []).extend(
                [{"length": p["olcu"], "label": p["isim"]}] * p["adet"]
            )

        kesim_plani_ozet = {"kodlar": {}, "toplam_stok": 0, "toplam_fire": 0.0}
        profil_tl = 0.0
        motor_borusu_tl = 0.0
        kod_kg = {p["kod"]: p["kg_per_m"] for p in profiller}
        kod_isim = {p["kod"]: p["isim"] for p in profiller}
        kod_adet = {}
        kod_net_mm = {}   # gerçek kullanılan (kesilen) parça toplamı
        for p in profiller:
            kod_adet[p["kod"]] = kod_adet.get(p["kod"], 0) + p["adet"]
            kod_net_mm[p["kod"]] = kod_net_mm.get(p["kod"], 0.0) + p["olcu"] * p["adet"]

        # Malzeme özeti — her profil için bar/kg/fire toplamı
        malzeme_ozeti = []
        toplam_profil_kg = 0.0
        toplam_kullanilan_mm = 0.0
        toplam_fire_mm = 0.0
        toplam_satin_alinan_mm = 0.0

        for kod, parcalar in gruplar.items():
            if not parcalar:
                continue
            bins = cls.optimize_kesim(parcalar, stock_length, kerf)
            stok = len(bins)
            fire = sum(b["waste"] for b in bins)
            kesim_plani_ozet["kodlar"][kod] = {
                "bins": bins, "stok_adedi": stok, "fire_mm": round(fire, 2)
            }
            kesim_plani_ozet["toplam_stok"] += stok
            kesim_plani_ozet["toplam_fire"] += fire

            satin_alinan_mm = stok * stock_length
            net_mm = kod_net_mm.get(kod, 0.0)
            fire_yuzde = (fire / satin_alinan_mm * 100) if satin_alinan_mm > 0 else 0.0
            kullanilan_m = stok * (stock_length / 1000)
            kg = kullanilan_m * kod_kg.get(kod, 0.0)

            if kod == "G.AKS1001":
                motor_borusu_tl = kullanilan_m * boru_tl_m
                kalem_tl = motor_borusu_tl
                kalem_tip = "boru"
            else:
                profil_tl += kg * alm_kg_tl
                kalem_tl = kg * alm_kg_tl
                kalem_tip = "profil"
                toplam_profil_kg += kg

            toplam_kullanilan_mm += net_mm
            toplam_fire_mm += fire
            toplam_satin_alinan_mm += satin_alinan_mm

            malzeme_ozeti.append({
                "kod": kod,
                "isim": kod_isim.get(kod, kod),
                "adet": kod_adet.get(kod, 0),
                "net_mm": round(net_mm, 0),
                "bar_adedi": stok,
                "satin_alinan_m": round(satin_alinan_mm / 1000, 1),
                "kg": round(kg, 2),
                "fire_mm": round(fire, 0),
                "fire_yuzde": round(fire_yuzde, 1),
                "tutar_tl": round(kalem_tl, 2),
                "tip": kalem_tip,
            })

        # Fire % en yüksekten sırala (en israflı profiller üstte)
        malzeme_ozeti.sort(key=lambda x: x["fire_yuzde"], reverse=True)

        ortalama_fire_yuzde = (toplam_fire_mm / toplam_satin_alinan_mm * 100) if toplam_satin_alinan_mm > 0 else 0.0
        fire_kg = (toplam_fire_mm / 1000) * (toplam_profil_kg / max(toplam_kullanilan_mm / 1000, 0.001)) if toplam_kullanilan_mm > 0 else 0.0
        fire_maliyet_tl = fire_kg * alm_kg_tl

        kayis_m  = (height / 4) * 4.7 * quantity / 1000
        kayis_tl = kayis_m * kayis_tl_m
        cam_tl   = cam_olculeri["m2"] * cam_m2_tl
        sabit_tl = quantity * sabit_set

        # ── Aksesuarların maliyetini hesapla ───────────────────────
        aksesuar_detay = []
        aksesuar_tl_top = 0.0
        for (key, isim, miktar, birim, fiyat_alani) in aksesuarlar:
            birim_tl = getattr(cs, fiyat_alani, None) or 0.0
            tl = float(miktar) * float(birim_tl)
            aksesuar_tl_top += tl
            aksesuar_detay.append({
                "key": key, "isim": isim,
                "miktar": round(float(miktar), 2), "birim": birim,
                "birim_tl": float(birim_tl), "tl": round(tl, 2),
            })

        iscilik_tl = quantity * (cs.iscilik_sistem_tl or 0.0)
        nakliye_tl = cs.nakliye_montaj_tl or 0.0

        ara_toplam  = (profil_tl + motor_borusu_tl + kayis_tl + cam_tl
                       + sabit_tl + aksesuar_tl_top + iscilik_tl + nakliye_tl)
        genel_gider = ara_toplam * (gg_yuzde / 100)
        maliyet     = ara_toplam + genel_gider   # toplam MALİYET (kâr hariç)

        # ── Fiyatlandırma katmanları ───────────────────────────────
        kar_yuzde = cs.kar_marji_yuzde if cs.kar_marji_yuzde is not None else 35.0
        kdv_yuzde = cs.kdv_yuzde if cs.kdv_yuzde is not None else 20.0
        kar_tl    = maliyet * (kar_yuzde / 100)
        satis_kdv_haric = maliyet + kar_tl
        kdv_tl    = satis_kdv_haric * (kdv_yuzde / 100)
        satis_kdv_dahil = satis_kdv_haric + kdv_tl

        toplam_m2 = cam_olculeri["m2"] if cam_olculeri["m2"] > 0 else 1.0
        m2_birim_fiyat = satis_kdv_dahil / toplam_m2
        sistem_birim_fiyat = satis_kdv_dahil / max(quantity, 1)

        pricing = {
            "maliyet_tl":          round(maliyet, 2),
            "kar_yuzde":           round(kar_yuzde, 1),
            "kar_tl":              round(kar_tl, 2),
            "satis_kdv_haric_tl":  round(satis_kdv_haric, 2),
            "kdv_yuzde":           round(kdv_yuzde, 1),
            "kdv_tl":              round(kdv_tl, 2),
            "satis_kdv_dahil_tl":  round(satis_kdv_dahil, 2),
            "m2_birim_fiyat_tl":   round(m2_birim_fiyat, 2),
            "sistem_birim_fiyat_tl": round(sistem_birim_fiyat, 2),
            "toplam_m2":           round(cam_olculeri["m2"], 2),
        }

        fire_analizi = {
            "toplam_satin_alinan_m":  round(toplam_satin_alinan_mm / 1000, 1),
            "toplam_kullanilan_m":    round(toplam_kullanilan_mm / 1000, 1),
            "toplam_fire_m":          round(toplam_fire_mm / 1000, 1),
            "ortalama_fire_yuzde":    round(ortalama_fire_yuzde, 1),
            "toplam_profil_kg":       round(toplam_profil_kg, 1),
            "fire_kg":                round(fire_kg, 1),
            "fire_maliyet_tl":        round(fire_maliyet_tl, 2),
            "toplam_bar":             kesim_plani_ozet["toplam_stok"],
        }

        # Maliyet dağılımı (yüzde olarak) — donut chart için
        maliyet_dagilim = []
        for label, val in [
            ("Profil", profil_tl + motor_borusu_tl),
            ("Cam", cam_tl),
            ("Aksesuar", aksesuar_tl_top),
            ("Sabit (Motor/Kumanda)", sabit_tl),
            ("Kayış", kayis_tl),
            ("İşçilik", iscilik_tl),
            ("Genel Gider", genel_gider),
        ]:
            if val > 0:
                maliyet_dagilim.append({
                    "label": label, "tl": round(val, 2),
                    "yuzde": round(val / maliyet * 100, 1) if maliyet > 0 else 0,
                })

        cost_details = {
            # Geriye dönük uyumluluk
            "total_profile_cost":   round(profil_tl, 2),
            "total_accessory_cost": round(motor_borusu_tl + kayis_tl + sabit_tl + aksesuar_tl_top, 2),
            "cam_cost":             round(cam_tl, 2),
            "overhead":             round(genel_gider, 2),
            "total_cost":           round(maliyet, 2),
            # Detay maliyet kalemleri
            "motor_borusu_tl":      round(motor_borusu_tl, 2),
            "kayis_tl":             round(kayis_tl, 2),
            "sabit_aksesuar_tl":    round(sabit_tl, 2),
            "detay_aksesuar_tl":    round(aksesuar_tl_top, 2),
            "iscilik_tl":           round(iscilik_tl, 2),
            "nakliye_tl":           round(nakliye_tl, 2),
            "ara_toplam_tl":        round(ara_toplam, 2),
            # YENİ — zengin veriler
            "pricing":              pricing,
            "fire_analizi":         fire_analizi,
            "malzeme_ozeti":        malzeme_ozeti,
            "maliyet_dagilim":      maliyet_dagilim,
            "vendor":               vendor_info,
            "eksik_roller":         eksik_roller,
            "olcu_uyarilari":       uyarilar_olcu,
            "cam_olculeri":         cam_olculeri,
            "imalat_listesi":       [
                {
                    "isim": p["isim"], "kod": p["kod"], "role": p["role"],
                    "olcu_mm": round(p["olcu"], 1), "adet": p["adet"],
                    "kg_per_m": p["kg_per_m"],
                }
                for p in profiller
            ],
            "aksesuar_listesi":     aksesuar_detay,
        }
        return cost_details, kesim_plani_ozet
