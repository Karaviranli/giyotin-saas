from fastapi import APIRouter
from .endpoints import auth, giyotin, promo, admin, vendors, vendors_admin

api_router = APIRouter()
api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(giyotin.router, prefix="/giyotin", tags=["giyotin"])
api_router.include_router(promo.router, prefix="/promo", tags=["promo"])
# Subscription altinda da bir alias — frontend /api/v1/subscription/redeem-promo cagiriyorsa
api_router.include_router(promo.router, prefix="/subscription", tags=["subscription-promo"])
api_router.include_router(admin.router, prefix="/admin", tags=["admin"])
api_router.include_router(vendors.router, prefix="/vendors", tags=["vendors"])
api_router.include_router(vendors_admin.router, prefix="/admin", tags=["vendors-admin"])
