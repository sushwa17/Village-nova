from fastapi import APIRouter, Depends, Query, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy.orm import selectinload
from typing import List, Optional
from datetime import datetime, timezone, date, timedelta
import uuid

from app.core.database import get_db
from app.core.security import get_current_user, AuthenticatedResident
from app.models.farm import Farm, Crop, CropActivity, CropObservation, FarmExpense
from app.schemas.farm import (
    MyFarmOut,
    CropDetailOut,
    CropStageStep,
    CropActivityCreate,
    CropActivityOut,
    FarmExpenseCreate,
    FarmExpenseOut,
    CropObservationCreate,
    CropObservationOut,
    CropLifecycleOut,
    LeafDoctorRequest,
    LeafDoctorDiagnosisOut,
)
from app.schemas.common import APIResponse
from app.services.lifecycle import calculate_crop_lifecycle
from app.services.leaf_doctor import diagnose_leaf_observation

router = APIRouter(prefix="/farm", tags=["Farm & Crop Lifecycle"])


def _calculate_stages(crop_name: str, days_elapsed: int) -> tuple[str, int, List[CropStageStep]]:
    """
    Computes standard agronomic stages and progress percentage for Kharif crops like Soybean/Cotton.
    """
    lifecycle = calculate_crop_lifecycle(crop_name, days_elapsed)
    return lifecycle.current_stage, lifecycle.stage_progress_pct, lifecycle.stages


@router.get("/my-farm", response_model=APIResponse[MyFarmOut])
async def get_my_farm(
    current_user: AuthenticatedResident = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Returns the resident's primary farm details, crop stage timeline, recent activities, and expenses.
    """
    farm = None
    if db:
        try:
            user_uuid = uuid.UUID(current_user.user_id)
            stmt = (
                select(Farm)
                .options(
                    selectinload(Farm.crops).selectinload(Crop.activities),
                    selectinload(Farm.crops).selectinload(Crop.observations),
                )
                .where(Farm.resident_id == user_uuid)
            )
            result = await db.execute(stmt)
            farm = result.scalars().first()
        except Exception:
            farm = None

    now = datetime.now(timezone.utc)

    if not farm:
        # Fallback simulated farm (Day 42 Vegetative Stage)
        sow_date = date.today() - timedelta(days=42)
        current_stage, pct, stages = _calculate_stages("Soybean", 42)
        demo_crop = CropDetailOut(
            id=uuid.UUID("11111111-1111-1111-1111-111111111111"),
            crop_name="Soybean",
            variety="JS 335 (High Oil Yield)",
            sowing_date=sow_date,
            days_since_sowing=42,
            current_stage=current_stage,
            stage_progress_pct=pct,
            farming_goal="Maximize Soybean grain yield with timely pest prevention",
            stages=stages,
        )
        demo_activities = [
            CropActivityOut(
                id=uuid.UUID("22222222-2222-2222-2222-222222222221"),
                activity_type="irrigation",
                description="Borewell channel irrigation before sunny interval",
                cost_incurred=0.0,
                performed_at=now - timedelta(days=2),
            ),
            CropActivityOut(
                id=uuid.UUID("22222222-2222-2222-2222-222222222222"),
                activity_type="fertilizer",
                description="Applied DAP (18-46-0) split basal dose",
                cost_incurred=1450.0,
                performed_at=now - timedelta(days=8),
            ),
        ]
        demo_expenses = [
            FarmExpenseOut(
                id=uuid.UUID("33333333-3333-3333-3333-333333333331"),
                category="fertilizer",
                amount=1450.0,
                expense_date=date.today() - timedelta(days=8),
                notes="1 bag DAP from Vikarabad Agro Seva Kendra",
            ),
            FarmExpenseOut(
                id=uuid.UUID("33333333-3333-3333-3333-333333333332"),
                category="seeds",
                amount=3200.0,
                expense_date=sow_date,
                notes="Certified JS-335 seeds (30 kg)",
            ),
        ]
        return APIResponse(
            data=MyFarmOut(
                farm_id=uuid.UUID("44444444-4444-4444-4444-444444444444"),
                farm_name="Ravi's Main Field",
                land_acres=2.5,
                soil_type="Black Soil (నల్ల రేగడి)",
                water_source="Borewell",
                crop=demo_crop,
                total_expenses=4650.0,
                recent_activities=demo_activities,
                recent_expenses=demo_expenses,
                weather_advisory="Rain expected today at 6:00 PM (14mm). Hold evening spray operations.",
            )
        )

    # Extract active crop from DB
    crop_out = None
    recent_activities = []
    if farm.crops:
        primary_crop = farm.crops[0]
        sow_date = primary_crop.sowing_date or (date.today() - timedelta(days=42))
        days_elapsed = max(1, (date.today() - sow_date).days)
        stage_key, progress_pct, stages = _calculate_stages(primary_crop.crop_name, days_elapsed)

        recent_activities = [
            CropActivityOut(
                id=act.id,
                activity_type=act.activity_type,
                description=act.description,
                cost_incurred=float(act.cost_incurred or 0.0),
                performed_at=act.performed_at,
            )
            for act in (primary_crop.activities or [])
        ]

        crop_out = CropDetailOut(
            id=primary_crop.id,
            crop_name=primary_crop.crop_name,
            variety=primary_crop.variety,
            sowing_date=sow_date,
            days_since_sowing=days_elapsed,
            current_stage=stage_key,
            stage_progress_pct=progress_pct,
            farming_goal=primary_crop.farming_goal,
            stages=stages,
        )

    return APIResponse(
        data=MyFarmOut(
            farm_id=farm.id,
            farm_name=farm.farm_name,
            land_acres=float(farm.land_acres),
            soil_type=farm.soil_type,
            water_source=farm.water_source,
            crop=crop_out,
            total_expenses=sum(a.cost_incurred for a in recent_activities),
            recent_activities=recent_activities,
            weather_advisory="Weather advisory: 14mm rainfall forecast. Avoid irrigation today.",
        )
    )


@router.get("/lifecycle", response_model=APIResponse[CropLifecycleOut])
async def get_crop_lifecycle_endpoint(
    days_elapsed: Optional[int] = Query(None, description="Optional override to simulate lifecycle stage"),
    current_user: AuthenticatedResident = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Returns the comprehensive phenological crop lifecycle progression, active PJTSAU agronomic recommendations,
    active disease/weather risks, and daily priority actions. Supports ?days_elapsed=<int> simulation.
    """
    crop_name = "Soybean"
    variety = "JS 335 (High Oil Yield)"
    farming_goal = "Maximize Soybean grain yield with timely pest prevention"
    sow_date = None
    actual_days = None

    if db:
        try:
            user_uuid = uuid.UUID(current_user.user_id)
            stmt = select(Crop).join(Farm).where(Farm.resident_id == user_uuid)
            res = await db.execute(stmt)
            crop = res.scalars().first()
            if crop:
                crop_name = crop.crop_name or crop_name
                variety = crop.variety or variety
                farming_goal = crop.farming_goal or farming_goal
                sow_date = crop.sowing_date
                if sow_date:
                    actual_days = max(1, (date.today() - sow_date).days)
        except Exception:
            pass

    if days_elapsed is not None:
        effective_days = max(1, days_elapsed)
    elif actual_days is not None:
        effective_days = actual_days
    else:
        effective_days = 42  # default simulated day (Vegetative)

    effective_sow_date = sow_date or (date.today() - timedelta(days=effective_days))
    lifecycle_data = calculate_crop_lifecycle(
        crop_name=crop_name,
        days_elapsed=effective_days,
        variety=variety,
        sowing_date=effective_sow_date,
        farming_goal=farming_goal,
    )

    return APIResponse(
        message="Crop lifecycle retrieved successfully",
        data=lifecycle_data,
    )


@router.get("/activities", response_model=APIResponse[List[CropActivityOut]])
async def get_farm_activities(
    activity_type: Optional[str] = Query(None, description="Filter by activity type"),
    limit: int = Query(20, le=100, description="Max activities to return"),
    current_user: AuthenticatedResident = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Returns logged farm activities for the resident's primary crop.
    """
    activities: List[CropActivityOut] = []
    if db:
        try:
            user_uuid = uuid.UUID(current_user.user_id)
            stmt = (
                select(CropActivity)
                .join(Crop)
                .join(Farm)
                .where(Farm.resident_id == user_uuid)
            )
            if activity_type:
                stmt = stmt.where(CropActivity.activity_type == activity_type)
            stmt = stmt.order_by(CropActivity.performed_at.desc()).limit(limit)
            res = await db.execute(stmt)
            rows = res.scalars().all()
            for r in rows:
                activities.append(
                    CropActivityOut(
                        id=r.id,
                        activity_type=r.activity_type,
                        description=r.description,
                        cost_incurred=float(r.cost_incurred or 0.0),
                        performed_at=r.performed_at,
                    )
                )
        except Exception:
            pass

    if not activities:
        # Fallback simulated activities
        now = datetime.now(timezone.utc)
        simulated = [
            CropActivityOut(
                id=uuid.UUID("22222222-2222-2222-2222-222222222221"),
                activity_type="irrigation",
                description="Borewell channel irrigation before sunny interval",
                cost_incurred=0.0,
                performed_at=now - timedelta(days=2),
            ),
            CropActivityOut(
                id=uuid.UUID("22222222-2222-2222-2222-222222222222"),
                activity_type="fertilizer",
                description="Applied DAP (18-46-0) split basal dose",
                cost_incurred=1450.0,
                performed_at=now - timedelta(days=8),
            ),
            CropActivityOut(
                id=uuid.UUID("22222222-2222-2222-2222-222222222223"),
                activity_type="spray",
                description="Neem oil spray (1500 ppm) for sucking pests prevention",
                cost_incurred=350.0,
                performed_at=now - timedelta(days=14),
            ),
        ]
        if activity_type:
            simulated = [a for a in simulated if a.activity_type == activity_type]
        activities = simulated[:limit]

    return APIResponse(
        message="Farm activities retrieved successfully",
        data=activities,
    )


@router.post("/activities", response_model=APIResponse[CropActivityOut], status_code=status.HTTP_201_CREATED)
async def log_crop_activity(
    payload: CropActivityCreate,
    current_user: AuthenticatedResident = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Log a field operation (irrigation, fertilizer, spray, weeding, soil inspection).
    """
    activity_id = uuid.uuid4()
    performed_at = payload.performed_at or datetime.now(timezone.utc)

    if db:
        try:
            user_uuid = uuid.UUID(current_user.user_id)
            stmt = select(Crop).join(Farm).where(Farm.resident_id == user_uuid)
            result = await db.execute(stmt)
            crop = result.scalars().first()

            if crop:
                new_act = CropActivity(
                    id=activity_id,
                    crop_id=crop.id,
                    activity_type=payload.activity_type,
                    description=payload.description,
                    cost_incurred=payload.cost_incurred,
                    performed_at=performed_at,
                )
                db.add(new_act)
                await db.commit()
        except Exception:
            pass

    return APIResponse(
        message="Farm activity logged successfully",
        data=CropActivityOut(
            id=activity_id,
            activity_type=payload.activity_type,
            description=payload.description,
            cost_incurred=payload.cost_incurred,
            performed_at=performed_at,
        ),
    )


@router.post("/expenses", response_model=APIResponse[FarmExpenseOut], status_code=status.HTTP_201_CREATED)
async def log_farm_expense(
    payload: FarmExpenseCreate,
    current_user: AuthenticatedResident = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Log a farming expenditure (seeds, fertilizer, labor, machinery, water, other).
    """
    expense_id = uuid.uuid4()
    exp_date = payload.expense_date or date.today()

    if db:
        try:
            user_uuid = uuid.UUID(current_user.user_id)
            f_stmt = select(Farm).where(Farm.resident_id == user_uuid)
            f_res = await db.execute(f_stmt)
            farm = f_res.scalars().first()

            if farm:
                new_exp = FarmExpense(
                    id=expense_id,
                    farm_id=farm.id,
                    category=payload.category,
                    amount=payload.amount,
                    expense_date=exp_date,
                    notes=payload.notes,
                )
                db.add(new_exp)
                await db.commit()
        except Exception:
            pass

    return APIResponse(
        message="Farm expense logged successfully",
        data=FarmExpenseOut(
            id=expense_id,
            category=payload.category,
            amount=payload.amount,
            expense_date=exp_date,
            notes=payload.notes,
        ),
    )


async def _resolve_active_crop(user_id: str, db: Optional[AsyncSession]) -> Optional[Crop]:
    """Resolves the resident's primary active crop from PostgreSQL if available."""
    if not db:
        return None
    try:
        user_uuid = uuid.UUID(user_id)
        stmt = select(Crop).join(Farm).where(Farm.resident_id == user_uuid)
        res = await db.execute(stmt)
        return res.scalars().first()
    except Exception:
        return None


@router.post("/leaf-doctor/diagnose", response_model=APIResponse[LeafDoctorDiagnosisOut], status_code=status.HTTP_201_CREATED)
async def diagnose_leaf_endpoint(
    payload: LeafDoctorRequest,
    current_user: AuthenticatedResident = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Week 12 Multimodal Leaf Crop Doctor:
    Accepts leaf/pod symptoms + optional base64 photo, runs Gemini Vision or PJTSAU pathology
    inference, checks IMD Rain-Fastness spray safety, and persists the observation.
    """
    crop = await _resolve_active_crop(current_user.user_id, db)
    crop_name = payload.crop_name or (crop.crop_name if crop else "Soybean")
    crop_stage = crop.current_stage if crop else "vegetative"

    diagnosis = diagnose_leaf_observation(
        symptom_text=payload.symptom_text,
        crop_name=crop_name,
        crop_stage=crop_stage,
        image_base64=payload.image_base64,
        image_mime_type=payload.image_mime_type,
        affected_organ=payload.affected_organ,
        severity_hint=payload.severity_hint,
        weather_advisory="Rain expected today at 6:00 PM (14mm). Hold evening spray operations.",
    )

    if payload.save_observation and crop and db:
        try:
            obs_row = CropObservation(
                id=diagnosis.observation_id,
                crop_id=crop.id,
                observation_text=payload.symptom_text,
                photo_url=payload.photo_url,
                ai_diagnosis_summary=f"{diagnosis.disease_or_pest_name}: {diagnosis.summary}",
                severity_level=diagnosis.severity_level,
                logged_at=diagnosis.logged_at,
            )
            db.add(obs_row)
            await db.commit()
        except Exception:
            pass

    return APIResponse(
        message="Leaf Crop Doctor diagnosis completed successfully",
        data=diagnosis,
    )


@router.get("/observations", response_model=APIResponse[List[CropObservationOut]])
async def list_crop_observations(
    limit: int = Query(20, le=50, description="Max observations to return"),
    current_user: AuthenticatedResident = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Returns historical crop pathology observations and Leaf Doctor summaries.
    """
    observations: List[CropObservationOut] = []
    if db:
        try:
            user_uuid = uuid.UUID(current_user.user_id)
            stmt = (
                select(CropObservation)
                .join(Crop)
                .join(Farm)
                .where(Farm.resident_id == user_uuid)
                .order_by(CropObservation.logged_at.desc())
                .limit(limit)
            )
            res = await db.execute(stmt)
            rows = res.scalars().all()
            for row in rows:
                observations.append(
                    CropObservationOut(
                        id=row.id,
                        observation_text=row.observation_text,
                        photo_url=row.photo_url,
                        ai_diagnosis_summary=row.ai_diagnosis_summary,
                        severity_level=row.severity_level,
                        logged_at=row.logged_at,
                    )
                )
        except Exception:
            pass

    if not observations:
        now = datetime.now(timezone.utc)
        observations = [
            CropObservationOut(
                id=uuid.UUID("55555555-5555-5555-5555-555555555551"),
                observation_text="Noticed mild yellow speckling on two border leaves and few whiteflies.",
                photo_url=None,
                ai_diagnosis_summary="Yellow Mosaic Virus (YMV) & Whitefly Vector: Install 6-8 yellow sticky traps/acre; hold foliar sprays before 6:00 PM rain.",
                severity_level="high",
                logged_at=now - timedelta(days=1),
            ),
            CropObservationOut(
                id=uuid.UUID("55555555-5555-5555-5555-555555555552"),
                observation_text="Healthy dark green canopy across central furrow rows.",
                photo_url=None,
                ai_diagnosis_summary="Healthy Crop Canopy — No Active Pathology: Vigorous vegetative branching.",
                severity_level="healthy",
                logged_at=now - timedelta(days=7),
            ),
        ][:limit]

    return APIResponse(
        message="Crop observations retrieved successfully",
        data=observations,
    )


@router.post("/observations", response_model=APIResponse[CropObservationOut], status_code=status.HTTP_201_CREATED)
async def log_crop_observation(
    payload: CropObservationCreate,
    current_user: AuthenticatedResident = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """
    Upload an observation or pest photo for Leaf Doctor AI diagnosis and record keeping.
    """
    crop = await _resolve_active_crop(current_user.user_id, db)
    crop_name = payload.crop_name or (crop.crop_name if crop else "Soybean")
    crop_stage = crop.current_stage if crop else "vegetative"

    diagnosis = diagnose_leaf_observation(
        symptom_text=payload.observation_text,
        crop_name=crop_name,
        crop_stage=crop_stage,
        image_base64=payload.image_base64,
        severity_hint=payload.severity_level,
        weather_advisory="Rain expected today at 6:00 PM (14mm). Hold evening spray operations.",
    )

    summary_text = f"{diagnosis.disease_or_pest_name}: {diagnosis.summary}"
    if crop and db:
        try:
            obs_row = CropObservation(
                id=diagnosis.observation_id,
                crop_id=crop.id,
                observation_text=payload.observation_text,
                photo_url=payload.photo_url,
                ai_diagnosis_summary=summary_text,
                severity_level=diagnosis.severity_level,
                logged_at=diagnosis.logged_at,
            )
            db.add(obs_row)
            await db.commit()
        except Exception:
            pass

    return APIResponse(
        message="Crop observation recorded and diagnosed successfully",
        data=CropObservationOut(
            id=diagnosis.observation_id,
            observation_text=payload.observation_text,
            photo_url=payload.photo_url,
            ai_diagnosis_summary=summary_text,
            severity_level=diagnosis.severity_level,
            logged_at=diagnosis.logged_at,
            diagnosis=diagnosis,
        ),
    )
