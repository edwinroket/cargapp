"""Authentication API routes."""
from datetime import timedelta

from fastapi import APIRouter, HTTPException, status

from app.auth.jwt import create_access_token
from app.config import settings
from app.usuario.mock_store import UsuarioMockStore
from app.usuario.schemas import AuthResponse, UserCreate, UserLogin


def create_auth_router(usuario_store: UsuarioMockStore) -> APIRouter:
    """Create authentication router with injected store."""

    router = APIRouter(
        prefix="/auth",
        tags=["auth"],
    )

    @router.post("/register", response_model=AuthResponse)
    async def register(usuario: UserCreate):
        """Register a new user."""
        # Check if user already exists
        existing = await usuario_store.get_usuario_by_email(usuario.email)
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already registered",
            )

        # Create user
        new_user = await usuario_store.create_usuario(usuario)

        # Generate token
        access_token = create_access_token(
            new_user.id,
            expires_delta=timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES),
        )

        return AuthResponse(
            access_token=access_token,
            user=new_user,
        )

    @router.post("/login", response_model=AuthResponse)
    async def login(credentials: UserLogin):
        """Login user and return JWT token."""
        user = await usuario_store.authenticate_usuario(
            credentials.email,
            credentials.password,
        )

        if not user:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid email or password",
            )

        access_token = create_access_token(
            user.id,
            expires_delta=timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES),
        )

        return AuthResponse(
            access_token=access_token,
            user=user,
        )

    @router.post("/logout")
    async def logout():
        """Logout user (token invalidation handled on client side)."""
        return {"message": "Logged out successfully"}

    return router
