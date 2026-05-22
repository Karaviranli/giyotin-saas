"""İlk açılışta GİYOTİN profil katsayıları ve fiyatları için default kayıtları yükler.

Settings (ProductSystem) tablosunda iki kategori altında saklanır:
  • GIYOTIN_PROFIL : K-1401..K-1412 profillerinin kg/m değerleri
  • GIYOTIN_FIYAT  : alüminyum kg, cam m², aksesuar TL fiyatları
"""
import logging
import json
from app.db.database import SessionLocal
from app.models.product_system import ProductSystem

# ── BİNTELLİ profil kg/m değerleri (Kastamonu SMMMO faturasından) ────────────

GIYOTIN_PROFIL_KG_M = {
    "K-1401": 1.293, "K-1402": 0.669, "K-1403": 1.355, "K-1404": 0.653,
    "K-1405": 1.650, "K-1406": 1.005, "K-1407": 0.203, "K-1408": 0.883,
    "K-1409": 0.699, "K-1410": 0.726, "K-1411": 0.726, "K-1412": 0.366,
}

# ── Birim fiyatlar (TL) ──────────────────────────────────────────────────────

GIYOTIN_FIYATLAR = {
    "Alüminyum (TL/kg)":           368.0,
    "Cam (TL/m²) 4+16+4 DC/C Isı": 1915.0,
    "Kayış (TL/m)":                150.0,
    "Sekizgen Boru 70 (TL/m)":     204.0,
    "Kayışlı Set (TL/adet)":       4104.0,
    "Kumanda (TL/adet)":           860.0,
    "Motor (TL/adet)":             3765.0,
    "Genel Gider (%)":             2.5,
}

ESKI_HATALI_DEFAULTS = {
    "GIYOTIN_PROFIL": {
        "K-1411": [0.737],
    },
    "GIYOTIN_FIYAT": {
        "Sekizgen Boru 70 (TL/m)": [20.0],
        "Genel Gider (%)":         [1.0],
    },
}

def bootstrap_giyotin_settings():
    """Giyotin profil katsayıları ve fiyatları için default kayıtları yükler."""
    db = SessionLocal()
    try:
        eklenen_sayisi = 0
        guncellenen_sayisi = 0

        # 1) Profil kg/m
        for kod, kg in GIYOTIN_PROFIL_KG_M.items():
            mevcut = (db.query(ProductSystem)
                        .filter(ProductSystem.kategori == "GIYOTIN_PROFIL",
                                ProductSystem.isim == kod)
                        .first())
            if mevcut:
                eski_hatalilar = ESKI_HATALI_DEFAULTS["GIYOTIN_PROFIL"].get(kod, [])
                if mevcut.kg_katsayi in eski_hatalilar and mevcut.kg_katsayi != kg:
                    mevcut.kg_katsayi = kg
                    guncellenen_sayisi += 1
                continue
            
            db.add(ProductSystem(
                kategori="GIYOTIN_PROFIL",
                isim=kod,
                kg_katsayi=kg,
                ozel_katsayi=1.0,
                ekstra_ayar=json.dumps({"birim": "kg/m"}),
            ))
            eklenen_sayisi += 1

        # 2) Birim fiyatlar
        for isim, tl in GIYOTIN_FIYATLAR.items():
            mevcut = (db.query(ProductSystem)
                        .filter(ProductSystem.kategori == "GIYOTIN_FIYAT",
                                ProductSystem.isim == isim)
                        .first())
            if mevcut:
                eski_hatalilar = ESKI_HATALI_DEFAULTS["GIYOTIN_FIYAT"].get(isim, [])
                if mevcut.kg_katsayi in eski_hatalilar and mevcut.kg_katsayi != tl:
                    mevcut.kg_katsayi = tl
                    guncellenen_sayisi += 1
                continue
            
            birim = "TL"
            if "(TL/" in isim:
                birim = isim.split("(")[-1].rstrip(")")
            
            db.add(ProductSystem(
                kategori="GIYOTIN_FIYAT",
                isim=isim,
                kg_katsayi=tl,
                ozel_katsayi=1.0,
                ekstra_ayar=json.dumps({"birim": birim}),
            ))
            eklenen_sayisi += 1

        if eklenen_sayisi > 0 or guncellenen_sayisi > 0:
            db.commit()
            logging.getLogger(__name__).info(
                f"Bootstrap GİYOTİN: {eklenen_sayisi} yeni eklendi, {guncellenen_sayisi} eski default güncellendi."
            )
    except Exception as e:
        db.rollback()
        logging.getLogger(__name__).warning(f"Giyotin bootstrap atlandı: {e}")
    finally:
        db.close()

def giyotin_ayarlari_oku() -> dict:
    db = SessionLocal()
    try:
        sonuc = {"profil_kg_m": dict(GIYOTIN_PROFIL_KG_M), "fiyatlar": dict(GIYOTIN_FIYATLAR)}
        for s in db.query(ProductSystem).filter(ProductSystem.kategori.in_(["GIYOTIN_PROFIL", "GIYOTIN_FIYAT"])).all():
            if s.kategori == "GIYOTIN_PROFIL" and s.kg_katsayi and s.kg_katsayi > 0:
                sonuc["profil_kg_m"][s.isim] = s.kg_katsayi
            elif s.kategori == "GIYOTIN_FIYAT" and s.kg_katsayi and s.kg_katsayi > 0:
                sonuc["fiyatlar"][s.isim] = s.kg_katsayi
        return sonuc
    except Exception:
        return {"profil_kg_m": dict(GIYOTIN_PROFIL_KG_M), "fiyatlar": dict(GIYOTIN_FIYATLAR)}
    finally:
        db.close()