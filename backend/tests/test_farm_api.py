from fastapi.testclient import TestClient
from app.main import app
from app.core.security import get_current_user, AuthenticatedResident
from app.core.database import get_db
import uuid

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


def test_get_my_farm():
    """
    Test GET /v1/farm/my-farm returns farm, active crop, stage progress, and timeline.
    """
    response = client.get("/v1/farm/my-farm")
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert "farm_name" in data["data"]
    assert "crop" in data["data"]
    crop = data["data"]["crop"]
    assert crop["crop_name"] == "Soybean"
    assert crop["days_since_sowing"] == 42
    assert crop["current_stage"] == "vegetative"
    assert len(crop["stages"]) >= 5


def test_log_crop_activity():
    """
    Test POST /v1/farm/activities logs a field operation.
    """
    payload = {
        "activity_type": "irrigation",
        "description": "Borewell drip irrigation for 3 hours",
        "cost_incurred": 0.0
    }
    response = client.post("/v1/farm/activities", json=payload)
    assert response.status_code == 201
    data = response.json()
    assert data["success"] is True
    assert data["data"]["activity_type"] == "irrigation"


def test_log_farm_expense():
    """
    Test POST /v1/farm/expenses records farm financial entry.
    """
    payload = {
        "category": "fertilizer",
        "amount": 1450.0,
        "notes": "1 bag DAP 18-46-0"
    }
    response = client.post("/v1/farm/expenses", json=payload)
    assert response.status_code == 201
    data = response.json()
    assert data["success"] is True
    assert data["data"]["amount"] == 1450.0
    assert data["data"]["category"] == "fertilizer"


def test_log_crop_observation():
    """
    Test POST /v1/farm/observations records photo observation and returns summary.
    """
    payload = {
        "observation_text": "Leaves look dark green and healthy, no yellow spots.",
        "severity_level": "none"
    }
    response = client.post("/v1/farm/observations", json=payload)
    assert response.status_code == 201
    data = response.json()
    assert data["success"] is True
    assert "observation_text" in data["data"]


def test_list_and_toggle_task():
    """
    Test GET /v1/tasks and PATCH /v1/tasks/{id}/toggle.
    """
    res_list = client.get("/v1/tasks")
    assert res_list.status_code == 200
    tasks = res_list.json()["data"]
    assert len(tasks) > 0

    task_id = tasks[0]["id"]
    res_toggle = client.patch(f"/v1/tasks/{task_id}/toggle")
    assert res_toggle.status_code == 200
    data = res_toggle.json()
    assert data["success"] is True
    assert data["data"]["id"] == task_id
