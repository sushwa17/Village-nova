from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload
from typing import List
import uuid

from app.core.database import get_db
from app.core.security import get_current_user, AuthenticatedResident
from app.models.resident import ResidentProfile, ResidentRole, Village
from app.models.farm import Farm, Crop
from app.schemas.resident import ResidentProfileOut, OnboardingRequest
from app.schemas.common import APIResponse

router = APIRouter(prefix="/resident", tags=["Resident Profile"])


@router.get("/me", response_model=APIResponse[ResidentProfileOut])
async def get_my_profile(
    current_user: AuthenticatedResident = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Fetch current authenticated resident's profile and assigned roles.
    """
    stmt = (
        select(ResidentProfile)
        .options(selectinload(ResidentProfile.roles), selectinload(ResidentProfile.village))
        .where(ResidentProfile.id == uuid.UUID(current_user.user_id))
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
    1. Create/Update ResidentProfile
    2. Assign selected multi-roles
    3. Setup Farm & main Crop if Farmer role selected
    """
    user_uuid = uuid.UUID(current_user.user_id)

    # Check for existing profile
    stmt = select(ResidentProfile).where(ResidentProfile.id == user_uuid)
    result = await db.execute(stmt)
    profile = result.scalars().first()

    if not profile:
        profile = ResidentProfile(
            id=user_uuid,
            full_name=payload.full_name,
            phone_number=current_user.phone,
            village_id=payload.village_id,
            preferred_language=payload.preferred_language
        )
        db.add(profile)
    else:
        profile.full_name = payload.full_name
        profile.village_id = payload.village_id
        profile.preferred_language = payload.preferred_language

    await db.flush()

    # Assign Roles
    for role_name in payload.roles:
        role_entry = ResidentRole(
            resident_id=profile.id,
            role=role_name,
            is_primary=(role_name == payload.roles[0])
        )
        db.add(role_entry)

    # If farmer role & farm details provided, create farm and crop
    if "farmer" in payload.roles and payload.farm:
        farm = Farm(
            resident_id=profile.id,
            farm_name=payload.farm.farm_name,
            land_acres=payload.farm.land_acres,
            soil_type=payload.farm.soil_type,
            water_source=payload.farm.water_source
        )
        db.add(farm)
        await db.flush()

        crop = Crop(
            farm_id=farm.id,
            crop_name=payload.farm.main_crop,
            current_stage="vegetative",
            farming_goal="Improve crop yield and quality"
        )
        db.add(crop)

    await db.commit()

    return APIResponse(
        message="Onboarding completed successfully",
        data=ResidentProfileOut(
            id=profile.id,
            full_name=profile.full_name,
            phone_number=profile.phone_number,
            village_id=profile.village_id,
            preferred_language=profile.preferred_language,
            verified_badge=profile.verified_badge,
            roles=payload.roles,
            created_at=profile.created_at
        )
    )
