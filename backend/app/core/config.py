from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    """
    Uygulama ayarlarını yöneten merkezi sınıf.
    Pydantic-settings, DATABASE_URL ve SECRET_KEY isimli ortam değişkenlerini
    otomatik olarak algılar ve bu alanlara atar.
    """
    # Tip belirterek otomatik validasyon sağlıyoruz
    DATABASE_URL: str
    SECRET_KEY: str
    
    # Diğer genel ayarlar
    PROJECT_NAME: str = "Kavira Giyotin SaaS"
    API_V1_STR: str = "/api/v1"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60 * 24 * 7 # 7 Gün

    # E-posta Ayarları (SMTP)
    MAIL_USERNAME: str = "your_email@gmail.com"
    MAIL_PASSWORD: str = "your_app_password"
    MAIL_FROM: str = "your_email@gmail.com"
    MAIL_PORT: int = 587
    MAIL_SERVER: str = "smtp.gmail.com"
    MAIL_FROM_NAME: str = "Kavira SaaS"
    MAIL_STARTTLS: bool = True
    MAIL_SSL_TLS: bool = False

    # Iyzico Ayarları
    IYZICO_API_KEY: str = "iyzico_api_keyiniz"
    IYZICO_SECRET_KEY: str = "iyzico_secret_keyiniz"
    IYZICO_BASE_URL: str = "https://sandbox-api.iyzipay.com"
    IYZICO_WEBHOOK_SECRET: str = "cok_gizli_webhook_anahtari_2026"

    # Pydantic v2 Yapılandırması
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=True        # Ortam değişkenlerinde büyük/küçük harf duyarlılığı
    )

# Ayarlar doğrudan .env dosyasından okunacak şekilde başlatılıyor
settings = Settings()