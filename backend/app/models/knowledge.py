from sqlalchemy import Column, String, DateTime, Text, Boolean, Float, JSON
from sqlalchemy.dialects.postgresql import UUID
from datetime import datetime
import uuid

from app.core.database import Base


class KnowledgeChunk(Base):
    """
    Official Knowledge Base chunk with semantic vector embedding (pgvector).
    Stores agricultural university advisories, government scheme gazettes,
    and market standards for AI grounding and hallucination prevention.
    """
    __tablename__ = "knowledge_chunks"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    document_title = Column(String(255), nullable=False)
    authority = Column(String(255), nullable=False)  # PJTSAU, ICAR, Central Govt, APMC
    domain = Column(String(50), nullable=False, index=True)  # agronomy, schemes, weather, mandi
    chunk_text = Column(Text, nullable=False)
    embedding = Column(JSON, nullable=True)  # Vector representation (array of floats)
    official_url = Column(String(500), nullable=True)
    published_date = Column(String(50), nullable=False)
    is_verified = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow)
