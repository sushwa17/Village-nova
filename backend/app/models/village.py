from sqlalchemy import Column, String, Boolean, DateTime, ForeignKey, Text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from datetime import datetime
import uuid

from app.core.database import Base


class VillageUpdate(Base):
    __tablename__ = "village_updates"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    village_id = Column(UUID(as_uuid=True), ForeignKey("villages.id", ondelete="CASCADE"), nullable=False)
    author_id = Column(UUID(as_uuid=True), ForeignKey("resident_profiles.id", ondelete="SET NULL"), nullable=True)
    category = Column(String(50), nullable=False)  # panchayat, agriculture, education, emergency, community
    title = Column(String(255), nullable=False)
    content = Column(Text, nullable=False)
    is_emergency = Column(Boolean, default=False)
    is_verified = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow)

    village = relationship("Village", back_populates="updates")
