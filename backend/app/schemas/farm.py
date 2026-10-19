from pydantic import BaseModel, Field
from typing import List, Optional
from uuid import UUID
from datetime import datetime, date


class CropActivityCreate(BaseModel):
    activity_type: str  # irrigation, fertilizer, pesticide, weeding, soil_check
    description: Optional[str] = None
    cost_incurred: float = 0.0


class CropActivityOut(BaseModel):
    id: UUID
    activity_type: str
    description: Optional[str] = None
    cost_incurred: float = 0.0
    performed_at: datetime

    class Config:
        from_attributes = True


class FarmExpenseCreate(BaseModel):
    category: str  # seeds, fertilizer, labor, machinery, water, other
    amount: float = Field(gt=0)
    notes: Optional[str] = None
    expense_date: Optional[date] = None


class FarmExpenseOut(BaseModel):
    id: UUID
    category: str
    amount: float
    expense_date: date
    notes: Optional[str] = None

    class Config:
        from_attributes = True


class CropObservationCreate(BaseModel):
    observation_text: str
    photo_url: Optional[str] = None
    severity_level: str = "mild"


class CropObservationOut(BaseModel):
    id: UUID
    observation_text: str
    photo_url: Optional[str] = None
    ai_diagnosis_summary: Optional[str] = None
    severity_level: str = "mild"
    logged_at: datetime

    class Config:
        from_attributes = True


class CropStageStep(BaseModel):
    stage_key: str
    title: str
    days_range: str
    is_completed: bool
    is_current: bool


class CropDetailOut(BaseModel):
    id: UUID
    crop_name: str
    variety: Optional[str] = None
    sowing_date: date
    days_since_sowing: int
    current_stage: str
    stage_progress_pct: int
    farming_goal: Optional[str] = None
    stages: List[CropStageStep] = Field(default_factory=list)

    class Config:
        from_attributes = True


class MyFarmOut(BaseModel):
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
