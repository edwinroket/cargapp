# 🗺️ Roadmap de Restructuración de CargApp

## Objetivo
Transformar CargApp de una arquitectura básica/inconsistente a una arquitectura profesional escalable basada en **FastAPI + Flutter Clean Architecture**, tomando a **Gastracer** como modelo.

---

## 📋 Fases de Implementación

### **FASE 0: Análisis y Planificación** ✅ COMPLETADA
- [x] Análisis de estructura actual (Express + Flutter)
- [x] Identificación de problemas
- [x] Diseño de nueva arquitectura
- [x] Creación de estructura de carpetas

---

## **FASE 1: Infraestructura Base** (Semana 1-2)

### Backend
- [ ] **1.1** Crear `requirements.txt` con dependencias FastAPI
  - `fastapi>=0.104.0`
  - `uvicorn[standard]>=0.24.0`
  - `sqlalchemy>=2.0.0`
  - `alembic>=1.13.0`
  - `pydantic>=2.0.0`
  - `pydantic-settings>=2.0.0`
  - `python-jose[cryptography]>=3.3.0`
  - `passlib[bcrypt]>=1.7.4`
  - `python-multipart>=0.0.6`
  - `pytest>=7.4.0`
  - `pytest-asyncio>=0.21.0`

- [ ] **1.2** Crear `config.py`
  ```python
  # Settings desde .env
  # - DATABASE_URL
  # - JWT_SECRET
  # - DATA_STORE (sql|mock)
  # - DEBUG
  ```

- [ ] **1.3** Crear `main.py` con app FastAPI
  ```python
  # - Factory Pattern para inyectar stores
  # - CORS habilitado
  # - Health check endpoint
  # - Mount routers por dominio
  ```

- [ ] **1.4** Crear `db/models.py` con SQLAlchemy
  ```python
  # Models principales:
  # - UserModel (id, email, password_hash, role, status, created_at, updated_at)
  # - VehicleModel (id, user_id, name, status, license_plate)
  # - StationModel (id, name, location, status)
  # - AlertModel (id, vehicle_id, severity, status)
  # - ReportModel (id, vehicle_id, data, created_at)
  ```

- [ ] **1.5** Crear `db/session.py`
  ```python
  # SessionLocal para conexiones
  # get_db dependency
  ```

- [ ] **1.6** Crear `.env.example`
  ```
  DATABASE_URL=postgresql://user:password@localhost/cargapp
  JWT_SECRET=your-secret-key-here
  DATA_STORE=sql
  DEBUG=true
  ```

- [ ] **1.7** Crear `.gitignore`
  ```
  .env
  __pycache__/
  *.pyc
  .pytest_cache/
  .venv/
  node_modules/
  build/
  ```

### Mobile
- [ ] **1.8** Crear `lib/main.dart` base
- [ ] **1.9** Crear `lib/app/cargapp.dart` con MaterialApp
- [ ] **1.10** Crear `lib/core/network/api_client.dart` base

### Documentación
- [ ] **1.11** Crear `docs/ARQUITECTURA.md` con diagrama de capas

---

## **FASE 2: Autenticación** (Semana 2-3)

### Backend
- [ ] **2.1** Crear `auth/jwt.py`
  ```python
  # create_access_token(user_id: str, expires_delta: timedelta)
  # decode_token(token: str) -> dict
  ```

- [ ] **2.2** Crear `auth/passwords.py`
  ```python
  # hash_password(password: str) -> str
  # verify_password(plain: str, hashed: str) -> bool
  ```

- [ ] **2.3** Crear `auth/dependencies.py`
  ```python
  # get_current_user(token: str = Depends(HTTPBearer()))
  # require_roles(allowed_roles: set) -> Depends
  ```

- [ ] **2.4** Crear `auth/mock_store.py` y `sql_store.py`
  ```python
  # Interface AuthStore con métodos:
  # - authenticate(email, password) -> User | None
  # - create_user(email, password, role) -> User
  # - get_user(user_id) -> User | None
  # - current_user(token) -> User | None
  ```

- [ ] **2.5** Crear `api/auth.py` router
  ```python
  # POST /auth/register → crear usuario
  # POST /auth/login → generar JWT
  # POST /auth/logout → invalidar token
  # GET /auth/me → usuario actual
  ```

- [ ] **2.6** Crear modelos Pydantic en `usuario/schemas.py`
  ```python
  # UserRegister, UserLogin, UserResponse, UserUpdate
  ```

### Mobile
- [ ] **2.7** Crear `features/auth/data/auth_repository.dart` (interfaz)
- [ ] **2.8** Crear `features/auth/data/auth_api_repository.dart`
  ```dart
  # register(email, password) -> Future<AuthResponse>
  # login(email, password) -> Future<AuthResponse>
  # logout() -> Future<void>
  # getCurrentUser() -> Future<User>
  ```

- [ ] **2.9** Crear `features/auth/data/auth_mock_repository.dart`
  ```dart
  # Implementación con datos hardcoded
  ```

- [ ] **2.10** Crear `features/auth/domain/entities/user.dart`
  ```dart
  # User(id, email, role, status)
  ```

- [ ] **2.11** Crear `features/auth/presentation/login_screen.dart`

---

## **FASE 3: Usuarios** (Semana 3)

### Backend
- [ ] **3.1** Crear `usuario/schemas.py`
  ```python
  # UsuarioCreate, UsuarioUpdate, UsuarioResponse
  ```

- [ ] **3.2** Crear `usuario/mock_store.py` y `sql_store.py`
  ```python
  # create_usuario, get_usuario, list_usuarios, update_usuario, delete_usuario
  ```

- [ ] **3.3** Crear `api/usuario.py` router
  ```python
  # GET /usuarios → listar
  # GET /usuarios/{id} → detalle
  # PUT /usuarios/{id} → actualizar
  # DELETE /usuarios/{id} → eliminar
  ```

- [ ] **3.4** Crear tests en `tests/test_usuario_api.py`

### Mobile
- [ ] **3.5** Crear repository, domain, presentation para usuario

---

## **FASE 4: Vehículos** (Semana 4)

### Backend
- [ ] **4.1** Crear `vehiculo/schemas.py`
- [ ] **4.2** Crear `vehiculo/mock_store.py` y `sql_store.py`
- [ ] **4.3** Crear `api/vehiculo.py` router
- [ ] **4.4** Tests

### Mobile
- [ ] **4.5** Crear feature completa vehículo

---

## **FASE 5: Estaciones y Alertas** (Semana 5)

### Backend
- [ ] **5.1** Crear `estacion/` feature completa
- [ ] **5.2** Crear `alerta/` feature completa
- [ ] **5.3** Lógica de alertas (notificaciones, filtros)

### Mobile
- [ ] **5.4** Crear features estación y alerta

---

## **FASE 6: Reportes y Análisis** (Semana 6)

### Backend
- [ ] **6.1** Crear `reporte/` feature
- [ ] **6.2** Agregaciones y estadísticas

### Mobile
- [ ] **6.3** Crear feature reporte con gráficos

---

## **FASE 7: Migraciones y Base de Datos** (Semana 7)

- [ ] **7.1** Configurar Alembic
- [ ] **7.2** Crear primera migración (init)
- [ ] **7.3** Crear migraciones por feature
- [ ] **7.4** Script de seed (datos iniciales)

---

## **FASE 8: Docker y Infraestructura** (Semana 8)

### infra/
- [ ] **8.1** Crear `docker-compose.yml`
  ```yaml
  services:
    postgres:
      image: postgres:16-alpine
      environment:
        POSTGRES_DB: cargapp
        POSTGRES_PASSWORD: cargapp
      ports:
        - "5432:5432"
    
    api:
      build: ../backend
      ports:
        - "8000:8000"
      depends_on:
        - postgres
      environment:
        DATABASE_URL: postgresql://postgres:cargapp@postgres/cargapp
  ```

- [ ] **8.2** Crear `Dockerfile` para FastAPI
- [ ] **8.3** Crear `.dockerignore`

### Backend
- [ ] **8.4** Crear `requirements-dev.txt` (dev dependencies)
- [ ] **8.5** Script de setup local

---

## **FASE 9: Testing e Integración** (Semana 9)

- [ ] **9.1** Tests unitarios para auth
- [ ] **9.2** Tests de integración API
- [ ] **9.3** Tests de repositorio (mock vs SQL)
- [ ] **9.4** Tests Flutter

---

## **FASE 10: Documentación Final** (Semana 10)

### docs/
- [ ] **10.1** Crear `ARQUITECTURA.md` completo
  - Diagrama de capas
  - Explicación de patrones
  - Ejemplos de código

- [ ] **10.2** Crear `API.md`
  - OpenAPI/Swagger auto-generado desde FastAPI
  - Ejemplos de requests/responses

- [ ] **10.3** Crear `MOBILE.md`
  - Estructura de features
  - Patrón Repository

- [ ] **10.4** Crear `SETUP.md`
  - Instrucciones de desarrollo
  - Docker setup

---

## 📊 Comparativa Antes vs Después

| Aspecto | ANTES (Express) | DESPUÉS (FastAPI) |
|--------|---|---|
| **Framework** | Express (Node.js) | FastAPI (Python) |
| **Validación API** | Manual (Joi/express-validator) | ✅ Automática (Pydantic) |
| **Documentación API** | Manual (Swagger) | ✅ Automática (OpenAPI) |
| **ORM** | Sequelize/manual | ✅ SQLAlchemy + tipos |
| **Migrations** | db-migrate | ✅ Alembic (versionado) |
| **Async/Await** | Soportado | ✅ Nativo |
| **Type hints** | No | ✅ Sí (MyPy) |
| **Testing** | Jest | ✅ Pytest |
| **Inyección dependencias** | Manual | ✅ FastAPI.Depends |
| **Secretos en repo** | ❌ .env público | ✅ .env.example |
| **package.json corrupto** | ❌ Sí | ✅ requirements.txt correcto |

---

## ⚠️ Puntos Críticos

1. **Migración de datos**: Si ya hay datos, necesitamos script de migración Express → FastAPI
2. **JWT compatibility**: Asegurar que tokens nuevos sean compatibles
3. **API endpoints**: Mantener URLs consistentes para no romper mobile
4. **Base de datos**: Creación de schema desde modelos SQLAlchemy

---

## 🎯 Hitos Clave

- **Semana 2**: Backend + Auth funcionando
- **Semana 4**: Backend + Mobile auth integrados
- **Semana 6**: CRUD completo de features
- **Semana 8**: Docker corriendo
- **Semana 10**: Deploy listo

---

## ✅ Checklist General

- [ ] Estructura de carpetas completa
- [ ] Backend ejecutándose localmente
- [ ] Mobile conectada a backend
- [ ] Tests pasando
- [ ] Docker funcional
- [ ] Documentación actualizada
- [ ] Secretos sacados del repo
- [ ] Ready para producción
