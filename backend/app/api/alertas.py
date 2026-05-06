"""Price alert API routes."""
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel

from app.api.estaciones import COMBUSTIBLES, STATIONS
from app.auth.dependencies import get_current_user_token


ALERTAS: dict[str, list[dict]] = {}


class AlertaCreate(BaseModel):
    """Payload for creating a price alert."""

    tipo_combustible_id: int
    precio_umbral: float
    radio_km: int = 5
    latitud_usuario: Optional[float] = None
    longitud_usuario: Optional[float] = None
    estacion_id: Optional[int] = None


def create_alertas_router() -> APIRouter:
    """Create alert routes."""

    router = APIRouter(prefix="/alertas", tags=["alertas"])

    @router.get("/")
    async def get_alertas(payload: dict = Depends(get_current_user_token)):
        """List alerts for the authenticated user."""
        return ALERTAS.setdefault(payload["user_id"], [])

    @router.post("/", status_code=status.HTTP_201_CREATED)
    async def crear_alerta(
        alerta: AlertaCreate,
        payload: dict = Depends(get_current_user_token),
    ):
        """Create a price alert."""
        user_alerts = ALERTAS.setdefault(payload["user_id"], [])
        fuel = next(
            (
                item["nombre"]
                for item in COMBUSTIBLES
                if item["id"] == alerta.tipo_combustible_id
            ),
            "Combustible",
        )
        station = next(
            (item for item in STATIONS if item["id"] == alerta.estacion_id),
            None,
        )
        new_alert = {
            "id": _next_id(user_alerts),
            "precio_umbral": alerta.precio_umbral,
            "radio_km": alerta.radio_km,
            "activa": 1,
            "combustible": fuel,
            "estacion": station["nombre"] if station else None,
            "latitud_usuario": alerta.latitud_usuario,
            "longitud_usuario": alerta.longitud_usuario,
            "creado_en": "2026-05-06T09:00:00",
        }
        user_alerts.append(new_alert)
        return {"mensaje": "Alerta creada", "id": new_alert["id"]}

    @router.delete("/{alerta_id}")
    async def desactivar_alerta(
        alerta_id: int,
        payload: dict = Depends(get_current_user_token),
    ):
        """Deactivate an alert."""
        user_alerts = ALERTAS.setdefault(payload["user_id"], [])
        alerta = next((item for item in user_alerts if item["id"] == alerta_id), None)
        if not alerta:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Alerta no encontrada",
            )
        alerta["activa"] = 0
        return {"mensaje": "Alerta desactivada"}

    return router


def _next_id(items: list[dict]) -> int:
    return max((item["id"] for item in items), default=0) + 1
