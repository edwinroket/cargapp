"""Mock user store for development without database."""
from typing import Dict, Optional

from app.auth.passwords import hash_password, verify_password
from app.usuario.schemas import User, UserCreate


class UsuarioMockStore:
    """In-memory user store for development."""

    regiones = [
        {"id": 13, "nombre": "Región Metropolitana"},
        {"id": 5, "nombre": "Valparaíso"},
        {"id": 8, "nombre": "Biobío"},
    ]

    ciudades = {
        13: [
            {"id": 13101, "nombre": "Santiago", "region_id": 13},
            {"id": 13119, "nombre": "Maipú", "region_id": 13},
            {"id": 13114, "nombre": "Las Condes", "region_id": 13},
        ],
        5: [
            {"id": 5101, "nombre": "Valparaíso", "region_id": 5},
            {"id": 5109, "nombre": "Viña del Mar", "region_id": 5},
        ],
        8: [
            {"id": 8101, "nombre": "Concepción", "region_id": 8},
            {"id": 8110, "nombre": "Talcahuano", "region_id": 8},
        ],
    }

    def __init__(self):
        """Initialize with sample data."""
        self.usuarios: Dict[str, dict] = {
            "1": {
                "id": "1",
                "email": "admin@example.com",
                "password_hash": hash_password("admin123"),
                "role": "admin",
                "status": "activo",
                "nombre_completo": "Administrador CargApp",
                "telefono": None,
                "puntos_reputacion": 0,
                "es_premium": True,
                "ciudad_id": 13101,
            },
            "2": {
                "id": "2",
                "email": "user@example.com",
                "password_hash": hash_password("user123"),
                "role": "usuario",
                "status": "activo",
                "nombre_completo": "Usuario Demo",
                "telefono": None,
                "puntos_reputacion": 0,
                "es_premium": False,
                "ciudad_id": 13119,
            },
        }

    async def create_usuario(self, usuario: UserCreate) -> User:
        """Create a new user."""
        user_id = str(max(int(key) for key in self.usuarios.keys()) + 1)
        self.usuarios[user_id] = {
            "id": user_id,
            "email": usuario.email,
            "password_hash": hash_password(usuario.password),
            "role": usuario.role,
            "status": "activo",
            "nombre_completo": usuario.nombre_completo,
            "telefono": usuario.telefono,
            "puntos_reputacion": 0,
            "es_premium": False,
            "ciudad_id": usuario.ciudad_id,
        }
        return await self.get_usuario(user_id)

    async def get_usuario(self, user_id: str) -> Optional[User]:
        """Get user by ID."""
        if user_id not in self.usuarios:
            return None
        user_data = self.usuarios[user_id]
        city = self._get_city(user_data.get("ciudad_id"))
        region = self._get_region(city.get("region_id") if city else None)
        return User(
            id=user_data["id"],
            email=user_data["email"],
            role=user_data["role"],
            status=user_data["status"],
            nombre_completo=user_data.get("nombre_completo"),
            telefono=user_data.get("telefono"),
            puntos_reputacion=user_data.get("puntos_reputacion", 0),
            es_premium=user_data.get("es_premium", False),
            ciudad_id=user_data.get("ciudad_id"),
            ciudad=city.get("nombre") if city else None,
            region_id=region.get("id") if region else None,
            region=region.get("nombre") if region else None,
        )

    async def get_usuario_by_email(self, email: str) -> Optional[User]:
        """Get user by email."""
        for user_data in self.usuarios.values():
            if user_data["email"] == email:
                return await self.get_usuario(user_data["id"])
        return None

    async def authenticate_usuario(
        self, email: str, password: str
    ) -> Optional[User]:
        """Authenticate user with email and password."""
        for user_data in self.usuarios.values():
            if user_data["email"] == email:
                if verify_password(password, user_data["password_hash"]):
                    return await self.get_usuario(user_data["id"])
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

    def _get_city(self, city_id: Optional[int]) -> Optional[dict]:
        if city_id is None:
            return None
        for cities in self.ciudades.values():
            for city in cities:
                if city["id"] == city_id:
                    return city
        return None

    def _get_region(self, region_id: Optional[int]) -> Optional[dict]:
        if region_id is None:
            return None
        return next(
            (region for region in self.regiones if region["id"] == region_id),
            None,
        )
