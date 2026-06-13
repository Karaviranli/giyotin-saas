"""
Vendor (Tedarikçi) okuma + tercih endpoint'leri.

Public:
  GET /vendors                  → tüm aktif vendor'ları listele (publike + şirketin özel'i)
  GET /vendors/{slug}/systems   → vendor'ın sistemlerini listele
  GET /vendors/{slug}/systems/{sub}/profiles → o sistemin profilleri
  GET /vendors/my-active        → şirketin aktif vendor + sistem seçimi
  PUT /vendors/my-active        → değiştir

Admin:
  POST /vendors/_seed           → tohumla (idempotent)
  POST /vendors/_seed?force=1   → mevcut profilleri güncelle (kg/m fix vs.)
"""
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Query
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.models.user import User
from app.models.company_settings import CompanySettings
from app.models.vendor import Vendor, VendorSystem, VendorProfile
from app.core.dependencies import get_current_active_user

router = APIRouter()


def _vendor_to_dict(v: Vendor) -> dict:
    return {
        "id": v.id,
        "slug": v.slug,
        "name": v.name,
        "logo_url": v.logo_url,
        "website": v.website,
        "is_default": v.is_default,
        "is_active": v.is_active,
        "is_custom": v.owner_company_id is not None,
        "system_count": len(v.systems) if v.systems else 0,
    }


def _system_to_dict(s: VendorSystem) -> dict:
    return {
        "id": s.id,
        "vendor_id": s.vendor_id,
        "category": s.category,
        "sub_category": s.sub_category,
        "name": s.name,
        "code_prefix": s.code_prefix,
        "profile_length_mm": s.profile_length_mm,
        "is_active": s.is_active,
        "profile_count": len(s.profiles) if s.profiles else 0,
    }


def _profile_to_dict(p: VendorProfile) -> dict:
    return {
        "id": p.id,
        "code": p.code,
        "name": p.name,
        "role": p.role,
        "kg_per_m": p.kg_per_m,
        "dimensions": p.dimensions,
        "notes": p.notes,
        "sort_order": p.sort_order,
    }


# ── PUBLİK / KULLANICI ──────────────────────────────────────────────
@router.get("")
def list_vendors(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Şirketin görebileceği tüm vendor'lar — publike + kendi özel'i."""
    vendors = (
        db.query(Vendor)
        .filter(
            Vendor.is_active == True,
            (Vendor.owner_company_id == None) | (Vendor.owner_company_id == current_user.company_id),
        )
        .order_by(Vendor.is_default.desc(), Vendor.name.asc())
        .all()
    )
    return {"vendors": [_vendor_to_dict(v) for v in vendors]}


@router.get("/{slug}/systems")
def list_vendor_systems(
    slug: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    vendor = db.query(Vendor).filter(Vendor.slug == slug, Vendor.is_active == True).first()
    if not vendor:
        raise HTTPException(404, "Vendor bulunamadı")
    if vendor.owner_company_id is not None and vendor.owner_company_id != current_user.company_id:
        raise HTTPException(403, "Bu vendor sana ait değil")
    return {
        "vendor": _vendor_to_dict(vendor),
        "systems": [_system_to_dict(s) for s in vendor.systems if s.is_active],
    }


@router.get("/{slug}/systems/{sub_category}/profiles")
def list_system_profiles(
    slug: str,
    sub_category: str,
    category: str = Query("giyotin"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    vendor = db.query(Vendor).filter(Vendor.slug == slug, Vendor.is_active == True).first()
    if not vendor:
        raise HTTPException(404, "Vendor bulunamadı")
    if vendor.owner_company_id is not None and vendor.owner_company_id != current_user.company_id:
        raise HTTPException(403)
    system = (
        db.query(VendorSystem)
        .filter(
            VendorSystem.vendor_id == vendor.id,
            VendorSystem.category == category,
            VendorSystem.sub_category == sub_category,
        )
        .first()
    )
    if not system:
        raise HTTPException(404, f"Sistem bulunamadı: {category}/{sub_category}")
    profiles = (
        db.query(VendorProfile)
        .filter(VendorProfile.system_id == system.id)
        .order_by(VendorProfile.sort_order.asc(), VendorProfile.code.asc())
        .all()
    )
    return {
        "vendor": _vendor_to_dict(vendor),
        "system": _system_to_dict(system),
        "profiles": [_profile_to_dict(p) for p in profiles],
    }


# ── ŞİRKETİN AKTİF SEÇİMİ ───────────────────────────────────────────
class SetActiveVendorRequest(BaseModel):
    vendor_slug: str
    sub_category: Optional[str] = None   # sistem alt-türü (klasik/silinebilir vs.)


@router.get("/my-active")
def get_my_active_vendor(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Şirketin aktif vendor + sistem tercihini döner."""
    settings = (
        db.query(CompanySettings)
        .filter(CompanySettings.company_id == current_user.company_id)
        .first()
    )
    # Tercih yoksa default vendor'ı dön
    slug = None
    sub = None
    if settings and getattr(settings, "preferred_vendor_slug", None):
        slug = settings.preferred_vendor_slug
        sub = getattr(settings, "preferred_vendor_subcategory", None)
    if not slug:
        default = db.query(Vendor).filter(Vendor.is_default == True, Vendor.is_active == True).first()
        if default:
            slug = default.slug
    if not slug:
        return {"vendor": None, "system": None}
    vendor = db.query(Vendor).filter(Vendor.slug == slug).first()
    if not vendor:
        return {"vendor": None, "system": None}
    system = None
    if sub:
        system = (
            db.query(VendorSystem)
            .filter(VendorSystem.vendor_id == vendor.id, VendorSystem.sub_category == sub)
            .first()
        )
    if not system and vendor.systems:
        # ilk sistem
        system = next((s for s in vendor.systems if s.is_active), vendor.systems[0])
    return {
        "vendor": _vendor_to_dict(vendor),
        "system": _system_to_dict(system) if system else None,
    }


@router.put("/my-active")
def set_my_active_vendor(
    req: SetActiveVendorRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    if not current_user.is_company_admin:
        raise HTTPException(403, "Bu işlem sadece şirket yöneticisi tarafından yapılabilir.")
    vendor = db.query(Vendor).filter(Vendor.slug == req.vendor_slug, Vendor.is_active == True).first()
    if not vendor:
        raise HTTPException(404, "Vendor bulunamadı")
    if vendor.owner_company_id is not None and vendor.owner_company_id != current_user.company_id:
        raise HTTPException(403, "Bu vendor sana ait değil")
    settings = (
        db.query(CompanySettings)
        .filter(CompanySettings.company_id == current_user.company_id)
        .first()
    )
    if not settings:
        settings = CompanySettings(company_id=current_user.company_id)
        db.add(settings)
    settings.preferred_vendor_slug = req.vendor_slug
    settings.preferred_vendor_subcategory = req.sub_category
    db.commit()
    return {"message": "Tedarikçi tercihi güncellendi", "vendor_slug": req.vendor_slug,
            "sub_category": req.sub_category}


# ── CUSTOM VENDOR — kullanıcı kendi tedarikçisini ekler ──────────────
class CustomVendorRequest(BaseModel):
    name: str                               # "Murat Alüminyum"
    system_name: str = "Klasik Giyotin"     # vendor'ın tek bir başlangıç sistemi olur
    code_prefix: Optional[str] = None       # "M-" gibi
    profile_length_mm: float = 6500


@router.post("/custom")
def create_custom_vendor(
    req: CustomVendorRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Kullanıcının kendi atölyesi için özel vendor oluşturur. Sadece o şirket görür."""
    if not current_user.is_company_admin:
        raise HTTPException(403, "Bu işlem için şirket yöneticisi olmalısın.")

    # Slug: company_id + name'den üret, çakışma engelle
    import re
    base_slug = re.sub(r'[^a-z0-9]+', '-', req.name.lower().strip()).strip('-')[:30]
    if not base_slug:
        base_slug = "ozel"
    slug = f"co{current_user.company_id}-{base_slug}"
    # Çakışma kontrolü
    cnt = 2
    final_slug = slug
    while db.query(Vendor).filter(Vendor.slug == final_slug).first():
        final_slug = f"{slug}-{cnt}"
        cnt += 1

    vendor = Vendor(
        slug=final_slug, name=req.name,
        owner_company_id=current_user.company_id,
        is_active=True, is_default=False,
    )
    db.add(vendor)
    db.flush()

    system = VendorSystem(
        vendor_id=vendor.id,
        category="giyotin", sub_category="klasik",
        name=req.system_name,
        code_prefix=req.code_prefix,
        profile_length_mm=req.profile_length_mm,
        is_active=True,
    )
    db.add(system)
    db.commit()
    db.refresh(vendor)
    db.refresh(system)

    return {
        "vendor": _vendor_to_dict(vendor),
        "system": _system_to_dict(system),
        "message": "Özel tedarikçi oluşturuldu. Şimdi profilleri ekleyebilirsin.",
    }


class CustomProfilesBulkRequest(BaseModel):
    csv_text: str
    replace: bool = False


@router.post("/custom/systems/{system_id}/profiles/bulk")
def custom_profiles_bulk(
    system_id: int,
    req: CustomProfilesBulkRequest,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    """Kullanıcının kendi vendor'ına toplu profil ekler. Sahiplik kontrol edilir."""
    system = db.query(VendorSystem).filter(VendorSystem.id == system_id).first()
    if not system:
        raise HTTPException(404, "Sistem bulunamadı")
    if system.vendor.owner_company_id != current_user.company_id:
        raise HTTPException(403, "Bu sistem senin değil.")

    import csv as csvmod
    import io as iomod
    text = req.csv_text.strip()
    first_line = text.split("\n")[0]
    delim = "\t" if "\t" in first_line else (";" if ";" in first_line and "," not in first_line else ",")
    reader = csvmod.DictReader(iomod.StringIO(text), delimiter=delim)

    if req.replace:
        db.query(VendorProfile).filter(VendorProfile.system_id == system_id).delete()
        db.commit()

    added = 0
    updated = 0
    errors = []
    for idx, row in enumerate(reader, start=2):
        try:
            code = (row.get("code") or "").strip()
            if not code:
                continue
            kg = float((row.get("kg_per_m") or "0").replace(",", ".").strip())
            name = (row.get("name") or code).strip()
            role = (row.get("role") or "").strip() or None
            sort_order = int(row.get("sort_order") or 0)
            existing = db.query(VendorProfile).filter(
                VendorProfile.system_id == system_id,
                VendorProfile.code == code,
            ).first()
            if existing:
                existing.name = name
                existing.role = role
                existing.kg_per_m = kg
                existing.sort_order = sort_order
                updated += 1
            else:
                db.add(VendorProfile(
                    system_id=system_id, code=code, name=name,
                    role=role, kg_per_m=kg, sort_order=sort_order,
                ))
                added += 1
        except Exception as e:
            errors.append({"satir": idx, "hata": str(e)[:120]})
    db.commit()
    return {"added": added, "updated": updated, "errors": errors}


@router.delete("/custom/{vendor_id}")
def delete_custom_vendor(
    vendor_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    v = db.query(Vendor).filter(Vendor.id == vendor_id).first()
    if not v:
        raise HTTPException(404)
    if v.owner_company_id != current_user.company_id:
        raise HTTPException(403, "Bu vendor senin değil.")
    db.delete(v)
    db.commit()
    return {"message": "Özel tedarikçi silindi"}


# ── ADMIN ───────────────────────────────────────────────────────────
@router.post("/_seed")
def seed_vendors_endpoint(
    force: bool = Query(False),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_active_user),
):
    if not current_user.is_superuser:
        raise HTTPException(403, "Sadece superadmin")
    from app.core.vendor_seed import seed_vendors
    result = seed_vendors(db, force=force)
    return result
