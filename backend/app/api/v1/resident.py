from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import delete
from sqlalchemy.orm import selectinload
from typing import List, Optional
from datetime import datetime, date, timedelta
import uuid
import logging

from app.core.database import get_db
from app.core.security import get_current_user, AuthenticatedResident
from app.models.resident import ResidentProfile, ResidentRole, Village
from app.models.farm import Farm, Crop
from app.models.task import Task
from app.schemas.resident import ResidentProfileOut, OnboardingRequest
from app.schemas.common import APIResponse

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/resident", tags=["Resident Profile"])


@router.get("/me", response_model=APIResponse[ResidentProfileOut])
async def get_my_profile(
    current_user: AuthenticatedResident = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Fetch current authenticated resident's profile and assigned roles.
    """
    user_uuid = uuid.UUID(current_user.user_id) if isinstance(current_user.user_id, str) and len(current_user.user_id) == 36 else uuid.uuid4()

    if not db:
        # Resilient offline/mock profile
        return APIResponse(
            data=ResidentProfileOut(
                id=user_uuid,
                full_name="Ravi Kumar",
                phone_number=current_user.phone or "+919876543210",
                village_id=uuid.UUID("3fa85f64-5717-4562-b3fc-2c963f66afa6"),
                village_name="Ananthagiri",
                preferred_language="te",
                verified_badge=True,
                roles=["farmer"],
                created_at=datetime.utcnow()
            )
        )

    stmt = (
        select(ResidentProfile)
        .options(selectinload(ResidentProfile.roles), selectinload(ResidentProfile.village))
        .where(ResidentProfile.id == user_uuid)
    )
    result = await db.execute(stmt)
    profile = result.scalars().first()

    if not profile:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Resident profile not found. Please complete onboarding."
        )

    roles_list = [r.role for r in profile.roles]
    village_name = profile.village.name if profile.village else None

    profile_out = ResidentProfileOut(
        id=profile.id,
        full_name=profile.full_name,
        phone_number=profile.phone_number,
        village_id=profile.village_id,
        village_name=village_name,
        preferred_language=profile.preferred_language,
        verified_badge=profile.verified_badge,
        roles=roles_list,
        created_at=profile.created_at
    )

    return APIResponse(data=profile_out)


@router.post("/onboarding", response_model=APIResponse[ResidentProfileOut], status_code=status.HTTP_201_CREATED)
async def complete_onboarding(
    payload: OnboardingRequest,
    current_user: AuthenticatedResident = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Process progressive resident onboarding:
    1. Resolve or create Village
    2. Create/Update ResidentProfile
    3. Assign selected multi-roles
    4. Setup Farm, main Crop, calculate crop stage, and seed initial Today's Actions
    """
    try:
        user_uuid = uuid.UUID(current_user.user_id)
    except (ValueError, TypeError):
        user_uuid = uuid.uuid4()

    if not db:
        # Resilient offline/mock response
        return APIResponse(
            message="Onboarding completed successfully",
            data=ResidentProfileOut(
                id=user_uuid,
                full_name=payload.full_name,
                phone_number=current_user.phone or "+919876543210",
                village_id=payload.village_id,
                village_name=payload.village_name or "Ananthagiri",
                preferred_language=payload.preferred_language,
                verified_badge=False,
                roles=payload.roles,
                created_at=datetime.utcnow()
            )
        )

    # 1. Resolve Village
    resolved_village_id = payload.village_id
    resolved_village_name = payload.village_name

    if not resolved_village_id and payload.village_name:
        clean_name = payload.village_name.split("(")[0].strip()
        v_stmt = select(Village).where(Village.name.ilike(f"%{clean_name}%"))
        v_res = await db.execute(v_stmt)
        matched_village = v_res.scalars().first()
        if matched_village:
            resolved_village_id = matched_village.id
            resolved_village_name = matched_village.name
        else:
            new_village = Village(
                name=clean_name,
                mandal="Vikarabad",
                district="Vikarabad",
                state="Telangana",
                pincode="501101"
            )
            db.add(new_village)
            await db.flush()
            resolved_village_id = new_village.id
            resolved_village_name = new_village.name

    # 2. Check for existing profile
    stmt = select(ResidentProfile).where(ResidentProfile.id == user_uuid)
    result = await db.execute(stmt)
    profile = result.scalars().first()

    if not profile:
        profile = ResidentProfile(
            id=user_uuid,
            full_name=payload.full_name,
            phone_number=current_user.phone,
            village_id=resolved_village_id,
            preferred_language=payload.preferred_language
        )
        db.add(profile)
    else:
        profile.full_name = payload.full_name
        profile.village_id = resolved_village_id
        profile.preferred_language = payload.preferred_language

    await db.flush()

    # 3. Assign Roles (replace existing)
    await db.execute(delete(ResidentRole).where(ResidentRole.resident_id == profile.id))
    for role_name in payload.roles:
        role_entry = ResidentRole(
            resident_id=profile.id,
            role=role_name,
            is_primary=(role_name == payload.roles[0])
        )
        db.add(role_entry)

    # 4. If farmer role & farm details provided, create/update farm and crop
    if "farmer" in payload.roles and payload.farm:
        farm_stmt = select(Farm).where(Farm.resident_id == profile.id)
        f_res = await db.execute(farm_stmt)
        farm = f_res.scalars().first()

        if not farm:
            farm = Farm(
                resident_id=profile.id,
                farm_name=payload.farm.farm_name,
                land_acres=payload.farm.land_acres,
                soil_type=payload.farm.soil_type,
                water_source=payload.farm.water_source
            )
            db.add(farm)
            await db.flush()
        else:
            farm.land_acres = payload.farm.land_acres
            farm.soil_type = payload.farm.soil_type
            farm.water_source = payload.farm.water_source
            await db.flush()

        # Parse Sowing Date and Calculate Crop Stage
        sow_date = date.today() - timedelta(days=42)  # Default: Day 42 Vegetative
        if payload.farm.sowing_date:
            try:
                sow_date = datetime.strptime(payload.farm.sowing_date, "%Y-%m-%d").date()
            except Exception:
                sow_date = date.today() - timedelta(days=42)

        days_elapsed = max(0, (date.today() - sow_date).days)
        if days_elapsed < 10:
            stage = "germination"
        elif days_elapsed < 35:
            stage = "early vegetative"
        elif days_elapsed < 65:
            stage = "vegetative"
        elif days_elapsed < 95:
            stage = "flowering"
        else:
            stage = "maturity"

        crop_stmt = select(Crop).where(Crop.farm_id == farm.id)
        c_res = await db.execute(crop_stmt)
        crop = c_res.scalars().first()

        if not crop:
            crop = Crop(
                farm_id=farm.id,
                crop_name=payload.farm.main_crop,
                sowing_date=sow_date,
                current_stage=stage,
                farming_goal=f"Maximize {payload.farm.main_crop} yield and grain quality"
            )
            db.add(crop)
        else:
            crop.crop_name = payload.farm.main_crop
            crop.sowing_date = sow_date
            crop.current_stage = stage

        # Seed initial farmer tasks
        await db.execute(delete(Task).where(Task.resident_id == profile.id))
        seed_tasks = [
            Task(
                resident_id=profile.id,
                title=f"Check soil moisture before evening rain ({payload.farm.main_crop})",
                domain="farm",
                due_date=date.today(),
                is_completed=True
            ),
            Task(
                resident_id=profile.id,
                title=f"Inspect {payload.farm.main_crop} leaves for yellow spots & pest activity",
                domain="farm",
                due_date=date.today(),
                is_completed=False
            ),
            Task(
                resident_id=profile.id,
                title=f"Upload weekly {payload.farm.main_crop} observation photo",
                domain="farm",
                due_date=date.today(),
                is_completed=False
            ),
        ]
        for t in seed_tasks:
            db.add(t)

    # 5. Non-farmer role specific tasks
    if "student" in payload.roles and "farmer" not in payload.roles:
        db.add(Task(
            resident_id=profile.id,
            title="Check NSP Pre-Matric & Post-Matric Scholarship deadlines",
            domain="education",
            due_date=date.today(),
            is_completed=False
        ))
    if "shg_livelihood" in payload.roles and "farmer" not in payload.roles:
        db.add(Task(
            resident_id=profile.id,
            title="Review SHG Stree Nidhi low-interest credit eligibility",
            domain="scheme",
            due_date=date.today(),
            is_completed=False
        ))

    await db.commit()

    return APIResponse(
        message="Onboarding completed successfully",
        data=ResidentProfileOut(
            id=profile.id,
            full_name=profile.full_name,
            phone_number=profile.phone_number,
            village_id=profile.village_id,
            village_name=resolved_village_name or "Ananthagiri",
            preferred_language=profile.preferred_language,
            verified_badge=profile.verified_badge,
            roles=payload.roles,
            created_at=profile.created_at
        )
    )
