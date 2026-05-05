"""Usuario API routes."""
from fastapi import APIRouter, Depends, HTTPException, status

from app.auth.dependencies import get_current_user_token
from app.usuario.schemas import User, UserCreate, UserUpdate
from app.usuario.mock_store import UsuarioMockStore


def create_usuario_router(usuario_store: UsuarioMockStore) -> APIRouter:
    """Create usuario router with injected store."""

    router = APIRouter(
        prefix="/usuarios",
        tags=["usuarios"],
    )

    @router.post("/", response_model=User)
    async def create_usuario(
        usuario: UserCreate,
        _: dict = Depends(get_current_user_token),  # Require auth
    ):
        """Create a new user (admin only)."""
        return await usuario_store.create_usuario(usuario)

    @router.get("/", response_model=list[User])
    async def list_usuarios(
        skip: int = 0,
        limit: int = 100,
        _: dict = Depends(get_current_user_token),
    ):
        """List all users."""
        return await usuario_store.list_usuarios(skip, limit)

    @router.get("/{user_id}", response_model=User)
    async def get_usuario(
        user_id: str,
        _: dict = Depends(get_current_user_token),
    ):
        """Get a specific user."""
        user = await usuario_store.get_usuario(user_id)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found",
            )
        return user

    @router.put("/{user_id}", response_model=User)
    async def update_usuario(
        user_id: str,
        updates: UserUpdate,
        _: dict = Depends(get_current_user_token),
    ):
        """Update a user."""
        updates_dict = updates.dict(exclude_unset=True)
        user = await usuario_store.update_usuario(user_id, updates_dict)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found",
            )
        return user

    @router.delete("/{user_id}")
    async def delete_usuario(
        user_id: str,
        _: dict = Depends(get_current_user_token),
    ):
        """Delete a user."""
        success = await usuario_store.delete_usuario(user_id)
        if not success:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="User not found",
            )
        return {"message": "User deleted"}

    return router
