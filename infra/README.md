# 🐳 Infraestructura — Docker Compose

Setup local completo de CargApp en Docker.

## 📋 Requisitos

- Docker 20.10+
- Docker Compose 2.0+

## 🚀 Inicio Rápido

```bash
# Levantar servicios
docker compose up -d

# Ver logs
docker compose logs -f api

# Detener
docker compose down
```

## 🏗️ Servicios

- **postgres**: Base de datos (puerto 5432)
- **api**: Backend FastAPI (puerto 8000)

## 📊 Acceso

- API: http://localhost:8000
- Swagger: http://localhost:8000/docs
- PostgreSQL: `postgresql://postgres:cargapp@localhost:5432/cargapp`

## 🔧 Configuración

Ver `docker-compose.yml` para variables de entorno.

## 📝 Notas

- Primera vez: `docker compose up` crea las tablas automáticamente
- Volúmenes: Los datos de la BD persisten en `postgres_data/`
- Red: Los servicios se comunican por la red interna de Docker
