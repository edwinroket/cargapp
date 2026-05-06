"""Pytest configuration and fixtures."""
import pytest
from fastapi.testclient import TestClient

from app.main import create_app
from app.usuario.mock_store import UsuarioMockStore
from app.usuario.schemas import UserCreate


@pytest.fixture
def app():
    """Create test application."""
    return create_app()


@pytest.fixture
def client(app):
    """Create test client."""
    return TestClient(app)


@pytest.fixture
def usuario_store():
    """Create mock user store for testing."""
    return UsuarioMockStore()


@pytest.fixture
async def test_user_data():
    """Test user data."""
    return {
        "email": "test@example.com",
        "password": "testpass123",
        "role": "usuario",
    }


@pytest.fixture
async def test_user(usuario_store, test_user_data):
    """Create a test user."""
    user_create = UserCreate(**test_user_data)
    return await usuario_store.create_usuario(user_create)


@pytest.fixture
def auth_token(usuario_store):
    """Get auth token for test user."""
    from app.auth.jwt import create_access_token

    # Get first user from mock store (id "1" is admin)
    return create_access_token("1")
