# CargApp Backend — FastAPI

Backend API para CargApp desarrollado con **FastAPI** + **PostgreSQL** + **SQLAlchemy**.

## 📋 Stack Tecnológico

- **Framework**: FastAPI (ASGI)
- **Server**: Uvicorn
- **ORM**: SQLAlchemy 2.0
- **Migraciones**: Alembic
- **Validación**: Pydantic
- **Auth**: JWT + bcrypt
- **Base de datos**: PostgreSQL

## 🚀 Inicio Rápido

### Requisitos
- Python 3.11+
- PostgreSQL 14+
- pip o poetry

### Instalación

```bash
# 1. Clonar repo
cd backend

# 2. Crear venv
python -m venv venv
source venv/bin/activate  # En Windows: venv\Scripts\activate

# 3. Instalar dependencias
pip install -r requirements.txt

# 4. Configurar .env
cp .env.example .env
# Editar .env con tus valores

# 5. Ejecutar migraciones
alembic upgrade head

# 6. Ejecutar servidor
uvicorn app.main:app --reload
```

La API estará disponible en http://localhost:8000

## 📚 Documentación

- **Swagger UI**: http://localhost:8000/docs
- **ReDoc**: http://localhost:8000/redoc
- [ARQUITECTURA.md](../docs/ARQUITECTURA.md) — Diseño y patrones
- [API.md](../docs/API.md) — Endpoints y ejemplos

## 📁 Estructura

```
app/
├── main.py              # Punto entrada
├── config.py            # Settings (.env)
├── health.py            # GET /health
├── api/                 # Routers por dominio
│   ├── auth.py
│   ├── usuario.py
│   ├── vehiculo.py
│   ├── estacion.py
│   ├── alerta.py
│   └── reporte.py
├── auth/                # Autenticación
│   ├── jwt.py
│   ├── passwords.py
│   ├── dependencies.py
│   ├── mock_store.py
│   └── sql_store.py
├── usuario/, vehiculo/, etc/  # Lógica por dominio
└── db/                  # Capa datos
    ├── models.py        # SQLAlchemy ORM
    ├── session.py
    └── base.py
```

## 🔐 Autenticación

Todos los endpoints (excepto `/auth/login` y `/auth/register`) requieren JWT:

```bash
curl -H "Authorization: Bearer <token>" \
     http://localhost:8000/usuarios
```

## 🧪 Testing

```bash
# Ejecutar todos los tests
pytest

# Con coverage
pytest --cov=app

# En modo watch
pytest --watch
```

## 📦 Docker

```bash
cd infra
docker compose up -d

# La API estará en http://localhost:8000
```

## 🌱 Base de Datos

### Inicializar schema

```bash
alembic upgrade head
```

### Crear nueva migración

```bash
alembic revision --autogenerate -m "descripción"
alembic upgrade head
```

## 🛠️ Desarrollo

### Formato de código

```bash
# Black formatter
black app/

# isort para imports
isort app/

# flake8 para linting
flake8 app/

# mypy para type checking
mypy app/
```

### Todo en uno

```bash
make format
make lint
make test
```

## 📝 Decisiones Arquitectónicas

- **Factory Pattern**: Inyecta Mock vs SQL Store según config
- **Dependency Injection**: FastAPI.Depends para guards de autenticación
- **Repository Pattern**: Interfaz agnóstica a la fuente de datos
- **Clean Architecture**: Separación clara de capas (api → auth/dominio → db)

Ver [ARQUITECTURA.md](../docs/ARQUITECTURA.md) para más detalles.

## 🐛 Troubleshooting

**Error: "could not connect to server"**
- Verificar que PostgreSQL está corriendo
- Revisar DATABASE_URL en .env

**Error: "Unknown table name"**
- Ejecutar: `alembic upgrade head`

**Error: "JWT token expired"**
- Generar nuevo token con `POST /auth/login`

## 📞 Soporte

Ver [docs/](../docs/) para documentación completa.
