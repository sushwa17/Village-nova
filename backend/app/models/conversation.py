from sqlalchemy import Column, String, DateTime, ForeignKey, Text
from sqlalchemy.dialects.postgresql import UUID, JSONB
from sqlalchemy.orm import relationship
from datetime import datetime
import uuid

from app.core.database import Base


class Conversation(Base):
    __tablename__ = "conversations"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    resident_id = Column(UUID(as_uuid=True), ForeignKey("resident_profiles.id", ondelete="CASCADE"), nullable=False)
    title = Column(String(255), default="Chat with VillageNova")
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow)
    updated_at = Column(DateTime(timezone=True), default=datetime.utcnow, onupdate=datetime.utcnow)

    resident = relationship("ResidentProfile", back_populates="conversations")
    messages = relationship("Message", back_populates="conversation", cascade="all, delete-orphan")


class Message(Base):
    __tablename__ = "messages"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    conversation_id = Column(UUID(as_uuid=True), ForeignKey("conversations.id", ondelete="CASCADE"), nullable=False)
    sender_type = Column(String(20), nullable=False)  # user, assistant, system
    content = Column(Text, nullable=False)
    actions = Column(JSONB, default=list)
    sources = Column(JSONB, default=list)
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow)
    conversation = relationship("Conversation", back_populates="messages")
    tool_calls = relationship("AIToolCall", back_populates="message", cascade="all, delete-orphan")


class AIToolCall(Base):
    __tablename__ = "ai_tool_calls"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    message_id = Column(UUID(as_uuid=True), ForeignKey("messages.id", ondelete="CASCADE"), nullable=True)
    tool_name = Column(String(100), nullable=False)
    tool_input = Column(JSONB, default=dict)
    tool_output = Column(JSONB, default=dict)
    execution_time_ms = Column(String(20), default="0.0")
    status = Column(String(20), default="success")  # success, error, fallback
    created_at = Column(DateTime(timezone=True), default=datetime.utcnow)

    message = relationship("Message", back_populates="tool_calls")
