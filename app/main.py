from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.db.database import engine
from app.db.base import Base

# Router'ları içe aktar (Henüz router'ları api klasörüne bağlamadıysan hata verebilir, 
# ama biz api.py içinde giyotin router'ını bağlamıştık)
from app.api.v1.api import api_router

# Veritabanı tablolarını otomatik oluştur (Alembic kullanana kadar en pratik yol budur)
Base.metadata.create_all(bind=engine)

app = FastAPI(
    title="Kavira SaaS API",
    description="Giyotin Maliyet ve Kesim Optimizasyon Sistemi",
    version="1.0.0"
)

# Frontend'in (Flutter Web/Mobil) backend'e erişebilmesi için CORS ayarları
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # Prod ortamında buraya sadece kendi domainini yazmalısın
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Endpointleri uygulamaya dahil et
app.include_router(api_router, prefix="/api/v1")

@app.get("/")
def read_root():
    return {"message": "Kavira SaaS API Çalışıyor! Starta basıldı."}