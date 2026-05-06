"""SQL user store using SQLAlchemy."""
from typing import Optional

from sqlalchemy.orm import Session

from app.auth.passwords import hash_password, verify_password
from app.db.models import UserModel
from app.usuario.schemas import User, UserCreate


class UsuarioSqlStore:
    """User store with SQL persistence."""

    def __init__(self, db_session: Session):
        """Initialize with database session."""
        self.db = db_session

    async def create_usuario(self, usuario: UserCreate) -> User:
        """Create a new user."""
        user_model = UserModel(
            id=usuario.id if hasattr(usuario, "id") else None,
            email=usuario.email,
            password_hash=hash_password(usuario.password),
            role=usuario.role,
            status="activo",
        )
        self.db.add(user_model)
        self.db.commit()
        self.db.refresh(user_model)
        return self._model_to_schema(user_model)

    async def get_usuario(self, user_id: str) -> Optional[User]:
        """Get user by ID."""
        user_model = self.db.query(UserModel).filter(UserModel.id == user_id).first()
        if not user_model:
            return None
        return self._model_to_schema(user_model)

    async def get_usuario_by_email(self, email: str) -> Optional[User]:
        """Get user by email."""
        user_model = (
            self.db.query(UserModel).filter(UserModel.email == email).first()
        )
        if not user_model:
            return None
        return self._model_to_schema(user_model)

    async def authenticate_usuario(
        self, email: str, password: str
    ) -> Optional[User]:
        """Authenticate user with email and password."""
        user_model = (
            self.db.query(UserModel).filter(UserModel.email == email).first()
        )
        if not user_model:
            return None
        if not verify_password(password, user_model.password_hash):
            return None
        return self._model_to_schema(user_model)

    async def list_usuarios(self, skip: int = 0, limit: int = 100) -> list[User]:
        """List all users."""
        user_models = (
            self.db.query(UserModel).offset(skip).limit(limit).all()
        )
        return [self._model_to_schema(u) for u in user_models]

    async def update_usuario(self, user_id: str, updates: dict) -> Optional[User]:
        """Update user."""
        user_model = self.db.query(UserModel).filter(UserModel.id == user_id).first()
        if not user_model:
            return None
        for key, value in updates.items():
            if hasattr(user_model, key):
                setattr(user_model, key, value)
        self.db.commit()
        self.db.refresh(user_model)
        return self._model_to_schema(user_model)

    async def delete_usuario(self, user_id: str) -> bool:
        """Delete user."""
        user_model = self.db.query(UserModel).filter(UserModel.id == user_id).first()
        if not user_model:
            return False
        self.db.delete(user_model)
        self.db.commit()
        return True

    @staticmethod
    def _model_to_schema(user_model: UserModel) -> User:
        """Convert UserModel to User schema."""
        return User(
            id=user_model.id,
            email=user_model.email,
            role=user_model.role,
            status=user_model.status,
        )
