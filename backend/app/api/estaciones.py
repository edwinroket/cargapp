"""Fuel station API routes for the mobile map."""
from math import asin, cos, radians, sin, sqrt
from typing import Optional

from fastapi import APIRouter, HTTPException, Query, status


COMBUSTIBLES = [
    {"id": 1, "nombre": "Gasolina 93", "categoria": "gasolina", "activo": 1},
    {"id": 2, "nombre": "Gasolina 95", "categoria": "gasolina", "activo": 1},
    {"id": 3, "nombre": "Gasolina 97", "categoria": "gasolina", "activo": 1},
    {"id": 4, "nombre": "Diesel", "categoria": "diesel", "activo": 1},
]

STATIONS = [
    {
        "id": 1,
        "nombre": "Shell Providencia",
        "marca": "Shell",
        "direccion": "Av. Providencia 2150",
        "comuna": "Providencia",
        "region": "Region Metropolitana",
        "latitud": -33.4245,
        "longitud": -70.6126,
        "horario": "24 horas",
        "metodos_pago": "Efectivo, debito, credito",
        "tiene_bano": 1,
        "tiene_tienda": 1,
        "tiene_lubricentro": 0,
        "tiene_cajero": 1,
        "activa": 1,
        "combustibles": [
            {
                "combustible": "Gasolina 93",
                "categoria": "gasolina",
                "precio": 1268,
                "precio_anterior": 1275,
                "fecha_registro": "2026-05-06T09:00:00",
            },
            {
                "combustible": "Gasolina 95",
                "categoria": "gasolina",
                "precio": 1312,
                "precio_anterior": 1308,
                "fecha_registro": "2026-05-06T09:00:00",
            },
            {
                "combustible": "Gasolina 97",
                "categoria": "gasolina",
                "precio": 1369,
                "precio_anterior": 1369,
                "fecha_registro": "2026-05-06T09:00:00",
            },
        ],
    },
    {
        "id": 2,
        "nombre": "Copec Las Condes",
        "marca": "Copec",
        "direccion": "Av. Apoquindo 4501",
        "comuna": "Las Condes",
        "region": "Region Metropolitana",
        "latitud": -33.4148,
        "longitud": -70.5839,
        "horario": "24 horas",
        "metodos_pago": "Efectivo, debito, credito",
        "tiene_bano": 1,
        "tiene_tienda": 1,
        "tiene_lubricentro": 1,
        "tiene_cajero": 1,
        "activa": 1,
        "combustibles": [
            {
                "combustible": "Gasolina 93",
                "categoria": "gasolina",
                "precio": 1259,
                "precio_anterior": 1261,
                "fecha_registro": "2026-05-06T09:00:00",
            },
            {
                "combustible": "Gasolina 95",
                "categoria": "gasolina",
                "precio": 1305,
                "precio_anterior": 1305,
                "fecha_registro": "2026-05-06T09:00:00",
            },
            {
                "combustible": "Diesel",
                "categoria": "diesel",
                "precio": 1024,
                "precio_anterior": 1030,
                "fecha_registro": "2026-05-06T09:00:00",
            },
        ],
    },
    {
        "id": 3,
        "nombre": "Petrobras Nunoa",
        "marca": "Petrobras",
        "direccion": "Av. Irarrazaval 3100",
        "comuna": "Nunoa",
        "region": "Region Metropolitana",
        "latitud": -33.4546,
        "longitud": -70.6031,
        "horario": "06:00 a 23:00",
        "metodos_pago": "Efectivo, debito",
        "tiene_bano": 1,
        "tiene_tienda": 0,
        "tiene_lubricentro": 0,
        "tiene_cajero": 0,
        "activa": 1,
        "combustibles": [
            {
                "combustible": "Gasolina 93",
                "categoria": "gasolina",
                "precio": 1247,
                "precio_anterior": 1255,
                "fecha_registro": "2026-05-06T09:00:00",
            },
            {
                "combustible": "Gasolina 97",
                "categoria": "gasolina",
                "precio": 1358,
                "precio_anterior": 1350,
                "fecha_registro": "2026-05-06T09:00:00",
            },
            {
                "combustible": "Diesel",
                "categoria": "diesel",
                "precio": 1018,
                "precio_anterior": 1018,
                "fecha_registro": "2026-05-06T09:00:00",
            },
        ],
    },
]


def create_estaciones_router() -> APIRouter:
    """Create station routes."""

    router = APIRouter(prefix="/estaciones", tags=["estaciones"])

    @router.get("/")
    async def get_cercanas(
        lat: float = Query(...),
        lng: float = Query(...),
        radio: float = 5,
        combustible: Optional[str] = None,
    ):
        """List nearby stations with current prices."""
        estaciones = []
        for station in STATIONS:
            station_copy = station.copy()
            station_copy["distancia_km"] = round(
                _distance_km(lat, lng, station["latitud"], station["longitud"]),
                2,
            )
            estaciones.append(station_copy)

        filtered = [
            station
            for station in estaciones
            if station["activa"] and station["distancia_km"] <= radio
        ]
        if not filtered:
            filtered = estaciones

        if combustible:
            filtered = [
                station
                for station in filtered
                if any(
                    combustible.lower() in price["combustible"].lower()
                    or combustible == str(_combustible_id(price["combustible"]))
                    for price in station["combustibles"]
                )
            ]

        filtered.sort(key=lambda station: station["distancia_km"])
        return {"total": len(filtered), "estaciones": filtered[:30]}

    @router.get("/combustibles")
    async def get_combustibles():
        """List available fuel types."""
        return COMBUSTIBLES

    @router.get("/{station_id}")
    async def get_detalle(station_id: int):
        """Get station detail with prices and price history."""
        station = next((item for item in STATIONS if item["id"] == station_id), None)
        if not station:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Estacion no encontrada",
            )

        historial = []
        for price in station["combustibles"]:
            historial.append(
                {
                    "combustible": price["combustible"],
                    "precio": price["precio"],
                    "fecha": "2026-05-06",
                    "fecha_registro": price["fecha_registro"],
                    "fuente": "cne",
                }
            )

        return {
            "estacion": station,
            "precios_actuales": station["combustibles"],
            "historial": historial,
        }

    return router


def _distance_km(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    radius_km = 6371
    dlat = radians(lat2 - lat1)
    dlng = radians(lng2 - lng1)
    value = (
        sin(dlat / 2) ** 2
        + cos(radians(lat1)) * cos(radians(lat2)) * sin(dlng / 2) ** 2
    )
    return 2 * radius_km * asin(sqrt(value))


def _combustible_id(name: str) -> Optional[int]:
    combustible = next((item for item in COMBUSTIBLES if item["nombre"] == name), None)
    return combustible["id"] if combustible else None
