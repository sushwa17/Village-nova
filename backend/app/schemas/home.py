from pydantic import BaseModel, Field
from typing import List, Optional


class TodayActionItem(BaseModel):
    id: str
    title: str
    tag: str
    action_type: str  # log_activity, check_soil, inspect_leaves, photo_observation
    completed: bool = False


class ProgressSummary(BaseModel):
    completed: int
    total: int
    percentage: int


class WeatherSummary(BaseModel):
    headline: str
    temperature_c: float
    rainfall_mm: float
    advisory: str


class HomeDashboardPayload(BaseModel):
    greeting: str
    resident_name: str
    location_label: str
    weather: WeatherSummary
    today_actions: List[TodayActionItem] = Field(default_factory=list)
    progress: ProgressSummary
    village_updates_count: int = 0
    scheme_matches_count: int = 0
