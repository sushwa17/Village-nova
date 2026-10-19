import pytest
from httpx import AsyncClient, ASGITransport
from app.main import app
from app.core.security import get_current_user, AuthenticatedResident
from app.core.database import get_db
import uuid

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


@pytest.mark.asyncio
async def test_ask_daily_guidance():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(
            "/v1/ask",
            json={"message": "What should I do on my farm today?", "language": "en"}
        )
        assert response.status_code == 200
        payload = response.json()
        assert payload["success"] is True
        data = payload["data"]
        assert "Soybean" in data["message"] or "Vegetative" in data["message"]
        assert len(data["actions"]) >= 2
        assert any(a["action_type"] in ["check_soil", "inspect_leaves", "photo_observation"] for a in data["actions"])
        assert data["why_advisory"] is not None
        assert len(data["sources"]) >= 1


@pytest.mark.asyncio
async def test_ask_mandi_rates_intent():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(
            "/v1/ask",
            json={"message": "What is today's soybean mandi price in Vikarabad?", "language": "en"}
        )
        assert response.status_code == 200
        data = response.json()["data"]
        assert "mandi" in data["message"].lower() or "price" in data["message"].lower()
        assert any(a["action_type"] == "view_mandi" for a in data["actions"])
        assert any("4,850" in a["title"] or "Soybean" in a["title"] for a in data["actions"])
        assert any("AGMARKNET" in s["title"] for s in data["sources"])


@pytest.mark.asyncio
async def test_ask_weather_and_spray_intent():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(
            "/v1/ask",
            json={"message": "Is it safe to spray fertilizer this evening?", "language": "en"}
        )
        assert response.status_code == 200
        data = response.json()["data"]
        assert "rain" in data["message"].lower() or "weather" in data["message"].lower()
        assert "runoff" in data["why_advisory"].lower() or "rain" in data["why_advisory"].lower()
        assert any("spray" in a["title"].lower() or "drainage" in a["title"].lower() for a in data["actions"])


@pytest.mark.asyncio
async def test_ask_pest_and_leaf_doctor_intent():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(
            "/v1/ask",
            json={"message": "I see yellow spots and insects on my soybean leaves, what to do?", "language": "en"}
        )
        assert response.status_code == 200
        data = response.json()["data"]
        assert "pest" in data["message"].lower() or "yellow" in data["message"].lower()
        assert any(a["action_type"] == "photo_observation" for a in data["actions"])
        assert any("Neem" in a["title"] or "photo" in a["title"].lower() for a in data["actions"])


@pytest.mark.asyncio
async def test_ask_schemes_and_subsidy_intent():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.post(
            "/v1/ask",
            json={"message": "Are there any active government subsidies for my 2.5 acre farm?", "language": "en"}
        )
        assert response.status_code == 200
        data = response.json()["data"]
        assert "scheme" in data["message"].lower() or "subsidy" in data["message"].lower()
        assert any(a["action_type"] == "check_scheme" for a in data["actions"])
        assert any("PM-KISAN" in a["title"] or "Rythu" in a["title"] for a in data["actions"])
