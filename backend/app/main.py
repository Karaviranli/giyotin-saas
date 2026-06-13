from fastapi import FastAPI, Request
from fastapi import Depends
from fastapi import HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException
from app.api.v1.api import api_router 
from app.api.v1.endpoints.subscription import router as subscription_router
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.db.database import get_db, engine, Base

# Tabloların veritabanına yansıması için modelleri içe aktarıyoruz
from app.models.user import User
from app.models.company import Company
from app.models.subscription import Subscription
from app.models.vendor import Vendor, VendorSystem, VendorProfile
from app.models.giyotin import GiyotinRecord
from app.models.product_system import ProductSystem
from app.models.company_settings import CompanySettings

# Rate Limiter (SlowAPI)
from slowapi.errors import RateLimitExceeded
from app.core.limiter import limiter

# Veritabanı tablolarını otomatik oluşturur
Base.metadata.create_all(bind=engine)

# İlk açılışta veritabanına varsayılan ayarları yükler/kontrol eder
from app.db.seed import bootstrap_giyotin_settings
bootstrap_giyotin_settings()

# Scheduler'ı (Arka plan görevleri) içe aktar
from app.core.scheduler import start_scheduler

app = FastAPI(
    title="Kavira Giyotin SaaS",
    openapi_url="/api/v1/openapi.json", 
    docs_url="/api/v1/docs"           
)

# Limiter'ı uygulamaya bağla
app.state.limiter = limiter

# FLUTTER İÇİN GÜVENLİK İZNİ (CORS) - Bunu eklemek zorundayız
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "https://kaviragiyotin.com",       # Canlı domaininiz
        "https://www.kaviragiyotin.com",
        "http://localhost:8080",           # Sadece test amaçlı yerel port
        "https://kavira-frontend.vercel.app" # VERCEL'DEN ALDIĞINIZ GERÇEK LİNKİ BURAYA YAZIN
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Rotaları ekle
app.include_router(api_router, prefix="/api/v1")
app.include_router(subscription_router, prefix="/api/v1/subscription", tags=["Subscription"])

# --- Merkezi Hata Yönetimi (Exception Handlers) ---

@app.on_event("startup")
def startup_event():
    """Uygulama ayağa kalktığında arka plan görevlerini başlatır."""
    start_scheduler()

@app.exception_handler(RateLimitExceeded)
async def rate_limit_handler(request: Request, exc: RateLimitExceeded):
    """Çok fazla istek (Brute Force/Spam) atıldığında devreye girer."""
    return JSONResponse(
        status_code=429,
        content={
            "status": "error",
            "detail": "Çok fazla istek gönderdiniz. Lütfen biraz bekleyip tekrar deneyin."
        },
    )

@app.exception_handler(StarletteHTTPException)
async def http_exception_handler(request: Request, exc: StarletteHTTPException):
    """Manuel olarak fırlatılan HTTPException hatalarını yakalar."""
    return JSONResponse(
        status_code=exc.status_code,
        content={
            "status": "error",
            "detail": exc.detail,
            "code": exc.status_code
        },
    )

@app.exception_handler(RequestValidationError)
async def validation_exception_handler(request: Request, exc: RequestValidationError):
    """Pydantic şemalarındaki doğrulama hatalarını yakalar."""
    return JSONResponse(
        status_code=422,
        content={
            "status": "validation_error",
            "detail": "Gönderilen verilerde doğrulama hatası oluştu.",
            "errors": exc.errors() # Detaylı hata listesi
        },
    )

@app.exception_handler(Exception)
async def generic_exception_handler(request: Request, exc: Exception):
    """Beklenmedik uygulama içi çökmeleri (500) yakalar."""
    # Burada loglama yapılabilir: print(f"CRITICAL ERROR: {exc}")
    return JSONResponse(
        status_code=500,
        content={
            "status": "error",
            "detail": "Sunucu tarafında beklenmedik bir sistem hatası oluştu."
        },
    )

@app.get("/")
def read_root():
    return {"message": "Kavira SaaS API Çalışıyor!"}

@app.get("/health")
def health_check():
    return {"status": "Sistem tıkır tıkır çalışıyor!"}

@app.get("/test-db")
def test_db_connection(db: Session = Depends(get_db)):
    try:
        result = db.execute(text("SELECT 1")).scalar()
        return {"status": "Başarılı", "message": "Veritabanına başarıyla bağlanıldı!", "result": result}
    except Exception as e:
        return {"status": "Hata", "message": f"Bağlantı hatası: {str(e)}"}