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


def test_health_endpoint():
    response = client.get("/v1/health")
    assert response.status_code == 200
    assert response.json()["status"] == "healthy"


def test_ask_endpoint():
    response = client.post(
        "/v1/ask",
        json={"message": "What should I do on my farm today?"}
    )
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert "actions" in data["data"]
    assert len(data["data"]["actions"]) > 0


def test_ask_mandi_endpoint():
    response = client.post(
        "/v1/ask",
        json={"message": "What are the mandi prices today?"}
    )
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert "Mandi" in data["data"]["message"] or "mandi" in data["data"]["message"]


def test_home_endpoint():
    response = client.get("/v1/home")
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert "weather" in data["data"]
    assert "today_actions" in data["data"]
