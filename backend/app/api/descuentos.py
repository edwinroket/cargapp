"""Fuel discount API routes."""
from fastapi import APIRouter


DESCUENTOS = [
    {
        "dia": "Todos los dias",
        "convenio": "Banco BCI",
        "descuento_por_litro": "$100 por litro",
        "tipo": "Tarjetas Bancarias",
        "condicion": "Pagando con tarjeta de credito BCI en estaciones adheridas.",
        "tope_mensual": "$20.000",
        "notas": "Beneficio sujeto a disponibilidad del convenio.",
        "origen": "Copec",
        "fuente_url": "https://www.copec.cl",
        "descuento_num": 100,
        "vigencia_hasta": "2026-12-31",
        "is_active": True,
    },
    {
        "dia": "Lunes a viernes",
        "convenio": "MACH",
        "descuento_por_litro": "$80 por litro",
        "tipo": "App / Digital",
        "condicion": "Pagando desde app MACH.",
        "tope_mensual": "$15.000",
        "notas": "",
        "origen": "Shell",
        "fuente_url": "https://www.shell.cl",
        "descuento_num": 80,
        "vigencia_hasta": "2026-10-31",
        "is_active": True,
    },
    {
        "dia": "Fin de semana",
        "convenio": "Cencosud Scotiabank",
        "descuento_por_litro": "$120 por litro",
        "tipo": "Tarjetas Retail",
        "condicion": "Pagando con tarjeta Cencosud Scotiabank.",
        "tope_mensual": "$25.000",
        "notas": "No acumulable con otras promociones.",
        "origen": "Aramco",
        "fuente_url": "https://www.aramco.cl",
        "descuento_num": 120,
        "vigencia_hasta": "2026-12-31",
        "is_active": True,
    },
]


def create_descuentos_router() -> APIRouter:
    """Create discount routes."""

    router = APIRouter(prefix="/descuentos", tags=["descuentos"])

    @router.get("/")
    async def get_descuentos():
        """List active fuel discounts."""
        return [item for item in DESCUENTOS if item["is_active"]]

    return router
