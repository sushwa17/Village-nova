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
