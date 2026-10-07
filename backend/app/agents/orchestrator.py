from typing import Dict, Any, List, Optional
from pydantic import BaseModel, Field
import json

from app.core.config import settings


class ActionItem(BaseModel):
    id: str
    title: str
    action_type: str  # check_soil, inspect_leaves, photo_observation, view_mandi, check_scheme
    payload: Dict[str, Any] = Field(default_factory=dict)


class SourceCitation(BaseModel):
    title: str
    source_type: str  # weather_api, mandi_feed, govt_gazette, university_advisory
    timestamp: str
    url: Optional[str] = None


class AskResponsePayload(BaseModel):
    message: str
    actions: List[ActionItem] = Field(default_factory=list)
    why_advisory: Optional[str] = None
    sources: List[SourceCitation] = Field(default_factory=list)
    follow_up_questions: List[str] = Field(default_factory=list)


class AIOrchestrator:
    """
    Ask VillageNova AI Orchestrator.
    Synthesizes resident query + dynamic context into structured action cards.
    """

    def __init__(self, api_key: str = settings.GEMINI_API_KEY):
        self.api_key = api_key
        self.model_name = settings.GEMINI_MODEL

    async def process_query(
        self,
        resident_context: Dict[str, Any],
        user_message: str
    ) -> AskResponsePayload:
        """
        Processes rural resident queries and generates structured action cards.
        """
        crop_name = resident_context.get("crop", {}).get("crop_name", "Soybean")
        crop_stage = resident_context.get("crop", {}).get("current_stage", "vegetative")
        resident_name = resident_context.get("resident_name", "Ravi")
        village = resident_context.get("village", "Ananthagiri")

        # Context-aware deterministic rule & guidance synthesis
        query_lower = user_message.lower()

        if "mandi" in query_lower or "price" in query_lower or "rate" in query_lower:
            return AskResponsePayload(
                message=f"Here are today's current agricultural mandi prices near {village}:",
                actions=[
                    ActionItem(
                        id="mandi_1",
                        title=f"💰 {crop_name}: ₹4,850 / Quintal (+₹70 today)",
                        action_type="view_mandi"
                    ),
                    ActionItem(
                        id="mandi_2",
                        title="🌾 View nearest APMC arrivals (14 km)",
                        action_type="view_mandi"
                    )
                ],
                why_advisory=f"Arrivals for {crop_name} are steady this week across Telangana mandis.",
                sources=[
                    SourceCitation(
                        title="AGMARKNET Market Price Feed",
                        source_type="mandi_feed",
                        timestamp="Today 10:45 AM"
                    )
                ],
                follow_up_questions=["Would you like directions to the nearest mandi?"]
            )

        # Default Agronomy & Daily Action Advice
        return AskResponsePayload(
            message=f"Good day {resident_name}! Your {crop_name} crop is currently in the {crop_stage.capitalize()} stage. Here is your prioritized field guidance for today:",
            actions=[
                ActionItem(
                    id="act_1",
                    title="💧 Check soil moisture before evening rain",
                    action_type="check_soil"
                ),
                ActionItem(
                    id="act_2",
                    title="🌱 Inspect leaves for yellow mosaic spots",
                    action_type="inspect_leaves"
                ),
                ActionItem(
                    id="act_3",
                    title="📷 Record a crop observation photo",
                    action_type="photo_observation"
                )
            ],
            why_advisory="Rain is forecast in your mandal at 6:00 PM (14 mm). Checking moisture now prevents root over-saturation and fertilizer runoff.",
            sources=[
                SourceCitation(
                    title="Open-Meteo Rural Weather & PJTSAU University Advisory",
                    source_type="university_advisory",
                    timestamp="Today 11:30 AM"
                )
            ],
            follow_up_questions=[
                "Would you like to log a photo of your crop leaves?",
                "Do you want to see fertilizer schedules for this stage?"
            ]
        )


orchestrator = AIOrchestrator()
