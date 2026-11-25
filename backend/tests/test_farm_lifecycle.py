import pytest
from datetime import date, timedelta
from fastapi.testclient import TestClient
import uuid

from app.main import app
from app.core.security import get_current_user, AuthenticatedResident
from app.core.database import get_db
from app.services.lifecycle import calculate_crop_lifecycle
from app.agents.context_builder import build_resident_context

client = TestClient(app)

MOCK_USER_ID = str(uuid.uuid4())


async def override_get_current_user():
    return AuthenticatedResident(
        user_id=MOCK_USER_ID,
        phone="+919876543210",
        role="authenticated"
    )


async def override_get_db():
    yield None


app.dependency_overrides[get_current_user] = override_get_current_user
app.dependency_overrides[get_db] = override_get_db


class TestCropLifecycleService:
    """Direct unit tests for phenological crop lifecycle engine."""

    def test_sowing_stage_calculation(self):
        result = calculate_crop_lifecycle(crop_name="Soybean", days_elapsed=3)
        assert result.current_stage == "sowing"
        assert result.stage_title == "Sowing & Seeding"
        assert result.days_since_sowing == 3
        assert result.days_in_current_stage == 3
        assert result.days_remaining_in_stage == 2  # End of sowing is day 5
        assert result.stage_progress_pct == 60  # Day 3 of 5 = 60%
        assert len(result.active_risks) >= 1
        assert len(result.priority_actions) == 3

    def test_germination_stage_calculation(self):
        result = calculate_crop_lifecycle(crop_name="Soybean", days_elapsed=10)
        assert result.current_stage == "germination"
        assert result.stage_title == "Germination & Emergence"
        assert result.days_since_sowing == 10
        assert result.days_remaining_in_stage == 2  # End of germination is day 12
        assert any("damping-off" in r.risk_title.lower() or "crusting" in r.risk_title.lower() for r in result.active_risks)

    def test_vegetative_stage_calculation(self):
        result = calculate_crop_lifecycle(crop_name="Soybean", days_elapsed=42)
        assert result.current_stage == "vegetative"
        assert result.stage_title == "Vegetative & Branching"
        assert result.days_since_sowing == 42
        assert result.days_remaining_in_stage == 13  # End of vegetative is day 55
        # Must flag Whitefly vector for Yellow Mosaic Virus
        assert any("whitefly" in r.risk_title.lower() or "mosaic" in r.risk_title.lower() for r in result.active_risks)
        assert any(rec.category == "pest_management" for rec in result.recommendations)

    def test_flowering_stage_calculation(self):
        result = calculate_crop_lifecycle(crop_name="Soybean", days_elapsed=65)
        assert result.current_stage == "flowering"
        assert result.stage_title == "Flowering & Blossom"
        assert result.days_since_sowing == 65
        assert result.days_remaining_in_stage == 10  # End of flowering is day 75
        assert any(r.severity == "critical" for r in result.active_risks)

    def test_pod_formation_stage_calculation(self):
        result = calculate_crop_lifecycle(crop_name="Soybean", days_elapsed=85)
        assert result.current_stage == "pod_formation"
        assert result.stage_title == "Pod Formation & Grain Fill"
        assert result.days_since_sowing == 85
        assert any("borer" in r.risk_title.lower() for r in result.active_risks)

    def test_harvest_stage_calculation(self):
        result = calculate_crop_lifecycle(crop_name="Soybean", days_elapsed=110)
        assert result.current_stage == "harvest"
        assert result.stage_title == "Maturity & Harvest"
        assert result.days_since_sowing == 110
        assert result.days_to_harvest == 5
        assert any("shattering" in r.risk_title.lower() for r in result.active_risks)


class TestCropLifecycleAPI:
    """Integration tests for farm lifecycle & activities endpoints."""

    def test_get_lifecycle_default(self):
        response = client.get("/v1/farm/lifecycle")
        assert response.status_code == 200
        payload = response.json()
        assert payload["success"] is True
        data = payload["data"]
        assert data["crop_name"] == "Soybean"
        assert data["current_stage"] == "vegetative"
        assert data["days_since_sowing"] == 42
        assert len(data["stages"]) == 6
        assert len(data["active_risks"]) >= 1
        assert len(data["recommendations"]) >= 1
        assert len(data["priority_actions"]) == 3

    def test_get_lifecycle_simulation_scrubbing(self):
        # Simulate flowering stage (Day 65)
        response = client.get("/v1/farm/lifecycle?days_elapsed=65")
        assert response.status_code == 200
        data = response.json()["data"]
        assert data["current_stage"] == "flowering"
        assert data["days_since_sowing"] == 65
        assert data["stage_title"] == "Flowering & Blossom"

        # Simulate pod formation stage (Day 85)
        response_pod = client.get("/v1/farm/lifecycle?days_elapsed=85")
        assert response_pod.status_code == 200
        data_pod = response_pod.json()["data"]
        assert data_pod["current_stage"] == "pod_formation"
        assert data_pod["days_since_sowing"] == 85

    def test_get_farm_activities(self):
        response = client.get("/v1/farm/activities")
        assert response.status_code == 200
        payload = response.json()
        assert payload["success"] is True
        activities = payload["data"]
        assert isinstance(activities, list)
        assert len(activities) >= 1

    def test_get_farm_activities_filtered(self):
        response = client.get("/v1/farm/activities?activity_type=fertilizer")
        assert response.status_code == 200
        payload = response.json()
        assert payload["success"] is True
        activities = payload["data"]
        for act in activities:
            assert act["activity_type"] == "fertilizer"

    def test_log_activity_with_performed_at(self):
        custom_time = (date.today() - timedelta(days=1)).isoformat() + "T10:30:00Z"
        payload = {
            "activity_type": "scouting",
            "description": "Scouted row borders for yellow sticky trap counts",
            "cost_incurred": 0.0,
            "performed_at": custom_time,
        }
        response = client.post("/v1/farm/activities", json=payload)
        assert response.status_code == 201
        data = response.json()["data"]
        assert data["activity_type"] == "scouting"
        assert data["description"] == payload["description"]
        assert "performed_at" in data


@pytest.mark.asyncio
async def test_build_resident_context_contains_lifecycle():
    """Verify context builder injects crop lifecycle data into AI context."""
    context = await build_resident_context(MOCK_USER_ID, db=None)
    assert "crop" in context
    crop = context["crop"]
    assert crop["crop_name"] == "Soybean"
    assert crop["current_stage"] == "vegetative"
    assert crop["days_since_sowing"] == 42
    assert "stage_title" in crop
    assert "days_to_harvest" in crop
