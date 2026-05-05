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


class UserLogin(BaseModel):
    """Schema for login."""

    email: EmailStr
    password: str


class User(UserBase):
    """User response schema."""

    id: str
    status: str

    class Config:
        from_attributes = True


class UserUpdate(BaseModel):
    """Schema for updating a user."""

    email: Optional[EmailStr] = None
    role: Optional[str] = None
    status: Optional[str] = None


class AuthResponse(BaseModel):
    """Authentication response."""

    access_token: str
    token_type: str = "bearer"
    user: User
