"""Mock user store for development without database."""
import uuid
from typing import Dict, Optional

from app.auth.passwords import hash_password, verify_password
from app.usuario.schemas import User, UserCreate


class UsuarioMockStore:
    """In-memory user store for development."""

    def __init__(self):
        """Initialize with sample data."""
        self.usuarios: Dict[str, dict] = {
            "1": {
                "id": "1",
                "email": "admin@example.com",
                "password_hash": hash_password("admin123"),
                "role": "admin",
                "status": "activo",
            },
            "2": {
                "id": "2",
                "email": "user@example.com",
                "password_hash": hash_password("user123"),
                "role": "usuario",
                "status": "activo",
            },
        }

    async def create_usuario(self, usuario: UserCreate) -> User:
        """Create a new user."""
        user_id = str(uuid.uuid4())
        self.usuarios[user_id] = {
            "id": user_id,
            "email": usuario.email,
            "password_hash": hash_password(usuario.password),
            "role": usuario.role,
            "status": "activo",
        }
        return await self.get_usuario(user_id)

    async def get_usuario(self, user_id: str) -> Optional[User]:
        """Get user by ID."""
        if user_id not in self.usuarios:
            return None
        user_data = self.usuarios[user_id]
        return User(
            id=user_data["id"],
            email=user_data["email"],
            role=user_data["role"],
            status=user_data["status"],
        )

    async def get_usuario_by_email(self, email: str) -> Optional[User]:
        """Get user by email."""
        for user_data in self.usuarios.values():
            if user_data["email"] == email:
                return User(
                    id=user_data["id"],
                    email=user_data["email"],
                    role=user_data["role"],
                    status=user_data["status"],
                )
        return None

    async def authenticate_usuario(
        self, email: str, password: str
    ) -> Optional[User]:
        """Authenticate user with email and password."""
        for user_data in self.usuarios.values():
            if user_data["email"] == email:
                if verify_password(password, user_data["password_hash"]):
                    return User(
                        id=user_data["id"],
                        email=user_data["email"],
                        role=user_data["role"],
                        status=user_data["status"],
                    )
        return None

    async def list_usuarios(self, skip: int = 0, limit: int = 100) -> list[User]:
        """List all users."""
        users = []
        for user_data in list(self.usuarios.values())[skip : skip + limit]:
            users.append(
                User(
                    id=user_data["id"],
                    email=user_data["email"],
                    role=user_data["role"],
                    status=user_data["status"],
                )
            )
        return users

    async def update_usuario(self, user_id: str, updates: dict) -> Optional[User]:
        """Update user."""
        if user_id not in self.usuarios:
            return None
        self.usuarios[user_id].update(updates)
        return await self.get_usuario(user_id)

    async def delete_usuario(self, user_id: str) -> bool:
        """Delete user."""
        if user_id in self.usuarios:
            del self.usuarios[user_id]
            return True
        return False
