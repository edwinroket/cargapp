"""Database models using SQLAlchemy ORM."""
from datetime import datetime

from sqlalchemy import Column, DateTime, String, Index
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import declarative_mixin

from app.db.session import Base


@declarative_mixin
class TimestampMixin:
    """Mixin that adds created_at and updated_at timestamps."""

    created_at = Column(
        DateTime,
        default=datetime.utcnow,
        nullable=False,
    )
    updated_at = Column(
        DateTime,
        default=datetime.utcnow,
        onupdate=datetime.utcnow,
        nullable=False,
    )


class UserModel(TimestampMixin, Base):
    """User model."""

    __tablename__ = "users"

    id = Column(String(64), primary_key=True)
    email = Column(String(255), unique=True, nullable=False, index=True)
    password_hash = Column(String(255), nullable=False)
    role = Column(String(32), nullable=False, index=True)  # admin, distribuidor, usuario
    status = Column(String(32), nullable=False, default="activo")

    __table_args__ = (
        Index("ix_users_email_role", "email", "role"),
    )


class VehicleModel(TimestampMixin, Base):
    """Vehicle model."""

    __tablename__ = "vehicles"

    id = Column(String(64), primary_key=True)
    user_id = Column(String(64), nullable=False, index=True)
    name = Column(String(255), nullable=False)
    license_plate = Column(String(32), unique=True, nullable=True)
    status = Column(String(32), nullable=False, default="activo")

    __table_args__ = (
        Index("ix_vehicles_user_id_status", "user_id", "status"),
    )


class StationModel(TimestampMixin, Base):
    """Charging station model."""

    __tablename__ = "stations"

    id = Column(String(64), primary_key=True)
    name = Column(String(255), nullable=False, index=True)
    location = Column(String(255), nullable=False)
    status = Column(String(32), nullable=False, default="activo")


class AlertModel(TimestampMixin, Base):
    """Alert model."""

    __tablename__ = "alerts"

    id = Column(String(64), primary_key=True)
    vehicle_id = Column(String(64), nullable=False, index=True)
    severity = Column(String(32), nullable=False)  # critical, warning, info
    status = Column(String(32), nullable=False, default="open")

    __table_args__ = (
        Index("ix_alerts_vehicle_id_status", "vehicle_id", "status"),
    )


class ReportModel(TimestampMixin, Base):
    """Report model."""

    __tablename__ = "reports"

    id = Column(String(64), primary_key=True)
    vehicle_id = Column(String(64), nullable=False, index=True)
    data = Column(String(4096), nullable=False)  # JSON as string
