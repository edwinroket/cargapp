"""Tests for authentication API."""
import pytest


def test_health_check(client):
    """Test health endpoint."""
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_register_user(client):
    """Test user registration."""
    user_data = {
        "email": "newuser@example.com",
        "password": "securepass123",
        "role": "usuario",
    }
    response = client.post("/auth/register", json=user_data)
    assert response.status_code == 200
    data = response.json()
    assert data["access_token"]
    assert data["token_type"] == "bearer"
    assert data["user"]["email"] == user_data["email"]
    assert data["user"]["role"] == "usuario"


def test_register_duplicate_email(client):
    """Test registration with duplicate email."""
    user_data = {
        "email": "admin@example.com",
        "password": "pass123",
        "role": "usuario",
    }
    response = client.post("/auth/register", json=user_data)
    assert response.status_code == 400
    assert "already registered" in response.json()["detail"]


def test_login_success(client):
    """Test successful login."""
    credentials = {
        "email": "admin@example.com",
        "password": "admin123",
    }
    response = client.post("/auth/login", json=credentials)
    assert response.status_code == 200
    data = response.json()
    assert data["access_token"]
    assert data["token_type"] == "bearer"
    assert data["user"]["email"] == "admin@example.com"
    assert data["user"]["role"] == "admin"


def test_login_invalid_password(client):
    """Test login with wrong password."""
    credentials = {
        "email": "admin@example.com",
        "password": "wrongpass",
    }
    response = client.post("/auth/login", json=credentials)
    assert response.status_code == 401


def test_login_user_not_found(client):
    """Test login with non-existent user."""
    credentials = {
        "email": "nonexistent@example.com",
        "password": "pass123",
    }
    response = client.post("/auth/login", json=credentials)
    assert response.status_code == 401


def test_logout(client, auth_token):
    """Test logout endpoint."""
    headers = {"Authorization": f"Bearer {auth_token}"}
    response = client.post("/auth/logout", headers=headers)
    assert response.status_code == 200
    assert response.json()["message"]


def test_list_usuarios_requires_auth(client):
    """Test that list usuarios requires authentication."""
    response = client.get("/usuarios")
    assert response.status_code == 401  # HTTPBearer returns 401, not 403


def test_list_usuarios_with_auth(client, auth_token):
    """Test listing usuarios with valid token."""
    headers = {"Authorization": f"Bearer {auth_token}"}
    response = client.get("/usuarios", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert isinstance(data, list)
    assert len(data) >= 2  # At least admin and user from mock


def test_get_usuario_with_auth(client, auth_token):
    """Test getting a specific usuario."""
    headers = {"Authorization": f"Bearer {auth_token}"}
    response = client.get("/usuarios/1", headers=headers)
    assert response.status_code == 200
    data = response.json()
    assert data["id"] == "1"
    assert data["email"] == "admin@example.com"


def test_get_usuario_not_found(client, auth_token):
    """Test getting non-existent usuario."""
    headers = {"Authorization": f"Bearer {auth_token}"}
    response = client.get("/usuarios/nonexistent", headers=headers)
    assert response.status_code == 404


def test_invalid_token(client):
    """Test with invalid token."""
    headers = {"Authorization": "Bearer invalid.token.here"}
    response = client.get("/usuarios", headers=headers)
    assert response.status_code == 401
