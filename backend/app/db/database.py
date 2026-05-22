from sqlalchemy import create_engine
from sqlalchemy.orm import declarative_base
from sqlalchemy.orm import sessionmaker
from app.core.config import settings

# os.getenv yerine merkezi settings nesnesini kullanıyoruz
SQLALCHEMY_DATABASE_URL = settings.DATABASE_URL

engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base() # Base burada tanımlanmalı.

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()