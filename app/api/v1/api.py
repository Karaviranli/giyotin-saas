from fastapi import APIRouter
from app.api.v1.endpoints import giyotin

api_router = APIRouter()
api_router.include_router(giyotin.router, prefix="/giyotin", tags=["Giyotin Hesaplama"])