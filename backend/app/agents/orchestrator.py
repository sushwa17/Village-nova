from typing import Dict, Any, List, Optional
from pydantic import BaseModel, Field


class ToolCallDefinition(BaseModel):
    name: str
    description: str
    parameters: Dict[str, Any]


class ActionItem(BaseModel):
    id: str
    title: str
    action_type: str  # log_activity, add_observation, add_expense, view_scheme, set_reminder
    payload: Dict[str, Any] = Field(default_factory=dict)


class SourceCitation(BaseModel):
    title: str
    source_type: str  # weather_api, mandi_feed, govt_gazette, university_advisory
    timestamp: str
    url: Optional[str] = None


class AskResponsePayload(BaseModel):
    message: str
    actions: List[ActionItem] = Field(default_factory=list)
    sources: List[SourceCitation] = Field(default_factory=list)
    follow_up_questions: List[str] = Field(default_factory=list)


class AIOrchestratorInterface:
    """
    Abstract interface for Ask VillageNova Orchestrator.
    Handles user intent, context assembly, tool selection, and structured card synthesis.
    """
    async def process_query(
        self,
        resident_id: str,
        message: str,
        conversation_id: Optional[str] = None
    ) -> AskResponsePayload:
        raise NotImplementedError("Orchestrator implementation required")
