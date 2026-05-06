# 🏛️ Arquitectura de CargApp

Guía de diseño y patrones arquitectónicos.

## 📐 Visión General

```
┌─────────────────────────────────────────────────────┐
│  Mobile (Flutter)                                    │
│  ├─ Features (auth, usuario, estación, etc.)        │
│  ├─ Domain (entities, repositories)                 │
│  ├─ Data (API & Mock repositories)                  │
│  └─ Presentation (screens, widgets)                 │
└────────────────┬────────────────────────────────────┘
                 │ HTTP (REST)
┌────────────────▼────────────────────────────────────┐
│  Backend (FastAPI)                                   │
│  ├─ API Routers (auth, usuario, vehiculo, etc.)     │
│  ├─ Auth (JWT, passwords, dependencies)             │
│  ├─ Domain Logic (usuario/, vehiculo/, etc.)        │
│  │  ├─ Schemas (Pydantic)                           │
│  │  ├─ Mock Store (desarrollo sin BD)               │
│  │  └─ SQL Store (persistencia PostgreSQL)          │
│  └─ DB (SQLAlchemy ORM models)                      │
└────────────────┬────────────────────────────────────┘
                 │
┌────────────────▼────────────────────────────────────┐
│  PostgreSQL                                          │
│  ├─ users, usuarios_perfiles                        │
│  ├─ vehiculos, vehiculos_alertas                    │
│  ├─ estaciones                                      │
│  └─ reportes                                        │
└──────────────────────────────────────────────────────┘
```

## 🏗️ Backend — FastAPI

### Capas (Clean Architecture)

#### 1. **API Layer** → `app/api/*.py`
- Routers de FastAPI
- Endpoints HTTP
- Mapeo de request/response
- Guards de autenticación

```python
# api/usuario.py
from fastapi import APIRouter, Depends
from app.auth.dependencies import require_roles
from app.usuario.schemas import UsuarioCreate

router = APIRouter(
    prefix="/usuarios",
    dependencies=[Depends(require_roles(auth_store, {AppRole.admin}))]
)

@router.get("/")
async def list_usuarios(skip: int = 0, limit: int = 100):
    return usuario_store.list_usuarios(skip, limit)
```

#### 2. **Domain Layer** → `app/usuario/`, `app/vehiculo/`, etc.
- Lógica de negocio
- Reglas de dominio
- Schemas Pydantic
- Interfaces

```python
# usuario/schemas.py
from pydantic import BaseModel, EmailStr

class UsuarioCreate(BaseModel):
    email: EmailStr
    password: str
    role: str = "user"

# usuario/mock_store.py (para desarrollo)
class UsuarioMockStore:
    def __init__(self):
        self.usuarios = {}
    
    async def create_usuario(self, usuario: UsuarioCreate):
        # Lógica sin persistencia
        pass

# usuario/sql_store.py (para producción)
class UsuarioSqlStore:
    def __init__(self, db_session):
        self.db = db_session
    
    async def create_usuario(self, usuario: UsuarioCreate):
        # Persistir en PostgreSQL
        pass
```

#### 3. **Auth Layer** → `app/auth/`
- Generación de tokens JWT
- Hashing de contraseñas
- Guards de autorización

```python
# auth/dependencies.py
def require_roles(allowed_roles: set[str]):
    async def check_role(token: str = Depends(HTTPBearer())):
        user = auth_store.get_user_from_token(token)
        if not user or user.role not in allowed_roles:
            raise HTTPException(403, "Forbidden")
        return user
    return Depends(check_role)
```

#### 4. **DB Layer** → `app/db/`
- Modelos SQLAlchemy
- Sesiones de BD
- Connection pooling

```python
# db/models.py
from sqlalchemy import Column, String, Integer
from sqlalchemy.ext.declarative import declarative_base

Base = declarative_base()

class UserModel(Base):
    __tablename__ = "users"
    
    id = Column(String(64), primary_key=True)
    email = Column(String(255), unique=True, index=True)
    role = Column(String(32), index=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
```

### Factory Pattern — Inyección de Dependencias

En `main.py`, decidimos en **runtime** si usar Mock o SQL Store:

```python
# main.py
from fastapi import FastAPI
from app.config import settings
from app.usuario.mock_store import UsuarioMockStore
from app.usuario.sql_store import UsuarioSqlStore
from app.api.usuario import create_usuario_router

app = FastAPI()

# Decidir basado en config
if settings.data_store == "mock":
    usuario_store = UsuarioMockStore()
else:
    db_session = SessionLocal()
    usuario_store = UsuarioSqlStore(db_session)

# Incluir router inyectando el store
app.include_router(create_usuario_router(usuario_store))
```

**Ventajas:**
- ✅ Desarrollo local sin BD
- ✅ Tests aislados sin dependencias externas
- ✅ Producción con PostgreSQL
- ✅ Cambio de config sin cambiar código

### Repository Pattern

Cada dominio expone una interfaz agnóstica:

```python
# usuario/base_store.py (interfaz)
class UsuarioStore:
    async def create_usuario(self, usuario: UsuarioCreate) -> Usuario:
        raise NotImplementedError
    
    async def get_usuario(self, usuario_id: str) -> Usuario | None:
        raise NotImplementedError
    
    async def list_usuarios(self) -> list[Usuario]:
        raise NotImplementedError

# usuario/sql_store.py (implementación)
class UsuarioSqlStore(UsuarioStore):
    async def create_usuario(self, usuario: UsuarioCreate) -> Usuario:
        # Lógica SQL
        pass
```

El router **no conoce** si es Mock o SQL:

```python
# api/usuario.py
async def create_usuario(usuario: UsuarioCreate) -> UsuarioResponse:
    new_user = await usuario_store.create_usuario(usuario)  # Funciona con ambos
    return UsuarioResponse(**new_user.dict())
```

---

## 📱 Mobile — Flutter Clean Architecture

### Estructura por Feature

```
features/
├── usuario/
│   ├── data/
│   │   ├── usuario_repository.dart        (Interfaz)
│   │   ├── usuario_api_repository.dart    (API implementation)
│   │   └── usuario_mock_repository.dart   (Mock implementation)
│   ├── domain/
│   │   ├── entities/
│   │   │   ├── usuario.dart
│   │   │   └── usuario_profile.dart
│   │   └── repositories/
│   │       └── usuario_repository.dart    (Interfaz re-exported)
│   └── presentation/
│       ├── pages/
│       │   ├── usuario_detail_page.dart
│       │   └── usuario_list_page.dart
│       ├── widgets/
│       │   ├── usuario_card.dart
│       │   └── usuario_form.dart
│       └── providers/
│           ├── usuario_provider.dart      (StateNotifier)
│           └── usuario_list_provider.dart (StateNotifier)
```

### Patrón Repository

```dart
// domain/repositories/usuario_repository.dart
abstract class UsuarioRepository {
  Future<List<Usuario>> getUsuarios();
  Future<Usuario> getUsuario(String id);
  Future<void> updateUsuario(Usuario usuario);
  Future<void> deleteUsuario(String id);
}

// data/usuario_api_repository.dart
class UsuarioApiRepository implements UsuarioRepository {
  final HttpClient _httpClient;
  
  UsuarioApiRepository({required HttpClient httpClient}) : _httpClient = httpClient;
  
  @override
  Future<List<Usuario>> getUsuarios() async {
    final response = await _httpClient.get('/usuarios');
    return (response.data as List)
        .map((u) => Usuario.fromJson(u))
        .toList();
  }
}

// data/usuario_mock_repository.dart
class UsuarioMockRepository implements UsuarioRepository {
  @override
  Future<List<Usuario>> getUsuarios() async {
    return [
      Usuario(id: '1', email: 'user@example.com', role: 'user'),
      Usuario(id: '2', email: 'admin@example.com', role: 'admin'),
    ];
  }
}

// presentation/providers/usuario_list_provider.dart
final usuarioRepositoryProvider = Provider<UsuarioRepository>((ref) {
  // Cambiar entre Mock y API según config
  return UsuarioApiRepository(
    httpClient: ref.watch(httpClientProvider),
  );
});

final usuariosProvider = FutureProvider<List<Usuario>>((ref) async {
  final repository = ref.watch(usuarioRepositoryProvider);
  return repository.getUsuarios();  // Agnóstico a la implementación
});
```

### Ventajas

- ✅ **Agnóstico a datos**: Cambiar entre API/Mock sin tocar UI
- ✅ **Testeable**: Mock repository para tests sin conexión
- ✅ **Escalable**: Nueva feature = nueva carpeta con estructura clara

---

## 🔐 Autenticación — JWT + Roles

### Flow

```
1. POST /auth/login
   ├─ email + password
   └─ → AuthResponse { access_token, user }

2. GET /usuarios
   ├─ Header: Authorization: Bearer <token>
   └─ → Token validado por dependency

3. POST /logout
   └─ Backend invalida token (opcional)
```

### Guards por Rol

```python
# auth/dependencies.py
def require_roles(auth_store, allowed_roles: set[str]):
    async def check_role(token: str = Header()):
        user = auth_store.decode_token(token)
        if not user or user.role not in allowed_roles:
            raise HTTPException(403, "Insufficient permissions")
        return user
    return Depends(check_role)

# Uso en router
@router.delete("/usuarios/{user_id}")
async def delete_usuario(
    user_id: str,
    current_user: User = Depends(require_roles({AppRole.admin}))
):
    # Solo admins pueden ejecutar esto
    pass
```

---

## 📊 Base de Datos — Schema

```sql
-- Usuarios
CREATE TABLE users (
    id VARCHAR(64) PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(32) NOT NULL,           -- admin, distribuidor, usuario
    status VARCHAR(32) NOT NULL,        -- activo, inactivo
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Vehículos
CREATE TABLE vehicles (
    id VARCHAR(64) PRIMARY KEY,
    user_id VARCHAR(64) NOT NULL REFERENCES users(id),
    name VARCHAR(255) NOT NULL,
    license_plate VARCHAR(32) UNIQUE,
    status VARCHAR(32) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Estaciones
CREATE TABLE stations (
    id VARCHAR(64) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    location VARCHAR(255) NOT NULL,
    status VARCHAR(32) NOT NULL,
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Alertas
CREATE TABLE alerts (
    id VARCHAR(64) PRIMARY KEY,
    vehicle_id VARCHAR(64) NOT NULL REFERENCES vehicles(id),
    severity VARCHAR(32) NOT NULL,     -- critical, warning, info
    status VARCHAR(32) NOT NULL,       -- open, resolved
    created_at TIMESTAMP DEFAULT NOW(),
    updated_at TIMESTAMP DEFAULT NOW()
);

-- Reportes
CREATE TABLE reports (
    id VARCHAR(64) PRIMARY KEY,
    vehicle_id VARCHAR(64) NOT NULL REFERENCES vehicles(id),
    data JSONB NOT NULL,
    created_at TIMESTAMP DEFAULT NOW()
);
```

---

## 🧪 Testing Strategy

### Backend (Pytest)

```python
# tests/test_usuario_api.py
import pytest
from app.usuario.mock_store import UsuarioMockStore

@pytest.fixture
def usuario_store():
    return UsuarioMockStore()

@pytest.mark.asyncio
async def test_create_usuario(usuario_store):
    usuario = UsuarioCreate(email="test@test.com", password="123")
    result = await usuario_store.create_usuario(usuario)
    assert result.email == "test@test.com"
```

### Mobile (Flutter Test)

```dart
// test/features/usuario/data/usuario_mock_repository_test.dart
void main() {
  group('UsuarioMockRepository', () {
    late UsuarioMockRepository repository;

    setUp(() {
      repository = UsuarioMockRepository();
    });

    test('getUsuarios returns list of usuarios', () async {
      final result = await repository.getUsuarios();
      expect(result, isNotEmpty);
      expect(result.first.email, contains('@'));
    });
  });
}
```

---

## 📦 Deployment

### Local
```bash
docker compose up -d
```

### Producción (Railroad/Heroku)
```bash
# Environment variables en Railway
DATABASE_URL=postgresql://...
JWT_SECRET=prod-secret
DEBUG=false
DATA_STORE=sql
```

---

## ✅ Checklist de Decisiones

- [x] Factory Pattern para Store injection
- [x] Repository Pattern para abstracción de datos
- [x] Clean Architecture (API → Domain → DB)
- [x] Feature-driven en Mobile
- [x] JWT + Roles para autenticación
- [x] Mock Stores para desarrollo
- [x] Tests unitarios e integración
- [x] Docker para dev/prod
- [x] Secretos fuera del repo (.env.example)

---

## 📚 Referencias

- FastAPI: https://fastapi.tiangolo.com
- SQLAlchemy: https://sqlalchemy.org
- Flutter Clean Architecture: https://medium.com/flutter-community/clean-architecture-in-flutter
- SOLID Principles: https://en.wikipedia.org/wiki/SOLID
