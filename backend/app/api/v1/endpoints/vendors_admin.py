"""
Admin tedarikçi yönetimi — sadece superadmin kullanır.

Endpoint'ler:
  Vendor CRUD:
    POST   /admin/vendors              → yeni vendor (publike)
    PUT    /admin/vendors/{id}         → güncelle
    DELETE /admin/vendors/{id}         → soft delete (is_active=False)

  System CRUD:
    POST   /admin/vendors/{id}/systems → yeni sistem
    PUT    /admin/systems/{id}         → güncelle
    DELETE /admin/systems/{id}         → soft delete

  Profile CRUD:
    POST   /admin/systems/{id}/profiles → yeni profil
    PUT    /admin/profiles/{id}         → güncelle
    DELETE /admin/profiles/{id}         → sil

  Bulk:
    POST   /admin/systems/{id}/profiles/bulk → CSV/TSV satırları toplu ekle
                                                Format: code,name,role,kg_per_m,sort_order
"""
import csv
import io
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, Body
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session

from app.db.database import get_db
from app.models.user import User
from app.models.vendor import Vendor, VendorSystem, VendorProfile
from app.core.dependencies import get_current_active_user

router = APIRouter()


def _require_super(user: User = Depends(get_current_active_user)) -> User:
    if not user.is_superuser:
        raise HTTPException(403, "Bu işlem için superadmin yetkisi gerekiyor.")
    return user


# ── Modeller ────────────────────────────────────────────────────────
class VendorCreate(BaseModel):
    slug: str = Field(..., min_length=2, max_length=40)
    name: str = Field(..., min_length=2, max_length=120)
    website: Optional[str] = None
    logo_url: Optional[str] = None
    is_default: bool = False


class VendorUpdate(BaseModel):
    name: Optional[str] = None
    website: Optional[str] = None
    logo_url: Optional[str] = None
    is_default: Optional[bool] = None
    is_active: Optional[bool] = None


class SystemCreate(BaseModel):
    category: str = "giyotin"
    sub_category: Optional[str] = None
    name: str
    code_prefix: Optional[str] = None
    profile_length_mm: float = 6500


class SystemUpdate(BaseModel):
    category: Optional[str] = None
    sub_category: Optional[str] = None
    name: Optional[str] = None
    code_prefix: Optional[str] = None
    profile_length_mm: Optional[float] = None
    is_active: Optional[bool] = None


class ProfileCreate(BaseModel):
    code: str
    name: str
    role: Optional[str] = None
    kg_per_m: float
    dimensions: Optional[dict] = None
    notes: Optional[str] = None
    sort_order: int = 0


class ProfileUpdate(BaseModel):
    code: Optional[str] = None
    name: Optional[str] = None
    role: Optional[str] = None
    kg_per_m: Optional[float] = None
    dimensions: Optional[dict] = None
    notes: Optional[str] = None
    sort_order: Optional[int] = None


class BulkProfilesRequest(BaseModel):
    """CSV/TSV içeriği veya satır listesi.
    csv_text: 'code,name,role,kg_per_m,sort_order' başlığı ile satırlar.
    """
    csv_text: str
    replace: bool = False   # True → mevcut profilleri silip baştan ekle


# ── VENDOR CRUD ─────────────────────────────────────────────────────
@router.post("/vendors")
def create_vendor(req: VendorCreate, db: Session = Depends(get_db), _: User = Depends(_require_super)):
    existing = db.query(Vendor).filter(Vendor.slug == req.slug).first()
    if existing:
        raise HTTPException(400, f"Slug zaten kullanılıyor: {req.slug}")
    if req.is_default:
        # tek default — diğerlerini False yap
        db.query(Vendor).filter(Vendor.is_default == True).update({Vendor.is_default: False})
    v = Vendor(
        slug=req.slug, name=req.name,
        website=req.website, logo_url=req.logo_url,
        is_default=req.is_default, is_active=True,
        owner_company_id=None,
    )
    db.add(v)
    db.commit()
    db.refresh(v)
    return {"id": v.id, "slug": v.slug, "name": v.name, "message": "Tedarikçi oluşturuldu"}


@router.put("/vendors/{vendor_id}")
def update_vendor(vendor_id: int, req: VendorUpdate, db: Session = Depends(get_db), _: User = Depends(_require_super)):
    v = db.query(Vendor).filter(Vendor.id == vendor_id).first()
    if not v:
        raise HTTPException(404, "Tedarikçi bulunamadı")
    if req.is_default == True and not v.is_default:
        db.query(Vendor).filter(Vendor.is_default == True).update({Vendor.is_default: False})
    for field in ["name", "website", "logo_url", "is_default", "is_active"]:
        val = getattr(req, field)
        if val is not None:
            setattr(v, field, val)
    db.commit()
    return {"message": "Güncellendi"}


@router.delete("/vendors/{vendor_id}")
def delete_vendor(vendor_id: int, db: Session = Depends(get_db), _: User = Depends(_require_super)):
    v = db.query(Vendor).filter(Vendor.id == vendor_id).first()
    if not v:
        raise HTTPException(404, "Tedarikçi bulunamadı")
    v.is_active = False
    db.commit()
    return {"message": "Devre dışı bırakıldı (soft delete)"}


# ── SYSTEM CRUD ─────────────────────────────────────────────────────
@router.post("/vendors/{vendor_id}/systems")
def create_system(vendor_id: int, req: SystemCreate, db: Session = Depends(get_db), _: User = Depends(_require_super)):
    v = db.query(Vendor).filter(Vendor.id == vendor_id).first()
    if not v:
        raise HTTPException(404, "Tedarikçi bulunamadı")
    s = VendorSystem(
        vendor_id=vendor_id,
        category=req.category, sub_category=req.sub_category,
        name=req.name, code_prefix=req.code_prefix,
        profile_length_mm=req.profile_length_mm, is_active=True,
    )
    db.add(s)
    db.commit()
    db.refresh(s)
    return {"id": s.id, "name": s.name}


@router.put("/systems/{system_id}")
def update_system(system_id: int, req: SystemUpdate, db: Session = Depends(get_db), _: User = Depends(_require_super)):
    s = db.query(VendorSystem).filter(VendorSystem.id == system_id).first()
    if not s:
        raise HTTPException(404, "Sistem bulunamadı")
    for f in ["category", "sub_category", "name", "code_prefix", "profile_length_mm", "is_active"]:
        val = getattr(req, f)
        if val is not None:
            setattr(s, f, val)
    db.commit()
    return {"message": "Güncellendi"}


@router.delete("/systems/{system_id}")
def delete_system(system_id: int, db: Session = Depends(get_db), _: User = Depends(_require_super)):
    s = db.query(VendorSystem).filter(VendorSystem.id == system_id).first()
    if not s:
        raise HTTPException(404)
    s.is_active = False
    db.commit()
    return {"message": "Sistem devre dışı"}


# ── PROFILE CRUD ────────────────────────────────────────────────────
@router.post("/systems/{system_id}/profiles")
def create_profile(system_id: int, req: ProfileCreate, db: Session = Depends(get_db), _: User = Depends(_require_super)):
    s = db.query(VendorSystem).filter(VendorSystem.id == system_id).first()
    if not s:
        raise HTTPException(404, "Sistem bulunamadı")
    existing = db.query(VendorProfile).filter(
        VendorProfile.system_id == system_id,
        VendorProfile.code == req.code,
    ).first()
    if existing:
        raise HTTPException(400, f"Kod zaten var: {req.code}")
    p = VendorProfile(
        system_id=system_id, code=req.code, name=req.name,
        role=req.role, kg_per_m=req.kg_per_m, dimensions=req.dimensions,
        notes=req.notes, sort_order=req.sort_order,
    )
    db.add(p)
    db.commit()
    db.refresh(p)
    return {"id": p.id, "code": p.code, "name": p.name}


@router.put("/profiles/{profile_id}")
def update_profile(profile_id: int, req: ProfileUpdate, db: Session = Depends(get_db), _: User = Depends(_require_super)):
    p = db.query(VendorProfile).filter(VendorProfile.id == profile_id).first()
    if not p:
        raise HTTPException(404, "Profil bulunamadı")
    for f in ["code", "name", "role", "kg_per_m", "dimensions", "notes", "sort_order"]:
        val = getattr(req, f)
        if val is not None:
            setattr(p, f, val)
    db.commit()
    return {"message": "Güncellendi"}


@router.delete("/profiles/{profile_id}")
def delete_profile(profile_id: int, db: Session = Depends(get_db), _: User = Depends(_require_super)):
    p = db.query(VendorProfile).filter(VendorProfile.id == profile_id).first()
    if not p:
        raise HTTPException(404)
    db.delete(p)
    db.commit()
    return {"message": "Silindi"}


# ── BULK CSV ────────────────────────────────────────────────────────
@router.post("/systems/{system_id}/profiles/bulk")
def bulk_profiles(system_id: int, req: BulkProfilesRequest,
                  db: Session = Depends(get_db), _: User = Depends(_require_super)):
    """CSV/TSV ile toplu profil ekleme.

    Format (ilk satır başlık):
      code,name,role,kg_per_m,sort_order
      K-1401,Motor Kutusu Alt,MOTOR_KUTUSU_ALT,1.293,0
      K-1402,Motor Kutusu Üst,MOTOR_KUTUSU_UST,0.669,1
    """
    s = db.query(VendorSystem).filter(VendorSystem.id == system_id).first()
    if not s:
        raise HTTPException(404, "Sistem bulunamadı")

    text = req.csv_text.strip()
    # TSV mi CSV mi otomatik tespit
    delim = "\t" if "\t" in text.split("\n")[0] else (";" if ";" in text.split("\n")[0] and "," not in text.split("\n")[0] else ",")
    reader = csv.DictReader(io.StringIO(text), delimiter=delim)

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


# ── DETAY (tek vendor için tam ağaç) ────────────────────────────────
@router.get("/vendors/{vendor_id}/detail")
def vendor_detail(vendor_id: int, db: Session = Depends(get_db), _: User = Depends(_require_super)):
    v = db.query(Vendor).filter(Vendor.id == vendor_id).first()
    if not v:
        raise HTTPException(404)
    systems_out = []
    for s in v.systems:
        profs = db.query(VendorProfile).filter(VendorProfile.system_id == s.id)\
            .order_by(VendorProfile.sort_order.asc(), VendorProfile.code.asc()).all()
        systems_out.append({
            "id": s.id,
            "category": s.category, "sub_category": s.sub_category,
            "name": s.name, "code_prefix": s.code_prefix,
            "profile_length_mm": s.profile_length_mm, "is_active": s.is_active,
            "profiles": [
                {
                    "id": p.id, "code": p.code, "name": p.name,
                    "role": p.role, "kg_per_m": p.kg_per_m,
                    "dimensions": p.dimensions, "notes": p.notes,
                    "sort_order": p.sort_order,
                }
                for p in profs
            ],
        })
    return {
        "id": v.id, "slug": v.slug, "name": v.name,
        "website": v.website, "logo_url": v.logo_url,
        "is_default": v.is_default, "is_active": v.is_active,
        "systems": systems_out,
    }
