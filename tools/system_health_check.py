#!/usr/bin/env python3
"""Sistem genelinde bug/edge case tespiti — 8 tedarikçi × 3 boyut × edge cases."""
from app.db.database import SessionLocal
from app.models.user import User
from app.models.company import Company
from app.models.subscription import Subscription
from app.models.vendor import Vendor, VendorSystem, VendorProfile
from app.models.company_settings import CompanySettings
from app.services.giyotin_strategies import run_strategy

db = SessionLocal()

TEDARIKCILER = [
    ("katar",   "katar"),
    ("saray",   "saray_gyt80"),
    ("zahit",   "zahit_klasik"),
    ("zahit",   "zahit_silinebilir"),
    ("asistal", "asistal_g130t"),
    ("tema",    "tema_isicam"),
    ("mavera",  "mavera"),
    ("tumen",   "tumen_giart"),
]

TEST_CASES = [
    ("Kucuk",  1500, 2000, 1),
    ("Orta",   3000, 2800, 2),
    ("Buyuk",  4500, 3200, 1),
]

EDGE_CASES = [
    ("XS-200x500",   200,  500,  1),   # cok kucuk - cam_boy negatif olabilir
    ("XS-500x800",   500,  800,  1),   # min - uyari beklenir
    ("XL-6000x4000", 6000, 4000, 1),   # cok buyuk - cam takviye gerek
    ("Q0-3000x3000", 3000, 3000, 0),   # adet=0
    ("QN-3000x3000", 3000, 3000, -1),  # adet=-1
]

def load_vendor(slug, strategy):
    v = db.query(Vendor).filter(Vendor.slug==slug).first()
    if not v: return None, None
    vs = db.query(VendorSystem).filter(
        VendorSystem.vendor_id==v.id,
        VendorSystem.calc_strategy==strategy,
    ).first()
    if not vs: return v, None
    profiles = db.query(VendorProfile).filter(VendorProfile.system_id==vs.id).all()
    return vs, {p.role: p for p in profiles}

print("=" * 90)
print("STANDART HESAP TESTLERI (8 vendor x 3 size = 24 senaryo)")
print("=" * 90)
print(f"{'Sistem':30} {'Boyut':8} {'kg':>7} {'profil':>6} {'aks':>4} {'eksik':>5} {'uyari':>5}  NOT")
print("-" * 90)

issues = []
for slug, strategy in TEDARIKCILER:
    vs, r2p = load_vendor(slug, strategy)
    if not vs:
        print(f"!! Bulunamadi: {slug}/{strategy}")
        continue
    for label, w, h, q in TEST_CASES:
        try:
            result = run_strategy(strategy, w, h, q, r2p)
            kg = sum(p["olcu"]/1000 * p["adet"] * p["kg_per_m"] for p in result["profiller"])
            ne = len(result.get("eksik_roller", []))
            nu = len(result.get("uyarilar", []))
            note = ""
            if ne: note += f" EKSIK:{[e['role'] for e in result['eksik_roller']][:3]}"
            if nu: note += f" UYARI:{nu}"
            print(f"{vs.name[:30]:30} {label:8} {kg:>7.1f} {len(result['profiller']):>6} {len(result['aksesuarlar']):>4} {ne:>5} {nu:>5}{note}")
            if ne or nu:
                issues.append((slug, strategy, label, ne, nu))
        except Exception as e:
            print(f"{vs.name[:30]:30} {label:8} >>> EXCEPTION: {type(e).__name__}: {e}")
            issues.append((slug, strategy, label, "EXC", str(e)))

print()
print("=" * 90)
print("EDGE CASE TESTLERI")
print("=" * 90)
print(f"{'Sistem':30} {'Senaryo':18} {'kg':>7} {'profil':>6} NOT")
print("-" * 90)

# Sadece katar ile edge case (cunku tum vendor icin ayni davranis beklenir)
slug, strategy = "katar", "katar"
vs, r2p = load_vendor(slug, strategy)

for label, w, h, q in EDGE_CASES:
    try:
        result = run_strategy(strategy, w, h, q, r2p)
        kg = sum(p["olcu"]/1000 * p["adet"] * p["kg_per_m"] for p in result["profiller"])
        ne = len(result.get("eksik_roller", []))
        nu = len(result.get("uyarilar", []))
        cam = result.get("cam_olculeri", {})
        note = ""
        if cam.get("boy", 0) < 0: note += " !cam_boy<0"
        if cam.get("en", 0) < 0: note += " !cam_en<0"
        if cam.get("m2", 0) < 0: note += " !m2<0"
        if kg < 0: note += " !kg<0"
        if q <= 0 and len(result['profiller']) == 0: note += " (boş - OK)"
        print(f"{vs.name[:30]:30} {label:18} {kg:>7.1f} {len(result['profiller']):>6} cam={cam.get('en')}x{cam.get('boy')} m2={cam.get('m2')}{note}")
        if note and "OK" not in note:
            issues.append(("edge", slug, label, note))
    except Exception as e:
        print(f"{vs.name[:30]:30} {label:18} EXCEPTION: {type(e).__name__}: {e}")
        issues.append(("edge", slug, label, f"EXC: {e}"))

print()
print("=" * 90)
print(f"TOPLAM SORUN SAYISI: {len(issues)}")
print("=" * 90)
for i in issues:
    print(" ", i)

# Settings olmayan sirketleri tespit et
print()
print("=== SETTINGS EKSIK SIRKETLER ===")
companies_no_settings = db.execute(
    db.execute.__self__.bind.execute,
    None,
).bind if False else None
from sqlalchemy import text
result = db.execute(text("""
    SELECT c.id, c.name FROM companies c
    LEFT JOIN company_settings cs ON cs.company_id = c.id
    WHERE cs.id IS NULL ORDER BY c.id
""")).fetchall()
print(f"{len(result)} sirket settings olmadan:")
for row in result:
    print(f"  id={row[0]} name={row[1]}")

db.close()
