from fastapi import APIRouter

from .endpoints import auth, giyotin

api_router = APIRouter()
api_router.include_router(auth.router, prefix="/auth", tags=["auth"])
api_router.include_router(giyotin.router, prefix="/giyotin", tags=["giyotin"])