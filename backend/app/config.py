"""Ortam değişkenlerinden okunan ayarlar (.env.example dosyasına bakın)."""

import secrets
from functools import lru_cache

from pydantic import Field, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    environment: str = Field("development", description="development | production | test")
    secret_key: str = ""
    database_url: str = "sqlite:///./skinsavvy.db"

    access_token_minutes: int = 15
    refresh_token_days: int = 30

    # Virgülle ayrılmış izinli kökenler (Flutter web demosu, yerel geliştirme).
    cors_origins: str = "https://melisayalcinkaya.github.io,http://localhost:8080,http://127.0.0.1:8080"

    # Açılışta demo kataloğu ve demo hesabı yüklensin mi?
    seed_demo: bool = True
    demo_email: str = "demo@skinsavvy.app"
    demo_password: str = "demo-sifre-2026"  # noqa: S105 - README'de herkese açık demo şifresi

    # Yönetici hesabı yalnızca ortam değişkeniyle oluşturulur; şifre depoda yok.
    admin_email: str = ""
    admin_password: str = ""

    # Ters vekil (Render vb.) arkasındaysa istemci IP'si X-Forwarded-For'dan okunur.
    # Doğrudan internete açıkken açılmamalı: başlık sahtelenebilir.
    trust_forwarded_for: bool = False

    # Ürün görseli (data URL) için üst sınır.
    max_image_bytes: int = 512 * 1024

    @model_validator(mode="after")
    def _check_secret(self) -> "Settings":
        if not self.secret_key:
            if self.environment == "production":
                raise ValueError("SECRET_KEY production ortamında zorunludur.")
            # Geliştirmede her açılışta yeni anahtar: token'lar yeniden başlatınca geçersiz olur.
            self.secret_key = secrets.token_urlsafe(48)
        elif self.environment == "production" and len(self.secret_key) < 32:
            raise ValueError("SECRET_KEY en az 32 karakter olmalı.")
        return self

    @property
    def cors_origin_list(self) -> list[str]:
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
