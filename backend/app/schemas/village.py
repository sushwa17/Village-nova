from pydantic import BaseModel, Field, ConfigDict
from typing import List, Optional
from datetime import datetime


class VillageUpdateBase(BaseModel):
    title: str = Field(..., max_length=255)
    content: str
    category: str = Field(default="panchayat")  # panchayat, agriculture, health, emergency, community
    is_emergency: bool = False
    author_name: Optional[str] = "Panchayat Secretary"
    author_role: Optional[str] = "Gram Panchayat Admin"


class VillageUpdateCreate(VillageUpdateBase):
    pass


class VillageUpdateOut(VillageUpdateBase):
    id: str
    village_id: str
    is_verified: bool = True
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)


class WeatherHourOut(BaseModel):
    time: str
    temp_c: float
    rain_prob: int
    condition: str
    icon: str
    rainfall_mm: float = 0.0
    wind_speed_kmh: float = 10.0
    spray_safe: bool = True


class VillageWeatherOut(BaseModel):
    village_name: str
    temp_c: float
    condition: str
    humidity_pct: int
    wind_speed_kmh: float
    rain_prob_pct: int
    rainfall_mm: float
    expected_rain_time: Optional[str] = None
    advisory: str
    hourly: List[WeatherHourOut] = []
    latitude: float = 17.31
    longitude: float = 77.86
    source: str = "Open-Meteo High-Resolution Rural Grid (Calibrated)"
    spray_risk_level: str = "HIGH_RISK"  # SAFE, CAUTION, HIGH_RISK
    spray_action: str = "HOLD_SPRAY"  # SPRAY_ALLOWED, SPRAY_WITH_CAUTION, HOLD_SPRAY
    best_spray_window: str = "Tomorrow 6:00 AM - 10:00 AM"
    irrigation_action: str = "HOLD_IRRIGATION"  # HOLD_IRRIGATION, LIGHT_PROTECTIVE_IRRIGATION, NORMAL_MONITORING
    trigger_reasons: List[str] = Field(default_factory=list)
    crop_stage_note: Optional[str] = None


class SprayAdvisoryOut(BaseModel):
    village_id: str
    village_name: str
    crop_name: str
    crop_stage: str
    scenario: str = "default"
    spray_risk_level: str  # SAFE, CAUTION, HIGH_RISK
    spray_action: str  # SPRAY_ALLOWED, SPRAY_WITH_CAUTION, HOLD_SPRAY
    is_spray_safe_now: bool
    best_spray_window: str
    irrigation_action: str
    rain_fast_hours_required: int = 4
    trigger_reasons: List[str] = Field(default_factory=list)
    advisory_summary: str
    weather: VillageWeatherOut


class MandiPriceOut(BaseModel):
    commodity: str
    market: str
    modal_price: float
    min_price: float
    max_price: float
    unit: str = "Quintal"
    price_change: float = 0.0
    trend: str = "stable"  # up, down, stable
    reported_date: str


class VillageFeedOut(BaseModel):
    village_id: str
    village_name: str
    mandal: str
    district: str
    active_alerts_count: int = 0
    weather: VillageWeatherOut
    mandi_prices: List[MandiPriceOut] = []
    bulletins: List[VillageUpdateOut] = []
