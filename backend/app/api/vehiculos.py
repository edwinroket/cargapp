"""Vehicle API routes for the mobile profile section."""
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel

from app.api.estaciones import COMBUSTIBLES, STATIONS
from app.auth.dependencies import get_current_user_token


MODELOS = [
    {
        "id": 1,
        "marca": "Toyota",
        "modelo": "Corolla",
        "anio": 2022,
        "rendimiento_oficial": 15.5,
    },
    {
        "id": 2,
        "marca": "Hyundai",
        "modelo": "Accent",
        "anio": 2021,
        "rendimiento_oficial": 14.8,
    },
    {
        "id": 3,
        "marca": "Chevrolet",
        "modelo": "Sail",
        "anio": 2020,
        "rendimiento_oficial": 13.9,
    },
]

VEHICULOS: dict[str, list[dict]] = {
    "1": [],
    "2": [
        {
            "id": 1,
            "alias": "Auto demo",
            "marca_manual": "Toyota",
            "modelo_manual": "Corolla",
            "anio_manual": 2022,
            "rendimiento_km_l": 15.5,
            "tipo_combustible_id": 1,
            "combustible": "Gasolina 93",
            "tipo_combustible": "Gasolina 93",
            "es_principal": 1,
            "creado_en": "2026-05-06T09:00:00",
        }
    ],
}


class VehiculoCreate(BaseModel):
    """Payload for creating a vehicle."""

    modelo_id: Optional[int] = None
    alias: Optional[str] = None
    marca_manual: Optional[str] = None
    modelo_manual: Optional[str] = None
    anio_manual: Optional[int] = None
    rendimiento_km_l: float
    tipo_combustible_id: int
    es_principal: bool = False


def create_vehiculos_router() -> APIRouter:
    """Create vehicle routes."""

    router = APIRouter(prefix="/vehiculos", tags=["vehiculos"])

    @router.get("/")
    async def get_vehiculos(payload: dict = Depends(get_current_user_token)):
        """List vehicles for the authenticated user."""
        return VEHICULOS.setdefault(payload["user_id"], [])

    @router.post("/", status_code=status.HTTP_201_CREATED)
    async def crear_vehiculo(
        vehiculo: VehiculoCreate,
        payload: dict = Depends(get_current_user_token),
    ):
        """Create a vehicle for the authenticated user."""
        user_id = payload["user_id"]
        user_vehicles = VEHICULOS.setdefault(user_id, [])
        if vehiculo.es_principal:
            for item in user_vehicles:
                item["es_principal"] = 0

        fuel = next(
            (
                item["nombre"]
                for item in COMBUSTIBLES
                if item["id"] == vehiculo.tipo_combustible_id
            ),
            "Combustible",
        )
        new_vehicle = {
            "id": _next_id(user_vehicles),
            "alias": vehiculo.alias,
            "marca_manual": vehiculo.marca_manual,
            "modelo_manual": vehiculo.modelo_manual,
            "anio_manual": vehiculo.anio_manual,
            "rendimiento_km_l": vehiculo.rendimiento_km_l,
            "tipo_combustible_id": vehiculo.tipo_combustible_id,
            "combustible": fuel,
            "tipo_combustible": fuel,
            "es_principal": 1 if vehiculo.es_principal else 0,
            "creado_en": "2026-05-06T09:00:00",
        }
        user_vehicles.append(new_vehicle)
        return {"mensaje": "Vehiculo agregado", "id": new_vehicle["id"]}

    @router.get("/modelos")
    async def get_modelos(
        marca: Optional[str] = None,
        modelo: Optional[str] = None,
        anio: Optional[int] = None,
    ):
        """List known vehicle models."""
        result = MODELOS
        if marca:
            result = [
                item for item in result if marca.lower() in item["marca"].lower()
            ]
        if modelo:
            result = [
                item for item in result if modelo.lower() in item["modelo"].lower()
            ]
        if anio:
            result = [item for item in result if item["anio"] == anio]
        return result

    @router.get("/costo")
    async def calcular_costo(
        vehiculo_id: int = Query(...),
        estacion_id: int = Query(...),
        distancia_km: float = 1,
        payload: dict = Depends(get_current_user_token),
    ):
        """Calculate fuel cost for a vehicle at a station."""
        user_vehicles = VEHICULOS.setdefault(payload["user_id"], [])
        vehiculo = next(
            (item for item in user_vehicles if item["id"] == vehiculo_id),
            None,
        )
        if not vehiculo:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Vehiculo no encontrado",
            )

        station = next((item for item in STATIONS if item["id"] == estacion_id), None)
        if not station:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Estacion no encontrada",
            )

        price = next(
            (
                item
                for item in station["combustibles"]
                if item["combustible"] == vehiculo["combustible"]
            ),
            station["combustibles"][0],
        )
        precio_litro = float(price["precio"])
        rendimiento = float(vehiculo["rendimiento_km_l"])
        costo_por_km = precio_litro / rendimiento
        return {
            "vehiculo": vehiculo.get("alias") or vehiculo.get("modelo_manual"),
            "combustible": price["combustible"],
            "precio_litro": precio_litro,
            "rendimiento_km_l": rendimiento,
            "costo_por_km": round(costo_por_km),
            "distancia_km": distancia_km,
            "costo_total": round(costo_por_km * distancia_km),
        }

    @router.delete("/{vehiculo_id}")
    async def eliminar_vehiculo(
        vehiculo_id: int,
        payload: dict = Depends(get_current_user_token),
    ):
        """Delete a vehicle."""
        user_vehicles = VEHICULOS.setdefault(payload["user_id"], [])
        before = len(user_vehicles)
        VEHICULOS[payload["user_id"]] = [
            item for item in user_vehicles if item["id"] != vehiculo_id
        ]
        if len(VEHICULOS[payload["user_id"]]) == before:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Vehiculo no encontrado",
            )
        return {"mensaje": "Vehiculo eliminado"}

    return router


def _next_id(items: list[dict]) -> int:
    return max((item["id"] for item in items), default=0) + 1
