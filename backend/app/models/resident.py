from sqlalchemy import Column, String, Boolean, DateTime, ForeignKey, Numeric
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from datetime import datetime
import uuid

from app.core.database import Base


class Village(Base):
    __tablename__ = "villages"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    name = Column(String(150), nullable=False)
    mandal = Column(String(150), nullable=False)
    district = Column(String(150), nullable=False)
    state = Column(String(150), nullable=False)
    pincode = Column(String(10), nullable=True)
    latitude = Column(Numeric(10, 7), nullable=True)
    longitude = Column(Numeric(10, 7), nullable=True)
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow)

    residents = relationship("ResidentProfile", back_populates="village")
    updates = relationship("VillageUpdate", back_populates="village")


class ResidentProfile(Base):
    __tablename__ = "resident_profiles"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    full_name = Column(String(150), nullable=False)
    phone_number = Column(String(20), nullable=True)
    village_id = Column(UUID(as_uuid=True), ForeignKey("villages.id", ondelete="SET NULL"), nullable=True)
    preferred_language = Column(String(20), default="en")
    verified_badge = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow)
    updated_at = Column(DateTime(timezone=True), default=datetime.utcnow, onupdate=datetime.utcnow)

    village = relationship("Village", back_populates="residents")
    roles = relationship("ResidentRole", back_populates="resident", cascade="all, delete-orphan")
    farms = relationship("Farm", back_populates="resident", cascade="all, delete-orphan")
    tasks = relationship("Task", back_populates="resident", cascade="all, delete-orphan")
    conversations = relationship("Conversation", back_populates="resident", cascade="all, delete-orphan")


class ResidentRole(Base):
    __tablename__ = "resident_roles"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    resident_id = Column(UUID(as_uuid=True), ForeignKey("resident_profiles.id", ondelete="CASCADE"), nullable=False)
    role = Column(String(50), nullable=False)  # farmer, cattle_owner, student, job_seeker, etc.
    is_primary = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow)

    resident = relationship("ResidentProfile", back_populates="roles")
