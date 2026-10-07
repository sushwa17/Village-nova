from pydantic_settings import BaseSettings, SettingsConfigDict
from typing import List


class Settings(BaseSettings):
    PROJECT_NAME: str = "VillageNova Backend API"
    VERSION: str = "1.0.0"
    API_V1_PREFIX: str = "/v1"
    DEBUG: bool = False

    # Supabase Configuration
    SUPABASE_URL: str = "https://udncpejresbvgqksedip.supabase.co"
    SUPABASE_KEY: str = "placeholder-anon-key"
    SUPABASE_SERVICE_ROLE_KEY: str = "placeholder-service-role-key"
    SUPABASE_JWT_SECRET: str = "placeholder-jwt-secret"

    # Database Configuration (PostgreSQL / Supabase connection pooling)
    DATABASE_URL: str = "postgresql+asyncpg://postgres:postgres@localhost:5432/villagenova"

    # AI Configuration (Google Gemini)
    GEMINI_API_KEY: str = "placeholder-gemini-key"
    GEMINI_MODEL: str = "gemini-2.0-flash"

    # Redis Cache Configuration
    REDIS_URL: str = "redis://localhost:6379/0"

    # CORS Allowed Origins
    CORS_ORIGINS: List[str] = ["*"]

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore"
    )


settings = Settings()
