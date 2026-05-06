"""Application configuration from environment variables."""
import os
from typing import Literal

from pydantic import field_validator
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Application settings loaded from .env file."""

    # Database
    DATABASE_URL: str = "postgresql://postgres:password@localhost:5432/cargapp"

    # JWT
    JWT_SECRET: str = "your-super-secret-key"
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 30

    # Application
    DEBUG: bool = True
    DATA_STORE: Literal["sql", "mock"] = "mock"

    # CORS
    CORS_ORIGINS: list[str] = ["*"]

    @field_validator("DEBUG", mode="before")
    @classmethod
    def parse_debug(cls, value):
        """Accept bool-like deployment labels from legacy .env files."""
        if isinstance(value, bool):
            return value
        if isinstance(value, str) and value.lower() in {"release", "prod", "production"}:
            return False
        return value

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


settings = Settings()
