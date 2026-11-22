from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field
from typing import Optional, Dict, Any, List
from sqlalchemy.ext.asyncio import AsyncSession

from app.core.database import get_db
from app.core.security import get_current_user, AuthenticatedResident
from app.agents.context_builder import build_resident_context
from app.agents.orchestrator import orchestrator, AskResponsePayload
from app.agents.dispatcher import dispatcher
from app.schemas.common import APIResponse
from app.services.cache import semantic_cache, check_ask_rate_limit
from app.services.conversation import conversation_manager, MAX_MESSAGE_CHARACTERS

router = APIRouter(prefix="/ask", tags=["Ask VillageNova AI"])


class AskRequestPayload(BaseModel):
    message: str = Field(min_length=1, max_length=MAX_MESSAGE_CHARACTERS, example="What should I do on my farm today?")
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


class ConversationHistoryResponse(BaseModel):
    conversation_id: str
    total_messages: int
    messages: List[Dict[str, Any]]


class AskStatsResponse(BaseModel):
    cache_stats: Dict[str, Any]
    active_sessions: int
    rate_limiting_enabled: bool = True


@router.post("", response_model=APIResponse[AskResponsePayload], dependencies=[Depends(check_ask_rate_limit)])
async def ask_villagenova(
    payload: AskRequestPayload,
    current_user: AuthenticatedResident = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Main conversational AI endpoint (Week 10 Hardened):
    1. Enforces character bounds (max 1000 chars) and sliding-window rate limits (429 Too Many Requests).
    2. Retrieves or provisions conversational session tracking.
    3. Checks sub-50ms semantic query cache.
    4. Runs grounded Gemini 3.8 Flash / agronomic rule engine with verified citations.
    5. Appends turn to conversation history and enforces sliding-window truncation.
    """
    # 1. Message Validation
    conversation_manager.validate_message(payload.message)

    # 2. Context Building & Session Provisions
    context = await build_resident_context(current_user.user_id, db)
    if payload.language:
        context["language"] = payload.language

    session = conversation_manager.get_or_create_session(
        conversation_id=payload.conversation_id,
        user_id=current_user.user_id
    )

    # 3. Query Processing with Latency & Cache Tracking
    ai_response = await orchestrator.process_query(
        resident_context=context,
        user_message=payload.message,
        conversation_id=session.session_id
    )

    # 4. Record Conversation Turn
    conversation_manager.add_turn(
        conversation_id=session.session_id,
        user_id=current_user.user_id,
        user_message=payload.message,
        model_response=ai_response.message,
        actions=[a.model_dump() for a in ai_response.actions],
        sources=[s.model_dump() for s in ai_response.sources],
        why_advisory=ai_response.why_advisory
    )

    return APIResponse(data=ai_response)


@router.get("/conversations/{conversation_id}", response_model=APIResponse[ConversationHistoryResponse])
async def get_conversation_history(
    conversation_id: str,
    current_user: AuthenticatedResident = Depends(get_current_user)
):
    """
    Fetches full message history for a resident conversation session.
    """
    messages = conversation_manager.get_session_history(
        conversation_id=conversation_id,
        user_id=current_user.user_id
    )
    return APIResponse(
        data=ConversationHistoryResponse(
            conversation_id=conversation_id,
            total_messages=len(messages),
            messages=messages
        )
    )


@router.delete("/conversations/{conversation_id}", response_model=APIResponse[Dict[str, Any]])
async def clear_conversation(
    conversation_id: str,
    current_user: AuthenticatedResident = Depends(get_current_user)
):
    """
    Clears message history for a conversation session ("Clear Chat").
    """
    cleared = conversation_manager.clear_session(
        conversation_id=conversation_id,
        user_id=current_user.user_id
    )
    if not cleared:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Conversation session not found or unauthorized."
        )
    return APIResponse(
        data={
            "conversation_id": conversation_id,
            "status": "cleared",
            "message": "Conversation history cleared successfully."
        }
    )


@router.get("/stats", response_model=APIResponse[AskStatsResponse])
async def get_orchestrator_stats(
    current_user: AuthenticatedResident = Depends(get_current_user)
):
    """
    Telemetry introspection returning semantic cache hit ratio and session counts.
    """
    stats = semantic_cache.get_stats()
    session_count = conversation_manager.get_all_sessions_count()
    return APIResponse(
        data=AskStatsResponse(
            cache_stats=stats,
            active_sessions=session_count,
            rate_limiting_enabled=True
        )
    )


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
