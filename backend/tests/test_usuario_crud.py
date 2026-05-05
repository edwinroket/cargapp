"""Tests for user CRUD operations (Fase 3)."""
import pytest


# ============================================================================
# CREATE USUARIO (POST /usuarios) - Requires auth
# ============================================================================


def test_create_usuario_requires_auth(client):
    """Test that creating usuario requires authentication."""
    user_data = {
        "email": "newuser@example.com",
        "password": "pass123",
        "role": "usuario",
    }
    response = client.post("/usuarios", json=user_data)
    assert response.status_code == 401


def test_create_usuario_with_auth(client, auth_token):
    """Test creating a new usuario with valid token."""
    headers = {"Authorization": f"Bearer {auth_token}"}
    user_data = {
        "email": "new@example.com",
        "password": "securepass123",
        "role": "usuario",
    }
    response = client.post("/usuarios", headers=headers, json=user_data)
    assert response.status_code == 200
    data = response.json()
    assert data["email"] == "new@example.com"
    assert data["role"] == "usuario"
    assert data["status"] == "activo"
    assert "id" in data


def test_create_usuario_invalid_email(client, auth_token):
    """Test creating usuario with invalid email."""
    headers = {"Authorization": f"Bearer {auth_token}"}
    user_data = {
        "email": "invalid-email",
        "password": "pass123",
        "role": "usuario",
    }
    response = client.post("/usuarios", headers=headers, json=user_data)
    assert response.status_code == 422  # Validation error


# ============================================================================
# READ USUARIO (GET /usuarios/{id}) - Requires auth
# ============================================================================


def test_get_usuario_success(client, auth_token):
    """Test getting usuario by ID."""
    headers = {"Authorization": f"Bearer {auth_token}"}
    response = client.get("/usuarios/1", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert data["id"] == "1"
    assert data["email"] == "admin@example.com"
    assert data["role"] == "admin"


def test_get_usuario_not_found(client, auth_token):
    """Test getting non-existent usuario."""
    headers = {"Authorization": f"Bearer {auth_token}"}
    response = client.get("/usuarios/999", headers=headers)
    assert response.status_code == 404
    assert "not found" in response.json()["detail"]


def test_get_usuario_no_auth(client):
    """Test getting usuario without authentication."""
    response = client.get("/usuarios/1")
    assert response.status_code == 401


# ============================================================================
# LIST USUARIOS (GET /usuarios) - Requires auth
# ============================================================================


def test_list_usuarios_success(client, auth_token):
    """Test listing all usuarios."""
    headers = {"Authorization": f"Bearer {auth_token}"}
    response = client.get("/usuarios", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) >= 2  # At least admin and user from mock


def test_list_usuarios_with_pagination(client, auth_token):
    """Test listing usuarios with skip and limit."""
    headers = {"Authorization": f"Bearer {auth_token}"}
    response = client.get("/usuarios?skip=0&limit=1", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) == 1


def test_list_usuarios_no_auth(client):
    """Test listing usuarios without authentication."""
    response = client.get("/usuarios")
    assert response.status_code == 401


# ============================================================================
# UPDATE USUARIO (PUT /usuarios/{id}) - Requires auth
# ============================================================================


def test_update_usuario_success(client, auth_token):
    """Test updating usuario."""
    headers = {"Authorization": f"Bearer {auth_token}"}
    update_data = {
        "role": "moderador",
        "status": "inactivo",
    }
    response = client.put("/usuarios/2", headers=headers, json=update_data)
    assert response.status_code == 200
    data = response.json()
    assert data["id"] == "2"
    assert data["role"] == "moderador"
    assert data["status"] == "inactivo"


def test_update_usuario_partial(client, auth_token):
    """Test updating only some fields."""
    headers = {"Authorization": f"Bearer {auth_token}"}
    update_data = {"role": "admin"}
    response = client.put("/usuarios/2", headers=headers, json=update_data)
    assert response.status_code == 200
    data = response.json()
    assert data["role"] == "admin"
    assert data["email"] == "user@example.com"  # Unchanged


def test_update_usuario_not_found(client, auth_token):
    """Test updating non-existent usuario."""
    headers = {"Authorization": f"Bearer {auth_token}"}
    update_data = {"role": "moderador"}
    response = client.put("/usuarios/999", headers=headers, json=update_data)
    assert response.status_code == 404
    assert "not found" in response.json()["detail"]


def test_update_usuario_no_auth(client):
    """Test updating usuario without authentication."""
    update_data = {"role": "moderador"}
    response = client.put("/usuarios/2", json=update_data)
    assert response.status_code == 401


def test_update_usuario_invalid_email(client, auth_token):
    """Test updating usuario with invalid email."""
    headers = {"Authorization": f"Bearer {auth_token}"}
    update_data = {"email": "not-an-email"}
    response = client.put("/usuarios/2", headers=headers, json=update_data)
    assert response.status_code == 422  # Validation error


# ============================================================================
# DELETE USUARIO (DELETE /usuarios/{id}) - Requires auth
# ============================================================================


def test_delete_usuario_success(client, auth_token):
    """Test deleting usuario."""
    headers = {"Authorization": f"Bearer {auth_token}"}
    
    # First create a usuario to delete
    user_data = {
        "email": "delete_me@example.com",
        "password": "pass123",
        "role": "usuario",
    }
    create_response = client.post("/usuarios", headers=headers, json=user_data)
    user_id = create_response.json()["id"]
    
    # Now delete it
    response = client.delete(f"/usuarios/{user_id}", headers=headers)
    assert response.status_code == 200
    assert "deleted" in response.json()["message"].lower()
    
    # Verify it's deleted
    get_response = client.get(f"/usuarios/{user_id}", headers=headers)
    assert get_response.status_code == 404


def test_delete_usuario_not_found(client, auth_token):
    """Test deleting non-existent usuario."""
    headers = {"Authorization": f"Bearer {auth_token}"}
    response = client.delete("/usuarios/999", headers=headers)
    assert response.status_code == 404
    assert "not found" in response.json()["detail"]


def test_delete_usuario_no_auth(client):
    """Test deleting usuario without authentication."""
    response = client.delete("/usuarios/1")
    assert response.status_code == 401


# ============================================================================
# EDGE CASES AND INTEGRATION
# ============================================================================


def test_create_then_list_usuario(client, auth_token):
    """Test creating usuario and verifying in list."""
    headers = {"Authorization": f"Bearer {auth_token}"}
    
    # Create
    user_data = {
        "email": "integration@example.com",
        "password": "pass123",
        "role": "usuario",
    }
    create_response = client.post("/usuarios", headers=headers, json=user_data)
    new_user_id = create_response.json()["id"]
    
    # List and verify presence
    list_response = client.get("/usuarios", headers=headers)
    usuarios = list_response.json()
    user_ids = [u["id"] for u in usuarios]
    assert new_user_id in user_ids


def test_create_update_delete_flow(client, auth_token):
    """Test complete CRUD flow."""
    headers = {"Authorization": f"Bearer {auth_token}"}
    
    # CREATE
    user_data = {
        "email": "crud_test@example.com",
        "password": "pass123",
        "role": "usuario",
    }
    create_resp = client.post("/usuarios", headers=headers, json=user_data)
    assert create_resp.status_code == 200
    user_id = create_resp.json()["id"]
    
    # READ
    get_resp = client.get(f"/usuarios/{user_id}", headers=headers)
    assert get_resp.status_code == 200
    assert get_resp.json()["email"] == "crud_test@example.com"
    
    # UPDATE
    update_data = {"role": "moderador", "status": "inactivo"}
    update_resp = client.put(
        f"/usuarios/{user_id}", headers=headers, json=update_data
    )
    assert update_resp.status_code == 200
    assert update_resp.json()["role"] == "moderador"
    
    # DELETE
    delete_resp = client.delete(f"/usuarios/{user_id}", headers=headers)
    assert delete_resp.status_code == 200
    
    # VERIFY DELETED
    final_get = client.get(f"/usuarios/{user_id}", headers=headers)
    assert final_get.status_code == 404
