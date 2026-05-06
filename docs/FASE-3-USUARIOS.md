# 📘 Fase 3: CRUD Completo de Usuarios

## 🎯 Descripción General

**Fase 3** implementa el **CRUD completo** de usuarios en backend (FastAPI) y mobile (Flutter):

### Backend (FastAPI)
- ✅ Endpoints de lectura (`GET /usuarios`, `GET /usuarios/{id}`)
- ✅ Endpoints de escritura (`POST /usuarios`, `PUT /usuarios/{id}`, `DELETE /usuarios/{id}`)
- ✅ Autenticación requerida en todos los endpoints
- ✅ Tests completos (27/27 tests pasando)
- ✅ Mock store + SQL store intercambiables

### Mobile (Flutter)
- 📁 Estructura Clean Architecture completa
- 📱 Domain entities + repositories
- 🔌 Data models + datasources (API + Mock)
- 🎨 Presentación scaffolding (listo para screens)

---

## 🚀 Setup Local

### Requisitos Previos

```bash
# Backend
Python 3.11+
pip
virtualenv

# Mobile
Flutter 3.10+
Dart 3.0+
```

### 1️⃣ Backend Setup

#### Crear environment virtual

```bash
cd backend
python -m venv .venv

# Windows
.venv\Scripts\activate

# macOS/Linux
source .venv/bin/activate
```

#### Instalar dependencias

```bash
pip install -r requirements.txt
pip install -r requirements-dev.txt  # Para tests
```

#### Verificar variables de entorno

```bash
cat .env
# Debe contener:
# DATABASE_URL=postgresql://...
# JWT_SECRET=cargapp_secret_key_change_in_production_2026
# DEBUG=true
# DATA_STORE=mock
```

#### Iniciar servidor

```bash
# Terminal 1: Uvicorn en reload
uvicorn app.main:app --reload --port 8000

# Output esperado:
# INFO:     Uvicorn running on http://127.0.0.1:8000
# INFO:     Application startup complete.
```

#### Verificar salud

```bash
# Terminal 2
curl http://localhost:8000/health

# Respuesta:
# {"status":"ok","service":"cargapp-api","version":"0.1.0"}
```

### 2️⃣ Mobile Setup

#### Obtener dependencias Flutter

```bash
cd app

# Limpiar caché
flutter clean

# Descargar dependencias
flutter pub get
```

#### Verificar conectividad con backend

```bash
# El archivo app/lib/services/api_service.dart debe tener:
const String baseUrl = 'http://localhost:8000';

# O desde emulador Android:
const String baseUrl = 'http://10.0.2.2:8000';
```

---

## 🧪 Testing

### Backend: Ejecutar Tests

```bash
cd backend

# Todos los tests
pytest tests/ -v

# Solo tests de usuario CRUD
pytest tests/test_usuario_crud.py -v

# Con coverage
pytest tests/ --cov=app --cov-report=html
```

#### Estructura de Tests

```
tests/
├── test_auth_api.py          # 12 tests (Auth + login + logout)
└── test_usuario_crud.py      # 27 tests (CRUD completo)
   ├── CREATE (3 tests)
   ├── READ (3 tests)
   ├── LIST (3 tests)
   ├── UPDATE (5 tests)
   ├── DELETE (3 tests)
   └── INTEGRATION (7 tests)
```

#### Ejemplo de Ejecución

```bash
$ pytest tests/test_usuario_crud.py -v

test_create_usuario_requires_auth PASSED
test_create_usuario_with_auth PASSED
test_create_usuario_invalid_email PASSED
test_get_usuario_success PASSED
test_get_usuario_not_found PASSED
test_list_usuarios_success PASSED
test_update_usuario_success PASSED
test_delete_usuario_success PASSED
test_create_then_list_usuario PASSED
test_create_update_delete_flow PASSED

===================== 27 passed in 2.15s =====================
```

### Mobile: Prueba de Conexión

```bash
cd app

# Ejecutar en emulador
flutter run

# O en dispositivo conectado
flutter run -d <device-id>
```

---

## 🔄 Simulación con Mock Data

### Backend: Mock Store

El backend usa **mock store por defecto** (`.env: DATA_STORE=mock`):

```python
# No requiere base de datos
# Datos se almacenan en memoria (se pierden al reiniciar)
# Perfecto para desarrollo local sin Docker
```

**Usuarios precargados:**

```
Email: admin@example.com
Password: admin123
Role: admin

Email: user@example.com
Password: user123
Role: usuario
```

**Testear mock:**

```bash
# Login
curl -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"admin123"}'

# Respuesta con token JWT
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "user": {
    "id": "1",
    "email": "admin@example.com",
    "role": "admin",
    "status": "activo"
  }
}

# Listar usuarios
curl http://localhost:8000/usuarios \
  -H "Authorization: Bearer <token>"
```

### Mobile: Mock Datasource

```dart
// Usar mock datasource para testing sin backend
final mockDataSource = UsuarioMockDataSource();

// Simula API con delay
await mockDataSource.getUsuarios();
// Retorna lista con 2 usuarios de prueba
```

---

## 📁 Estructura de Archivos

### Backend

```
backend/
├── app/
│   ├── usuario/
│   │   ├── schemas.py           # Pydantic models (request/response)
│   │   ├── mock_store.py        # In-memory store
│   │   └── sql_store.py         # SQL store
│   ├── api/
│   │   └── usuario.py           # Router con endpoints CRUD
│   ├── auth/
│   │   ├── jwt.py               # Token generation/validation
│   │   ├── passwords.py         # Argon2 hashing
│   │   └── dependencies.py      # HTTPBearer guard
│   └── db/
│       ├── models.py            # SQLAlchemy ORM
│       └── session.py           # DB connection pooling
├── tests/
│   ├── test_auth_api.py         # 12 auth tests
│   └── test_usuario_crud.py     # 27 CRUD tests
├── conftest.py                  # Pytest fixtures
├── requirements.txt             # Dependencies
└── .env                         # Config (mock store)
```

### Mobile

```
app/lib/features/usuario/
├── data/
│   ├── datasources/
│   │   ├── usuario_remote_datasource.dart          # Abstract
│   │   ├── usuario_remote_datasource_impl.dart     # Real API
│   │   └── usuario_mock_datasource.dart            # Mock
│   ├── models/
│   │   └── usuario_model.dart                      # JSON serialization
│   └── repositories/
│       └── usuario_repository_impl.dart            # Repository implementation
├── domain/
│   ├── entities/
│   │   └── usuario.dart                            # Domain model
│   └── repositories/
│       └── usuario_repository.dart                 # Abstract interface
└── presentation/
    ├── pages/
    │   ├── usuarios_list_page.dart                 # List screen
    │   └── usuario_detail_page.dart                # Detail screen
    └── providers/
        └── usuario_provider.dart                   # State management
```

---

## 🔌 Endpoints API

### Autenticación (Pública)

```
POST /auth/register
POST /auth/login
POST /auth/logout
```

### Usuarios (Requiere JWT)

```
GET    /usuarios              # Listar todos
GET    /usuarios/{id}         # Obtener por ID
POST   /usuarios              # Crear
PUT    /usuarios/{id}         # Actualizar
DELETE /usuarios/{id}         # Eliminar
```

### Headers Requeridos

```bash
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json
```

---

## 💻 Ejemplo de Flujo Completo

### 1. Login y Obtener Token

```bash
TOKEN=$(curl -s -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"admin@example.com","password":"admin123"}' \
  | jq -r '.access_token')

echo $TOKEN
# eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### 2. Crear Usuario

```bash
curl -X POST http://localhost:8000/usuarios \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "nuevo@example.com",
    "password": "pass123",
    "role": "usuario"
  }' | jq

# Respuesta:
# {
#   "id": "550e8400-e29b-41d4-a716-446655440000",
#   "email": "nuevo@example.com",
#   "role": "usuario",
#   "status": "activo"
# }
```

### 3. Listar Usuarios

```bash
curl http://localhost:8000/usuarios \
  -H "Authorization: Bearer $TOKEN" | jq

# Respuesta: Lista de usuarios
```

### 4. Actualizar Usuario

```bash
curl -X PUT http://localhost:8000/usuarios/2 \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "role": "moderador",
    "status": "inactivo"
  }' | jq
```

### 5. Eliminar Usuario

```bash
curl -X DELETE http://localhost:8000/usuarios/2 \
  -H "Authorization: Bearer $TOKEN"

# Respuesta: {"message": "User deleted"}
```

---

## 🎨 Documentación Automática

### Swagger UI

```
http://localhost:8000/docs
```

Interfaz interactiva para probar endpoints. Incluye:
- Todos los endpoints
- Modelos de request/response
- Try it out para probar

### ReDoc

```
http://localhost:8000/redoc
```

Documentación estática y más limpia.

---

## 🐛 Troubleshooting

### Backend

#### Error: "Module not found: app"

```bash
# Asegúrate de estar en backend/
cd backend
uvicorn app.main:app --reload
```

#### Error: "Address already in use"

```bash
# Puerto 8000 ocupado, cambiar puerto
uvicorn app.main:app --reload --port 8001

# O matar proceso
lsof -i :8000
kill -9 <PID>
```

#### Tests fallan

```bash
# Limpiar caché
pytest --cache-clear
pytest tests/test_usuario_crud.py -v

# Con debug
pytest tests/test_usuario_crud.py -v -s
```

### Mobile

#### Error: "Connection refused"

```bash
# Backend no está corriendo
# Asegúrate que uvicorn esté corriendo en terminal aparte
# Terminal 1: backend
uvicorn app.main:app --reload

# Terminal 2: mobile
flutter run
```

#### Error: "CORS blocked"

```dart
# En app/lib/services/api_service.dart, verificar baseUrl
// Emulador Android
const String baseUrl = 'http://10.0.2.2:8000';

// Físico en red local
const String baseUrl = 'http://192.168.1.100:8000';

// Localhost (solo web)
const String baseUrl = 'http://localhost:8000';
```

---

## 📊 Estadísticas

| Métrica | Valor |
|---------|-------|
| Tests Backend | 27/27 ✅ |
| Tests Auth | 12/12 ✅ |
| Endpoints | 8 (5 CRUD + 3 Auth) |
| Modelos Flutter | 3 (Entity + Model + Mock) |
| Datasources | 2 (Real + Mock) |
| Líneas de Código | ~800 (backend) + ~600 (mobile) |

---

## 🎯 Próximos Pasos (Fase 4)

### Backend
- [ ] Implementar Vehiculo (mismo patrón)
- [ ] Implementar Estacion
- [ ] Implementar Alerta
- [ ] Implementar Reporte

### Mobile
- [ ] Crear screens para lista de usuarios
- [ ] Crear screen de detalles
- [ ] Integrar con provider state management
- [ ] Implementar crud UI

### DevOps
- [ ] Docker funcional con PostgreSQL
- [ ] Migraciones Alembic
- [ ] Seed scripts

---

## 📚 Referencias

- [FastAPI Docs](https://fastapi.tiangolo.com/)
- [Pydantic Docs](https://docs.pydantic.dev/)
- [SQLAlchemy Docs](https://docs.sqlalchemy.org/)
- [Flutter Clean Architecture](https://resocoder.com/flutter-clean-architecture)
- [Pytest Docs](https://docs.pytest.org/)

---

## ✅ Checklist Local Development

- [ ] Backend `.venv` creado y activado
- [ ] `pip install -r requirements.txt` completado
- [ ] `pip install -r requirements-dev.txt` completado
- [ ] `.env` configurado con `DATA_STORE=mock`
- [ ] Uvicorn corriendo en puerto 8000
- [ ] Health check respondiendo (GET /health)
- [ ] Tests pasando (`pytest tests/ -v`)
- [ ] Flutter `pub get` completado
- [ ] Mobile puede conectar a `http://10.0.2.2:8000`

---

## 🚀 Inicio Rápido (One Liner)

```bash
# Terminal 1: Backend
cd cargapp/backend && python -m venv .venv && source .venv/bin/activate && pip install -r requirements.txt && uvicorn app.main:app --reload

# Terminal 2: Tests
cd cargapp/backend && pytest tests/ -v

# Terminal 3: Mobile
cd cargapp/app && flutter run
```

---

**¡CargApp Fase 3 está lista para usar!** 🎉
