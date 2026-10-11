from pydantic import BaseModel, Field
from typing import List, Optional
from uuid import UUID
from datetime import datetime


class VillageOut(BaseModel):
    id: UUID
    name: str
    mandal: str
    district: str
    state: str
    pincode: Optional[str] = None

    class Config:
        from_attributes = True


class ResidentRoleOut(BaseModel):
    id: UUID
    role: str
    is_primary: bool

    class Config:
        from_attributes = True


class ResidentProfileOut(BaseModel):
    id: UUID
    full_name: str
    phone_number: Optional[str] = None
    village_id: Optional[UUID] = None
    village_name: Optional[str] = None
    preferred_language: str
    verified_badge: bool
    roles: List[str] = Field(default_factory=list)
    created_at: datetime

    class Config:
        from_attributes = True


class FarmOnboardingInput(BaseModel):
    farm_name: str = "Main Farm"
    land_acres: float
    soil_type: str = "unknown"
    water_source: str = "other"
    main_crop: str
    sowing_date: Optional[str] = None


class OnboardingRequest(BaseModel):
    full_name: str
    village_id: Optional[UUID] = None
    village_name: Optional[str] = None
    preferred_language: str = "en"
    roles: List[str] = Field(min_length=1)  # ['farmer', 'student', etc.]
    farm: Optional[FarmOnboardingInput] = None
