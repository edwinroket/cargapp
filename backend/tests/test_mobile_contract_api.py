"""Tests for the REST contract consumed by the Flutter app."""


def test_estaciones_contract(client):
    """Map endpoint returns stations in the shape used by Flutter."""
    response = client.get("/estaciones?lat=-33.45&lng=-70.66&radio=10")

    assert response.status_code == 200
    data = response.json()
    assert data["total"] >= 1
    station = data["estaciones"][0]
    assert "distancia_km" in station
    assert station["combustibles"][0]["combustible"]
    assert station["combustibles"][0]["fecha_registro"]


def test_estacion_detalle_contract(client):
    """Station detail endpoint returns current prices and history."""
    response = client.get("/estaciones/1")

    assert response.status_code == 200
    data = response.json()
    assert data["estacion"]["id"] == 1
    assert "tiene_cajero" in data["estacion"]
    assert len(data["precios_actuales"]) >= 1
    assert "precio_anterior" in data["precios_actuales"][0]
    assert len(data["historial"]) >= 1
    assert "fecha_registro" in data["historial"][0]


def test_descuentos_contract(client):
    """Discount endpoint returns rows used by the discounts screen."""
    response = client.get("/descuentos")

    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert data[0]["convenio"]
    assert data[0]["descuento_num"] > 0


def test_perfil_contract(client, auth_token):
    """Profile update endpoint supports fields added in main."""
    headers = {"Authorization": f"Bearer {auth_token}"}
    response = client.put(
        "/usuarios/perfil",
        headers=headers,
        json={
            "nombre_completo": "Admin Demo",
            "telefono": "+56912345678",
            "ciudad_id": 13101,
        },
    )

    assert response.status_code == 200
    data = response.json()
    assert data["nombre_completo"] == "Admin Demo"
    assert data["telefono"] == "+56912345678"
    assert data["ciudad"] == "Santiago"


def test_vehiculos_contract(client, auth_token):
    """Vehicle endpoints support list/create/delete for profile screen."""
    headers = {"Authorization": f"Bearer {auth_token}"}
    create = client.post(
        "/vehiculos",
        headers=headers,
        json={
            "marca_manual": "Toyota",
            "modelo_manual": "Yaris",
            "anio_manual": 2023,
            "rendimiento_km_l": 16.2,
            "tipo_combustible_id": 1,
            "alias": "Yaris",
            "es_principal": True,
        },
    )

    assert create.status_code == 201
    vehicle_id = create.json()["id"]

    listed = client.get("/vehiculos", headers=headers)
    assert listed.status_code == 200
    assert any(item["id"] == vehicle_id for item in listed.json())


def test_alertas_and_reportes_contract(client, auth_token):
    """Alert and report endpoints match the mobile services."""
    headers = {"Authorization": f"Bearer {auth_token}"}

    alerta = client.post(
        "/alertas",
        headers=headers,
        json={
            "tipo_combustible_id": 1,
            "precio_umbral": 1200,
            "radio_km": 5,
            "latitud_usuario": -33.45,
            "longitud_usuario": -70.66,
        },
    )
    assert alerta.status_code == 201

    reportes = client.get("/reportes/estacion/1")
    assert reportes.status_code == 200
    assert isinstance(reportes.json(), list)
