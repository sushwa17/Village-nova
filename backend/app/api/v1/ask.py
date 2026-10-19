from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field
from typing import Optional, Dict, Any, List
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import get_current_user, AuthenticatedResident
from app.agents.context_builder import build_resident_context
from app.agents.orchestrator import orchestrator, AskResponsePayload
from app.agents.dispatcher import dispatcher
from app.schemas.common import APIResponse

router = APIRouter(prefix="/ask", tags=["Ask VillageNova AI"])


class AskRequestPayload(BaseModel):
    message: str = Field(min_length=1, example="What should I do on my farm today?")
    conversation_id: Optional[str] = None
    language: Optional[str] = Field(default="en", example="en")


class ActionExecutionRequest(BaseModel):
    action_id: str = Field(..., example="act_1")
    action_type: str = Field(..., example="check_soil")
    payload: Dict[str, Any] = Field(default_factory=dict)
    notes: Optional[str] = Field(default=None, example="Soil moisture checked, good for rain")


class ActionExecutionResponse(BaseModel):
    success: bool = True
    action_id: str
    action_type: str
    feedback_message: str
    action_status: str = "completed"
    result_data: Dict[str, Any] = Field(default_factory=dict)


class ToolListResponse(BaseModel):
    total_tools: int
    tools: List[Dict[str, Any]]


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


@router.get("/tools", response_model=APIResponse[ToolListResponse])
async def list_ai_tools(
    current_user: AuthenticatedResident = Depends(get_current_user)
):
    """
    Introspection endpoint returning all registered specialist AI tools,
    parameter schemas, and capabilities for the agent dispatcher.
    """
    tools = dispatcher.list_tools()
    tools_data = [t.model_dump() for t in tools]
    return APIResponse(
        data=ToolListResponse(
            total_tools=len(tools_data),
            tools=tools_data
        )
    )


@router.post("/action", response_model=APIResponse[ActionExecutionResponse])
async def execute_action_card(
    action_req: ActionExecutionRequest,
    current_user: AuthenticatedResident = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Interactive Action Card Dispatcher (Week 8):
    Executes or logs the action selected by the resident in the chat UI.
    """
    action_type = action_req.action_type
    payload = action_req.payload

    if action_type in ("check_soil", "inspect_leaves", "irrigation", "task", "farm_activity"):
        res = await dispatcher.execute_tool(
            "execute_quick_farm_action",
            {
                "user_id": current_user.user_id,
                "action_type": action_type,
                "notes": action_req.notes or f"Completed '{action_type}' from VillageNova AI recommendation."
            }
        )
        return APIResponse(
            data=ActionExecutionResponse(
                action_id=action_req.action_id,
                action_type=action_type,
                feedback_message=f"✓ Recorded '{action_type}' in your My Farm activity timeline.",
                action_status="completed",
                result_data=res.data or {}
            )
        )

    elif action_type == "view_mandi":
        commodity = payload.get("commodity", "Soybean")
        market = payload.get("market", "Vikarabad")
        res = await dispatcher.execute_tool(
            "get_mandi_prices",
            {"commodity": commodity, "market": market}
        )
        return APIResponse(
            data=ActionExecutionResponse(
                action_id=action_req.action_id,
                action_type=action_type,
                feedback_message=f"Fetched live {commodity} rates for {market} APMC.",
                action_status="retrieved",
                result_data=res.data or {}
            )
        )

    elif action_type == "check_scheme":
        res = await dispatcher.execute_tool(
            "check_scheme_eligibility",
            {"land_acres": 2.5, "crop_name": "Soybean", "village": "Ananthagiri"}
        )
        return APIResponse(
            data=ActionExecutionResponse(
                action_id=action_req.action_id,
                action_type=action_type,
                feedback_message="Verified eligibility and compiled document requirements for Gram Panchayat.",
                action_status="verified",
                result_data=res.data or {}
            )
        )

    elif action_type == "photo_observation":
        return APIResponse(
            data=ActionExecutionResponse(
                action_id=action_req.action_id,
                action_type=action_type,
                feedback_message="Camera diagnostic session initialized. Ready for leaf snapshot.",
                action_status="ready_for_capture",
                result_data={
                    "session_id": f"obs_sess_{action_req.action_id}",
                    "diagnostic_target": "Soybean Leaf Canopy (Yellow Mosaic / Whitefly)",
                    "guide": "Align leaf squarely in frame with good natural daylight."
                }
            )
        )

    else:
        # Generic action fallback
        return APIResponse(
            data=ActionExecutionResponse(
                action_id=action_req.action_id,
                action_type=action_type,
                feedback_message=f"Acknowledged action '{action_type}'.",
                action_status="acknowledged",
                result_data=payload
            )
        )
