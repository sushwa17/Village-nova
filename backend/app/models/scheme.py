from sqlalchemy import Column, String, Boolean, DateTime, ForeignKey, Numeric, Date, Text
from sqlalchemy.dialects.postgresql import UUID, JSONB, ARRAY
from datetime import datetime
import uuid

from app.core.database import Base


class Scheme(Base):
    __tablename__ = "schemes"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    scheme_code = Column(String(100), unique=True, nullable=False)
    title = Column(String(255), nullable=False)
    department = Column(String(200), nullable=False)
    description = Column(Text, nullable=False)
    target_roles = Column(ARRAY(String), default=list)
    eligibility_criteria = Column(JSONB, default=dict)
    required_documents = Column(ARRAY(String), default=list)
    official_portal_url = Column(Text, nullable=True)
    deadline = Column(Date, nullable=True)
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow)


class SchemeMatch(Base):
    __tablename__ = "scheme_matches"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    resident_id = Column(UUID(as_uuid=True), ForeignKey("resident_profiles.id", ondelete="CASCADE"), nullable=False)
    scheme_id = Column(UUID(as_uuid=True), ForeignKey("schemes.id", ondelete="CASCADE"), nullable=False)
    match_status = Column(String(50), default="potentially_eligible")  # eligible, potentially_eligible, applied
    match_score = Column(Numeric(5, 2), default=0.0)
    match_reasons = Column(ARRAY(String), default=list)
    is_saved = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow)
