from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.core.config import settings

# Veritabanı URL'sini config'den al
SQLALCHEMY_DATABASE_URL = settings.DATABASE_URL

# Engine oluştur
engine = create_engine(SQLALCHEMY_DATABASE_URL)

# SessionLocal oluştur
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Dependency için get_db fonksiyonu (Bunu ekle ki main.py'dan çağırsın)
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()