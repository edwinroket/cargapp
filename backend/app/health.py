"""Health check endpoint."""
from fastapi import APIRouter

router = APIRouter()


@router.get("/health", tags=["health"])
async def health_check():
    """Health check endpoint."""
    return {
        "status": "ok",
        "service": "cargapp-api",
        "version": "0.1.0",
    }
