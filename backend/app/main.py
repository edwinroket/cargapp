"""Main FastAPI application factory."""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.health import router as health_router
from app.api.auth import create_auth_router
from app.api.usuario import create_usuario_router
from app.usuario.mock_store import UsuarioMockStore
from app.usuario.sql_store import UsuarioSqlStore
from app.db.session import SessionLocal


def create_app() -> FastAPI:
    """Create and configure FastAPI application."""

    app = FastAPI(
        title="CargApp API",
        description="Sistema de gestión de estaciones de carga",
        version="0.1.0",
        debug=settings.DEBUG,
    )

    # Add CORS middleware
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.CORS_ORIGINS,
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    # Factory Pattern: Decide between Mock and SQL store
    if settings.DATA_STORE == "mock":
        usuario_store = UsuarioMockStore()
    else:
        db_session = SessionLocal()
        usuario_store = UsuarioSqlStore(db_session)

    # Include routers
    app.include_router(health_router)
    app.include_router(create_auth_router(usuario_store))
    app.include_router(create_usuario_router(usuario_store))

    # TODO: Include more routers
    # app.include_router(create_vehiculo_router(vehiculo_store))
    # app.include_router(create_estacion_router(estacion_store))
    # etc.

    return app


app = create_app()
