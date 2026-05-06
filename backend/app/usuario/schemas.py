"""User schemas (Pydantic models)."""
from typing import Optional

from pydantic import BaseModel, EmailStr


class UserBase(BaseModel):
    """Base user schema."""

    email: EmailStr
    role: str = "usuario"


class UserCreate(UserBase):
    """Schema for creating a user."""

    password: str
    nombre_completo: Optional[str] = None
    telefono: Optional[str] = None
    ciudad_id: Optional[int] = None


class UserLogin(BaseModel):
    """Schema for login."""

    email: EmailStr
    password: str


class User(UserBase):
    """User response schema."""

    id: str
    status: str
    nombre_completo: Optional[str] = None
    telefono: Optional[str] = None
    puntos_reputacion: int = 0
    es_premium: bool = False
    ciudad_id: Optional[int] = None
    ciudad: Optional[str] = None
    region_id: Optional[int] = None
    region: Optional[str] = None

    class Config:
        from_attributes = True


class UserUpdate(BaseModel):
    """Schema for updating a user."""

    email: Optional[EmailStr] = None
    role: Optional[str] = None
    status: Optional[str] = None
    nombre_completo: Optional[str] = None
    telefono: Optional[str] = None
    ciudad_id: Optional[int] = None


class AuthResponse(BaseModel):
    """Authentication response."""

    access_token: str
    token_type: str = "bearer"
    user: User
