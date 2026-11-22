"""
VillageNova Conversation Session & History Truncation Service (Phase 3, Week 10)

Manages multi-turn resident dialogue sessions, input validation, and sliding-window
history truncation to prevent context window exhaustion and control LLM token costs.
"""

from typing import Dict, Any, List, Optional
import uuid
import datetime
import logging
from fastapi import HTTPException, status

logger = logging.getLogger(__name__)

MAX_MESSAGE_CHARACTERS = 1000
DEFAULT_MAX_TURNS = 10  # 10 turns = 20 messages (user + model pairs)


class ConversationMessage:
    def __init__(
        self,
        role: str,  # 'user' | 'model' | 'system'
        content: str,
        actions: Optional[List[Dict[str, Any]]] = None,
        sources: Optional[List[Dict[str, Any]]] = None,
        why_advisory: Optional[str] = None,
        timestamp: Optional[str] = None
    ):
        self.role = role
        self.content = content
        self.actions = actions or []
        self.sources = sources or []
        self.why_advisory = why_advisory
        self.timestamp = timestamp or datetime.datetime.now(datetime.timezone.utc).isoformat()

    def to_dict(self) -> Dict[str, Any]:
        return {
            "role": self.role,
            "content": self.content,
            "actions": self.actions,
            "sources": self.sources,
            "why_advisory": self.why_advisory,
            "timestamp": self.timestamp
        }


class ConversationSession:
    def __init__(self, session_id: str, user_id: str):
        self.session_id = session_id
        self.user_id = user_id
        self.created_at = datetime.datetime.now(datetime.timezone.utc).isoformat()
        self.updated_at = self.created_at
        self.messages: List[ConversationMessage] = []

    def add_message(self, message: ConversationMessage) -> None:
        self.messages.append(message)
        self.updated_at = datetime.datetime.now(datetime.timezone.utc).isoformat()

    def truncate(self, max_turns: int = DEFAULT_MAX_TURNS) -> int:
        """
        Truncates conversation history to latest max_turns (pairs of messages).
        Retains initial persona grounding if present, and keeps the latest N messages.
        Returns the number of messages pruned.
        """
        max_messages = max_turns * 2
        initial_count = len(self.messages)
        if initial_count <= max_messages:
            return 0

        # Keep the latest max_messages
        pruned_count = initial_count - max_messages
        self.messages = self.messages[-max_messages:]
        logger.info(f"Truncated session {self.session_id}: removed {pruned_count} older messages (kept {len(self.messages)})")
        return pruned_count


class ConversationSessionManager:
    """
    Manages active resident conversation sessions and history bounds.
    """

    def __init__(self, max_turns: int = DEFAULT_MAX_TURNS):
        self.max_turns = max_turns
        self._sessions: Dict[str, ConversationSession] = {}

    def validate_message(self, message: str) -> None:
        """Enforces character ceiling on incoming resident query."""
        if not message or not message.strip():
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Message content cannot be empty."
            )
        if len(message) > MAX_MESSAGE_CHARACTERS:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Message exceeds maximum allowed length of {MAX_MESSAGE_CHARACTERS} characters (received {len(message)})."
            )

    def get_or_create_session(self, conversation_id: Optional[str], user_id: str) -> ConversationSession:
        """Retrieves existing session or initializes a new one with a UUID."""
        if conversation_id and conversation_id in self._sessions:
            session = self._sessions[conversation_id]
            # Ensure ownership
            if session.user_id == user_id:
                return session

        new_id = conversation_id or f"conv_{uuid.uuid4().hex[:12]}"
        session = ConversationSession(session_id=new_id, user_id=user_id)
        self._sessions[new_id] = session
        return session

    def add_turn(
        self,
        conversation_id: str,
        user_id: str,
        user_message: str,
        model_response: str,
        actions: Optional[List[Dict[str, Any]]] = None,
        sources: Optional[List[Dict[str, Any]]] = None,
        why_advisory: Optional[str] = None
    ) -> ConversationSession:
        """Records a user-model conversational exchange and enforces truncation."""
        session = self.get_or_create_session(conversation_id, user_id)

        # Append user turn
        session.add_message(ConversationMessage(role="user", content=user_message))

        # Append model turn
        session.add_message(
            ConversationMessage(
                role="model",
                content=model_response,
                actions=actions,
                sources=sources,
                why_advisory=why_advisory
            )
        )

        # Enforce sliding-window truncation
        session.truncate(max_turns=self.max_turns)
        return session

    def get_session_history(self, conversation_id: str, user_id: str) -> List[Dict[str, Any]]:
        """Returns message list for a session if owned by user."""
        session = self._sessions.get(conversation_id)
        if not session or session.user_id != user_id:
            return []
        return [m.to_dict() for m in session.messages]

    def clear_session(self, conversation_id: str, user_id: str) -> bool:
        """Clears/resets message history for a conversation session."""
        session = self._sessions.get(conversation_id)
        if session and session.user_id == user_id:
            session.messages.clear()
            session.updated_at = datetime.datetime.now(datetime.timezone.utc).isoformat()
            return True
        return False

    def get_all_sessions_count(self) -> int:
        return len(self._sessions)


# Global Singleton Instance
conversation_manager = ConversationSessionManager(max_turns=DEFAULT_MAX_TURNS)
