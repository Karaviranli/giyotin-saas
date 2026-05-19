from pydantic_settings import BaseSettings
import os

class Settings(BaseSettings):
    # Bu değerler docker-compose.yml dosyasındaki environment kısmından otomatik okunacak
    DATABASE_URL: str = os.getenv("DATABASE_URL", "postgresql://kavira_admin:supersecretpassword@db:5432/kavira_saas")
    SECRET_KEY: str = os.getenv("SECRET_KEY", "kavira_cok_gizli_jwt_anahtari_2026")

    class Config:
        env_file = ".env"

# İşte hata veren 'settings' değişkeni burada!
settings = Settings()