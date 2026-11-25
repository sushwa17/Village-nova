from pydantic import BaseModel, Field, ConfigDict
from typing import List, Optional
from uuid import UUID
from datetime import datetime, date


class CropActivityCreate(BaseModel):
    activity_type: str  # irrigation, fertilizer, pesticide, weeding, soil_check, scouting, harvesting
    description: Optional[str] = None
    cost_incurred: float = 0.0
    performed_at: Optional[datetime] = None


class CropActivityOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    activity_type: str
    description: Optional[str] = None
    cost_incurred: float = 0.0
    performed_at: datetime


class FarmExpenseCreate(BaseModel):
    category: str  # seeds, fertilizer, labor, machinery, water, other
    amount: float = Field(gt=0)
    notes: Optional[str] = None
    expense_date: Optional[date] = None


class FarmExpenseOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    category: str
    amount: float
    expense_date: date
    notes: Optional[str] = None


class CropObservationCreate(BaseModel):
    observation_text: str
    photo_url: Optional[str] = None
    severity_level: str = "mild"


class CropObservationOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    observation_text: str
    photo_url: Optional[str] = None
    ai_diagnosis_summary: Optional[str] = None
    severity_level: str = "mild"
    logged_at: datetime


class CropStageStep(BaseModel):
    stage_key: str
    title: str
    days_range: str
    is_completed: bool
    is_current: bool
    description: Optional[str] = None


class CropLifecycleRisk(BaseModel):
    risk_title: str
    severity: str  # low, moderate, high, critical
    mitigation: str
    affected_organ: str  # leaf, root, flower, pod, soil


class CropStageRecommendation(BaseModel):
    category: str  # irrigation, nutrient, pest_management, cultural
    recommendation: str
    urgency: str  # immediate, planned, optional
    source: str = "PJTSAU Package of Practices 2026"


class CropLifecycleOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    crop_name: str
    variety: Optional[str] = None
    sowing_date: date
    days_since_sowing: int
    current_stage_key: str
    current_stage_title: str
    stage_days_range: str
    days_in_current_stage: int
    days_remaining_in_stage: int
    stage_progress_pct: int
    overall_progress_pct: int
    expected_harvest_date: date
    days_to_harvest: int
    farming_goal: Optional[str] = None
    active_risks: List[CropLifecycleRisk] = Field(default_factory=list)
    stage_recommendations: List[CropStageRecommendation] = Field(default_factory=list)
    daily_priority_actions: List[str] = Field(default_factory=list)
    stages: List[CropStageStep] = Field(default_factory=list)

    # Convenience aliases for frontend and tests
    current_stage: Optional[str] = None
    stage_title: Optional[str] = None
    recommendations: List[CropStageRecommendation] = Field(default_factory=list)
    priority_actions: List[str] = Field(default_factory=list)


class CropDetailOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    crop_name: str
    variety: Optional[str] = None
    sowing_date: date
    days_since_sowing: int
    current_stage: str
    stage_progress_pct: int
    farming_goal: Optional[str] = None
    stages: List[CropStageStep] = Field(default_factory=list)


class MyFarmOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    farm_id: UUID
    farm_name: str
    land_acres: float
    soil_type: str
    water_source: str
    crop: Optional[CropDetailOut] = None
    total_expenses: float = 0.0
    recent_activities: List[CropActivityOut] = Field(default_factory=list)
    recent_expenses: List[FarmExpenseOut] = Field(default_factory=list)
    weather_advisory: str
