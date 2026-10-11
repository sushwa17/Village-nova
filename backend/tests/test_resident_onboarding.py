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


def test_list_villages():
    """
    Test GET /v1/villages returns verified list of villages.
    """
    response = client.get("/v1/villages")
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert len(data["data"]) >= 5
    village_names = [v["name"] for v in data["data"]]
    assert "Ananthagiri" in village_names


def test_search_villages():
    """
    Test GET /v1/villages?q=dharur filters matching villages.
    """
    response = client.get("/v1/villages?q=dharur")
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert len(data["data"]) >= 1
    assert data["data"][0]["name"] == "Dharur"


def test_farmer_onboarding():
    """
    Test POST /v1/resident/onboarding with Farmer persona.
    """
    payload = {
        "full_name": "Ravi Kumar",
        "village_name": "Ananthagiri (Vikarabad)",
        "preferred_language": "te",
        "roles": ["farmer"],
        "farm": {
            "farm_name": "Ravi Soya Field",
            "land_acres": 2.5,
            "soil_type": "black",
            "water_source": "borewell",
            "main_crop": "Soybean",
            "sowing_date": "2024-06-15"
        }
    }
    response = client.post("/v1/resident/onboarding", json=payload)
    assert response.status_code == 201
    data = response.json()
    assert data["success"] is True
    assert data["data"]["full_name"] == "Ravi Kumar"
    assert "farmer" in data["data"]["roles"]
    assert data["data"]["village_name"] == "Ananthagiri (Vikarabad)"


def test_student_onboarding():
    """
    Test POST /v1/resident/onboarding with Student persona (non-farmer).
    """
    payload = {
        "full_name": "Priya Sharma",
        "village_name": "Kotepally",
        "preferred_language": "en",
        "roles": ["student"],
    }
    response = client.post("/v1/resident/onboarding", json=payload)
    assert response.status_code == 201
    data = response.json()
    assert data["success"] is True
    assert data["data"]["full_name"] == "Priya Sharma"
    assert "student" in data["data"]["roles"]


def test_get_my_profile():
    """
    Test GET /v1/resident/me returns current user profile.
    """
    response = client.get("/v1/resident/me")
    assert response.status_code == 200
    data = response.json()
    assert data["success"] is True
    assert "full_name" in data["data"]
    assert "roles" in data["data"]
