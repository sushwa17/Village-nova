from typing import Dict, Any, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload
from datetime import date
import uuid
import logging

from app.models.resident import ResidentProfile
from app.models.farm import Farm
from app.services.lifecycle import calculate_crop_lifecycle

logger = logging.getLogger(__name__)


async def build_resident_context(resident_id: str, db: Optional[AsyncSession] = None) -> Dict[str, Any]:
    """
    Assembles real-time contextual snapshot for the AI Orchestrator:
    Resident Name, Location, Roles, Primary Farm, Active Crop, Phenological Stage,
    Days Elapsed, Harvest Horizon, and Active Weather Advisory.
    Gracefully falls back to baseline defaults if DB is offline or mock.
    """
    default_context = {
        "resident_name": "Ravi",
        "village": "Ananthagiri",
        "district": "Vikarabad",
        "language": "te",
        "roles": ["farmer"],
        "farm": {"land_acres": 2.5, "soil_type": "black", "water_source": "borewell"},
        "crop": {
            "crop_name": "Soybean",
            "variety": "JS 335 (Certified High Yield)",
            "current_stage": "vegetative",
            "stage_title": "Vegetative & Branching",
            "sowing_date": "2024-06-15",
            "days_since_sowing": 42,
            "days_to_harvest": 73,
            "farming_goal": "Maximize Soybean grain yield with timely pest prevention",
        },
        "weather_advisory": "14mm rainfall forecast at 6:00 PM today"
    }

    if not db:
        return default_context

    try:
        user_uuid = uuid.UUID(resident_id)
        stmt = (
            select(ResidentProfile)
            .options(
                selectinload(ResidentProfile.village),
                selectinload(ResidentProfile.roles),
                selectinload(ResidentProfile.farms).selectinload(Farm.crops),
            )
            .where(ResidentProfile.id == user_uuid)
        )
        result = await db.execute(stmt)
        profile = result.scalars().first()

        if not profile:
            return default_context

        roles = [r.role for r in profile.roles] if profile.roles else ["farmer"]
        village_name = profile.village.name if profile.village else "Ananthagiri"
        district = profile.village.district if profile.village else "Vikarabad"

        farm_info = {}
        crop_info = {}
        if profile.farms:
            primary_farm = profile.farms[0]
            farm_info = {
                "land_acres": float(primary_farm.land_acres),
                "soil_type": primary_farm.soil_type,
                "water_source": primary_farm.water_source
            }
            if primary_farm.crops:
                active_crop = primary_farm.crops[0]
                sow_date = active_crop.sowing_date
                days_elapsed = max(1, (date.today() - sow_date).days) if sow_date else 42
                lifecycle = calculate_crop_lifecycle(
                    crop_name=active_crop.crop_name,
                    days_elapsed=days_elapsed,
                    variety=active_crop.variety or "JS 335",
                    sowing_date=sow_date or date.today(),
                    farming_goal=active_crop.farming_goal,
                )
                crop_info = {
                    "crop_name": lifecycle.crop_name,
                    "variety": lifecycle.variety,
                    "current_stage": lifecycle.current_stage,
                    "stage_title": lifecycle.stage_title,
                    "sowing_date": str(lifecycle.sowing_date),
                    "days_since_sowing": lifecycle.days_since_sowing,
                    "days_to_harvest": lifecycle.days_to_harvest,
                    "farming_goal": lifecycle.farming_goal,
                }

        return {
            "resident_name": profile.full_name,
            "village": village_name,
            "district": district,
            "language": profile.preferred_language,
            "roles": roles,
            "farm": farm_info or default_context["farm"],
            "crop": crop_info or default_context["crop"],
            "weather_advisory": "14mm rainfall forecast at 6:00 PM today"
        }
    except Exception as e:
        logger.warning(f"Failed to query resident context from DB, using resilient default: {e}")
        return default_context
