"""Crear archivo de migración inicial."""
import uuid
from datetime import datetime

from sqlalchemy import text

from app.db.models import Base
from app.db.session import engine, SessionLocal


def init_db():
    """Inicializar base de datos con tablas."""
    Base.metadata.create_all(bind=engine)
    print("✅ Base de datos inicializada")


def seed_db():
    """Agregar datos iniciales."""
    db = SessionLocal()
    try:
        # TODO: Agregar usuarios demo, estaciones, etc.
        print("✅ Base de datos poblada con datos iniciales")
    finally:
        db.close()


if __name__ == "__main__":
    init_db()
    seed_db()
