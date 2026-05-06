"""Authentication dependencies and guards."""
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.auth.jwt import decode_token
from app.usuario.schemas import User

security = HTTPBearer()


async def get_current_user_token(
    credentials: HTTPAuthorizationCredentials = Depends(security),
) -> dict:
    """Extract and validate user from JWT token."""
    token = credentials.credentials
    payload = decode_token(token)

    if payload is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
            headers={"WWW-Authenticate": "Bearer"},
        )
    return payload


def require_roles(allowed_roles: set[str]):
    """Guard that requires specific roles."""

    async def check_role(payload: dict = Depends(get_current_user_token)) -> dict:
        user_id = payload.get("user_id")
        # NOTE: In real implementation, fetch user from store to check role
        # For now, this is a placeholder
        return {"user_id": user_id}

    return Depends(check_role)
