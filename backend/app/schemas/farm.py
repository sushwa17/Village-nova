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


class LeafDiagnosisRemedy(BaseModel):
    remedy_type: str  # organic, chemical, cultural
    title: str
    dosage: str
    application_method: str
    safety_note: Optional[str] = None


class LeafDoctorCitation(BaseModel):
    document_title: str
    authority: str
    official_url: Optional[str] = None
    published_date: str = "2026"


class LeafDoctorRequest(BaseModel):
    crop_name: str = "Soybean"
    symptom_text: str = Field(
        min_length=3,
        max_length=1500,
        description="Farmer description of leaf/pod/stem symptoms",
    )
    image_base64: Optional[str] = Field(
        default=None,
        description="Optional Base64-encoded leaf photo for multimodal Gemini Vision diagnosis",
    )
    image_mime_type: str = "image/jpeg"
    photo_url: Optional[str] = None
    affected_organ: Optional[str] = None  # leaf, pod, flower, stem, root
    severity_hint: Optional[str] = None
    save_observation: bool = True


class LeafDoctorDiagnosisOut(BaseModel):
    model_config = ConfigDict(from_attributes=True, protected_namespaces=())

    observation_id: UUID
    crop_name: str
    crop_stage: str
    disease_or_pest_name: str
    scientific_name: Optional[str] = None
    affected_organ: str = "leaf"
    severity_level: str  # healthy, mild, moderate, high, critical
    confidence_score: float = Field(ge=0.0, le=1.0)
    is_healthy: bool = False
    summary: str
    weather_spray_warning: Optional[str] = None
    organic_remedies: List[LeafDiagnosisRemedy] = Field(default_factory=list)
    chemical_remedies: List[LeafDiagnosisRemedy] = Field(default_factory=list)
    preventive_steps: List[str] = Field(default_factory=list)
    citations: List[LeafDoctorCitation] = Field(default_factory=list)
    model_used: str = "pjtsau-vision-agronomy-engine"
    has_image_input: bool = False
    logged_at: datetime


class CropObservationCreate(BaseModel):
    observation_text: str
    photo_url: Optional[str] = None
    severity_level: str = "mild"
    image_base64: Optional[str] = None
    crop_name: Optional[str] = None


class CropObservationOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)

    id: UUID
    observation_text: str
    photo_url: Optional[str] = None
    ai_diagnosis_summary: Optional[str] = None
    severity_level: str = "mild"
    logged_at: datetime
    diagnosis: Optional[LeafDoctorDiagnosisOut] = None


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
