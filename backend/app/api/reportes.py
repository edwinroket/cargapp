"""User fuel price report API routes."""
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel

from app.api.estaciones import COMBUSTIBLES, STATIONS
from app.auth.dependencies import get_current_user_token


REPORTES: list[dict] = [
    {
        "id": 1,
        "estacion_id": 1,
        "usuario_id": "2",
        "precio_reportado": 1268,
        "votos_positivos": 2,
        "votos_negativos": 0,
        "estado": "pendiente",
        "combustible": "Gasolina 93",
        "usuario": "Usuario Demo",
        "reputacion_usuario": 0,
        "creado_en": "2026-05-06T09:00:00",
    }
]


class ReporteCreate(BaseModel):
    """Payload for creating a price report."""

    estacion_id: int
    tipo_combustible_id: int
    precio_reportado: float


class VotoCreate(BaseModel):
    """Payload for voting a report."""

    voto: str


def create_reportes_router() -> APIRouter:
    """Create report routes."""

    router = APIRouter(prefix="/reportes", tags=["reportes"])

    @router.get("/estacion/{estacion_id}")
    async def get_reportes_estacion(estacion_id: int):
        """List reports for a station."""
        return [
            item
            for item in REPORTES
            if item["estacion_id"] == estacion_id and item["estado"] != "rechazado"
        ]

    @router.post("/", status_code=status.HTTP_201_CREATED)
    async def crear_reporte(
        reporte: ReporteCreate,
        payload: dict = Depends(get_current_user_token),
    ):
        """Create a user price report."""
        if reporte.precio_reportado < 500 or reporte.precio_reportado > 5000:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Precio fuera de rango valido ($500 - $5000)",
            )
        station = next(
            (item for item in STATIONS if item["id"] == reporte.estacion_id),
            None,
        )
        if not station:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Estacion no encontrada",
            )
        fuel = next(
            (
                item["nombre"]
                for item in COMBUSTIBLES
                if item["id"] == reporte.tipo_combustible_id
            ),
            "Combustible",
        )
        new_report = {
            "id": _next_id(REPORTES),
            "estacion_id": reporte.estacion_id,
            "usuario_id": payload["user_id"],
            "precio_reportado": reporte.precio_reportado,
            "votos_positivos": 0,
            "votos_negativos": 0,
            "estado": "pendiente",
            "combustible": fuel,
            "usuario": "Usuario",
            "reputacion_usuario": 0,
            "creado_en": "2026-05-06T09:00:00",
        }
        REPORTES.append(new_report)
        return {
            "mensaje": "Reporte enviado, gracias por contribuir",
            "id": new_report["id"],
        }

    @router.post("/{reporte_id}/votar")
    async def votar_reporte(
        reporte_id: int,
        voto: VotoCreate,
        _: dict = Depends(get_current_user_token),
    ):
        """Vote for a price report."""
        if voto.voto not in {"positivo", "negativo"}:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="voto debe ser positivo o negativo",
            )
        reporte = next((item for item in REPORTES if item["id"] == reporte_id), None)
        if not reporte:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Reporte no encontrado",
            )
        if voto.voto == "positivo":
            reporte["votos_positivos"] += 1
        else:
            reporte["votos_negativos"] += 1
        return {"mensaje": f"Voto {voto.voto} registrado"}

    return router


def _next_id(items: list[dict]) -> int:
    return max((item["id"] for item in items), default=0) + 1
