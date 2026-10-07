from sqlalchemy import Column, String, Boolean, DateTime, ForeignKey, Numeric, Date, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from datetime import datetime, date
import uuid

from app.core.database import Base


class Farm(Base):
    __tablename__ = "farms"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    resident_id = Column(UUID(as_uuid=True), ForeignKey("resident_profiles.id", ondelete="CASCADE"), nullable=False)
    farm_name = Column(String(150), default="Main Farm")
    land_acres = Column(Numeric(6, 2), nullable=False)
    soil_type = Column(String(50), default="unknown")  # black, red, loamy, clay, sandy, unknown
    water_source = Column(String(50), default="other")  # borewell, canal, rainfed, tank, other
    latitude = Column(Numeric(10, 7), nullable=True)
    longitude = Column(Numeric(10, 7), nullable=True)
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow)
    updated_at = Column(DateTime(timezone=True), default=datetime.utcnow, onupdate=datetime.utcnow)

    resident = relationship("ResidentProfile", back_populates="farms")
    crops = relationship("Crop", back_populates="farm", cascade="all, delete-orphan")


class Crop(Base):
    __tablename__ = "crops"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    farm_id = Column(UUID(as_uuid=True), ForeignKey("farms.id", ondelete="CASCADE"), nullable=False)
    crop_name = Column(String(100), nullable=False)
    variety = Column(String(100), nullable=True)
    sowing_date = Column(Date, nullable=False, default=date.today)
    current_stage = Column(String(50), default="sowing")  # sowing, germination, vegetative, flowering, maturity, harvest
    farming_goal = Column(String(255), nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow)
    updated_at = Column(DateTime(timezone=True), default=datetime.utcnow, onupdate=datetime.utcnow)

    farm = relationship("Farm", back_populates="crops")
    activities = relationship("CropActivity", back_populates="crop", cascade="all, delete-orphan")
    observations = relationship("CropObservation", back_populates="crop", cascade="all, delete-orphan")


class CropActivity(Base):
    __tablename__ = "crop_activities"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    crop_id = Column(UUID(as_uuid=True), ForeignKey("crops.id", ondelete="CASCADE"), nullable=False)
    activity_type = Column(String(100), nullable=False)  # irrigation, fertilizer, pesticide, weeding, soil_check
    description = Column(Text, nullable=True)
    cost_incurred = Column(Numeric(10, 2), default=0.0)
    performed_at = Column(DateTime(timezone=True), default=datetime.utcnow)
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow)

    crop = relationship("Crop", back_populates="activities")


class CropObservation(Base):
    __tablename__ = "crop_observations"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    crop_id = Column(UUID(as_uuid=True), ForeignKey("crops.id", ondelete="CASCADE"), nullable=False)
    observation_text = Column(Text, nullable=False)
    photo_url = Column(Text, nullable=True)
    ai_diagnosis_summary = Column(Text, nullable=True)
    severity_level = Column(String(50), default="mild")
    logged_at = Column(DateTime(timezone=True), default=datetime.utcnow)

    crop = relationship("Crop", back_populates="observations")


class FarmExpense(Base):
    __tablename__ = "farm_expenses"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    farm_id = Column(UUID(as_uuid=True), ForeignKey("farms.id", ondelete="CASCADE"), nullable=False)
    crop_id = Column(UUID(as_uuid=True), ForeignKey("crops.id", ondelete="SET NULL"), nullable=True)
    category = Column(String(100), nullable=False)  # seeds, fertilizer, labor, machinery, water
    amount = Column(Numeric(10, 2), nullable=False)
    expense_date = Column(Date, default=date.today)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow)
