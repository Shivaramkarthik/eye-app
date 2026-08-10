from typing import List, Union
from pydantic import AnyHttpUrl, validator
from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    ENVIRONMENT: str = "development"
    DEBUG: bool = True
    API_V1_STR: str = "/api/v1"
    PROJECT_NAME: str = "Specz.co V2 API"

    # Database
    DATABASE_URL: str = "postgresql+asyncpg://specz_user:specz_password@localhost:5432/specz_db"
    SYNC_DATABASE_URL: str = "postgresql://specz_user:specz_password@localhost:5432/specz_db"

    # Security / Auth
    JWT_SECRET: str = "dev_jwt_secret_key_specz_co_v2_32_bytes_long"
    REFRESH_TOKEN_SECRET: str = "dev_refresh_secret_key_specz_co_v2_32_bytes"
    ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30

    # Razorpay
    RAZORPAY_KEY_ID: str = "rzp_test_placeholder"
    RAZORPAY_KEY_SECRET: str = "placeholder_secret"
    RAZORPAY_WEBHOOK_SECRET: str = "placeholder_wh_secret"

    # AI Provider
    AI_API_KEY: str = "placeholder_ai_key"

    # S3 Object Storage
    S3_ENDPOINT: str = "https://s3.us-east-1.amazonaws.com"
    S3_BUCKET: str = "specz-medical-storage"
    S3_ACCESS_KEY: str = "placeholder_s3_access_key"
    S3_SECRET_KEY: str = "placeholder_s3_secret_key"
    S3_REGION: str = "us-east-1"

    # Redis
    REDIS_URL: str = "redis://localhost:6379/0"

    # CORS
    CORS_ALLOWED_ORIGINS: List[str] = [
        "http://localhost:3000",
        "http://localhost:8000",
        "https://staging-api.specz.co",
        "https://api.specz.co"
    ]

    model_config = SettingsConfigDict(env_file=".env", case_sensitive=True, extra="ignore")

settings = Settings()
