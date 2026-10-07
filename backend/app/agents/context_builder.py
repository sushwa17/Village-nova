from typing import Dict, Any, Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload
import uuid
import logging

from app.models.resident import ResidentProfile
from app.models.farm import Farm, Crop

logger = logging.getLogger(__name__)


async def build_resident_context(resident_id: str, db: Optional[AsyncSession] = None) -> Dict[str, Any]:
    """
    Assembles real-time contextual snapshot for the AI Orchestrator:
    Resident Name, Location, Roles, Primary Farm, Active Crop, Sowing Date, Stage.
    Gracefully falls back to baseline defaults if DB is offline or mock.
    """
    default_context = {
        "resident_name": "Ravi",
        "village": "Ananthagiri",
        "district": "Vikarabad",
        "language": "te",
        "roles": ["farmer"],
        "farm": {"land_acres": 2.5, "soil_type": "black", "water_source": "borewell"},
        "crop": {"crop_name": "Soybean", "current_stage": "vegetative", "sowing_date": "2024-06-15"},
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
                crop_info = {
                    "crop_name": active_crop.crop_name,
                    "current_stage": active_crop.current_stage,
                    "sowing_date": str(active_crop.sowing_date)
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
