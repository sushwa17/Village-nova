from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field
from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import get_current_user, AuthenticatedResident
from app.agents.context_builder import build_resident_context
from app.agents.orchestrator import orchestrator, AskResponsePayload
from app.schemas.common import APIResponse

router = APIRouter(prefix="/ask", tags=["Ask VillageNova AI"])


class AskRequestPayload(BaseModel):
    message: str = Field(min_length=1, example="What should I do on my farm today?")
    conversation_id: Optional[str] = None
    language: Optional[str] = Field(default="en", example="en")


@router.post("", response_model=APIResponse[AskResponsePayload])
async def ask_villagenova(
    payload: AskRequestPayload,
    current_user: AuthenticatedResident = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Main conversational AI endpoint:
    1. Loads full resident context (crops, soil, stage, weather)
    2. Runs AI Orchestrator with contextual tool capabilities
    3. Produces structured action card payload for Flutter UI
    """
    context = await build_resident_context(current_user.user_id, db)
    if payload.language:
        context["language"] = payload.language

    ai_response = await orchestrator.process_query(
        resident_context=context,
        user_message=payload.message
    )

    return APIResponse(data=ai_response)
