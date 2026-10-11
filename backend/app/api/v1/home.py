from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload
import uuid

from app.core.database import get_db
from app.core.security import get_current_user, AuthenticatedResident
from app.models.resident import ResidentProfile
from app.models.farm import Farm, Crop
from app.models.task import Task
from app.schemas.home import HomeDashboardPayload, WeatherSummary, TodayActionItem, ProgressSummary
from app.schemas.common import APIResponse

router = APIRouter(prefix="/home", tags=["Home Dashboard"])


@router.get("", response_model=APIResponse[HomeDashboardPayload])
async def get_home_dashboard(
    current_user: AuthenticatedResident = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Returns aggregated ready-to-render payload for the Flutter Home Screen:
    Greeting, location, weather advisory, today's actions, and progress stats.
    """
    profile = None
    if db:
        try:
            user_uuid = uuid.UUID(current_user.user_id)
            stmt = (
                select(ResidentProfile)
                .options(
                    selectinload(ResidentProfile.village),
                    selectinload(ResidentProfile.farms).selectinload(Farm.crops),
                    selectinload(ResidentProfile.tasks),
                )
                .where(ResidentProfile.id == user_uuid)
            )
            result = await db.execute(stmt)
            profile = result.scalars().first()
        except Exception:
            profile = None

    name = profile.full_name if profile else "Ravi"
    village_name = profile.village.name if profile and profile.village else "Ananthagiri"
    crop_name = (
        profile.farms[0].crops[0].crop_name
        if profile and profile.farms and profile.farms[0].crops
        else "Soybean"
    )

    # Dynamic actions from resident tasks in DB
    if profile and profile.tasks:
        actions = []
        for t in profile.tasks:
            tag = "💧 Irrigation"
            if "Inspect" in t.title or "leaves" in t.title:
                tag = f"🌱 {crop_name}"
            elif "observation" in t.title or "photo" in t.title:
                tag = "📷 Observation"
            elif t.domain == "education":
                tag = "🎓 Education"
            elif t.domain == "scheme":
                tag = "🏛️ Scheme"

            actions.append(
                TodayActionItem(
                    id=str(t.id),
                    title=t.title,
                    tag=tag,
                    action_type="farm_task",
                    completed=t.is_completed,
                )
            )
        completed_cnt = sum(1 for t in profile.tasks if t.is_completed)
        total_cnt = len(profile.tasks)
        pct = int((completed_cnt / total_cnt) * 100) if total_cnt > 0 else 0
        progress = ProgressSummary(
            completed=completed_cnt,
            total=total_cnt,
            percentage=pct,
        )
    else:
        # Contextual default actions
        actions = [
            TodayActionItem(
                id="act_1",
                title=f"Check soil moisture before evening rain ({crop_name})",
                tag="💧 Irrigation",
                action_type="check_soil",
                completed=True,
            ),
            TodayActionItem(
                id="act_2",
                title=f"Inspect {crop_name} leaves for yellow mosaic spots",
                tag="🌱 Crop Health",
                action_type="inspect_leaves",
                completed=False,
            ),
            TodayActionItem(
                id="act_3",
                title=f"Upload weekly {crop_name} observation photo",
                tag="📷 Observation",
                action_type="photo_observation",
                completed=False,
            ),
        ]
        progress = ProgressSummary(
            completed=1,
            total=3,
            percentage=33,
        )

    weather = WeatherSummary(
        headline="Rain Expected Today (6:00 PM)",
        temperature_c=29.0,
        rainfall_mm=14.0,
        advisory=f"14mm forecast in {village_name} mandal. Avoid evening irrigation and spraying operations."
    )

    payload = HomeDashboardPayload(
        greeting=f"Good morning, {name} 👋",
        resident_name=name,
        location_label=f"{village_name} • {crop_name} Season",
        weather=weather,
        today_actions=actions,
        progress=progress,
        village_updates_count=3,
        scheme_matches_count=2,
    )

    return APIResponse(data=payload)
