# 🚗 CargApp — Sistema de Gestión de Estaciones de Carga

**CargApp** es una plataforma completa para gestión de estaciones de carga eléctrica, con soporte para usuarios, vehículos, alertas y reportes.

## 🎯 Stack Tecnológico

- **Backend**: FastAPI + PostgreSQL + SQLAlchemy
- **Mobile**: Flutter (iOS/Android)
- **Infrastructure**: Docker + Docker Compose
- **Patrón Arquitectónico**: Clean Architecture + Repository Pattern

## 📋 Características

- ✅ Autenticación JWT con roles (admin, distribuidor, usuario)
- ✅ Gestión de usuarios y perfiles
- ✅ Gestión de vehículos y asociación a usuarios
- ✅ Gestión de estaciones de carga
- ✅ Sistema de alertas (consumo, disponibilidad)
- ✅ Reportes y estadísticas
- ✅ Mock storage para desarrollo sin BD
- ✅ Migraciones automáticas (Alembic)

## 🚀 Inicio Rápido

### Backend

```bash
cd backend

# Setup venv
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# Instalar dependencias
pip install -r requirements.txt

# Configurar .env
cp .env.example .env

# Ejecutar servidor (con mock store, sin BD)
uvicorn app.main:app --reload
```

API: http://localhost:8000  
Docs: http://localhost:8000/docs

### Con Docker

```bash
cd infra
docker compose up -d
```

Base de datos y API levantarán juntas.

### Mobile

```bash
cd mobile
flutter pub get
flutter run
```

## 📚 Documentación

- [ROADMAP.md](docs/ROADMAP.md) — Plan de implementación fase a fase
- [ARQUITECTURA.md](docs/ARQUITECTURA.md) — Diseño, patrones y decisiones
- [backend/README.md](backend/README.md) — Setup y desarrollo del backend
- [mobile/README.md](mobile/README.md) — Setup y desarrollo del mobile

## 📁 Estructura

```
cargapp/
├── backend/              # FastAPI application
│   ├── app/              # Código principal
│   │   ├── api/          # Routers (auth, usuario, etc.)
│   │   ├── auth/         # Autenticación
│   │   ├── usuario/      # Lógica de usuarios
│   │   ├── vehiculo/     # Lógica de vehículos
│   │   ├── estacion/     # Lógica de estaciones
│   │   ├── alerta/       # Lógica de alertas
│   │   ├── reporte/      # Lógica de reportes
│   │   └── db/           # Base de datos
│   ├── migrations/       # Alembic (versionado de BD)
│   ├── tests/            # Tests
│   ├── requirements.txt  # Dependencias
│   └── .env.example      # Template de env vars
├── mobile/               # Flutter application
│   ├── lib/              # Código Dart
│   │   ├── features/     # Features (auth, usuario, etc.)
│   │   ├── core/         # Compartido (network, theme)
│   │   └── main.dart     # Entry point
│   ├── test/             # Tests Flutter
│   └── pubspec.yaml      # Dependencias Dart
├── infra/                # Docker Compose
│   ├── docker-compose.yml
│   └── README.md
├── docs/                 # Documentación
│   ├── ROADMAP.md
│   ├── ARQUITECTURA.md
│   └── ...
└── README.md             # Este archivo
```

## 🔐 Autenticación

Todos los endpoints (excepto `/auth/login` y `/auth/register`) requieren JWT:

```bash
# Login
curl -X POST http://localhost:8000/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"user@example.com","password":"123"}'

# Usar token
curl -H "Authorization: Bearer <token>" \
     http://localhost:8000/usuarios
```

## 🧪 Testing

### Backend
```bash
cd backend
pytest
pytest --cov=app
```

### Mobile
```bash
cd mobile
flutter test
```

## 📝 Decisiones Arquitectónicas Clave

1. **Factory Pattern** — Inyecta Mock vs SQL Store según config
2. **Repository Pattern** — Abstracción agnóstica de fuente de datos
3. **Clean Architecture** — Separación clara de capas
4. **Feature-driven (Mobile)** — Organización por funcionalidad
5. **JWT + Roles** — Autenticación y autorización
6. **Alembic** — Versionado seguro de migraciones

Ver [ARQUITECTURA.md](docs/ARQUITECTURA.md) para más detalles.

## 🐳 Deployment

### Local
```bash
cd infra
docker compose up -d
```

### Producción (Railway/Heroku)
- Configurar env vars en plataforma
- Push a repo → auto-deploy
- Variables requeridas:
  - `DATABASE_URL`
  - `JWT_SECRET`
  - `DEBUG=false`

## 🐛 Troubleshooting

**Backend no inicia:**
```bash
# Verificar Python
python --version  # Debe ser 3.11+

# Reinstalar dependencias
pip install --upgrade pip
pip install -r requirements.txt
```

**Error en migraciones:**
```bash
# Recrear desde cero
alembic downgrade base
alembic upgrade head
```

**Mobile no conecta a API:**
- Verificar que backend está corriendo: `http://localhost:8000/docs`
- Revisar endpoint en `lib/core/network/api_client.dart`

## 🛠️ Desarrollo

### Agregar nueva feature

1. Copiar estructura desde `backend/app/usuario/`
2. Crear routers en `backend/app/api/`
3. Agregar rutas en `app.main:app`
4. Crear tests en `backend/tests/`
5. Replicar en mobile con Clean Architecture

### Code style

```bash
cd backend
black app/
isort app/
flake8 app/
```

## 📞 Contacto & Soporte

Para documentación completa, ver [docs/](docs/).

---

**Última actualización**: Ruta de Restructuración iniciada  
**Estado**: ✅ Estructura lista, iniciando Fase 1 (Infraestructura Base)
