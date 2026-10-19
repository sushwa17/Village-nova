import pytest
from httpx import AsyncClient, ASGITransport
import uuid

from app.main import app
from app.core.security import get_current_user, AuthenticatedResident
from app.core.database import get_db
from app.agents.dispatcher import dispatcher, ToolDispatcher

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
async def test_dispatcher_registration_and_listing():
    tools = dispatcher.list_tools()
    tool_names = [t.name for t in tools]
    assert len(tool_names) >= 6
    assert "get_hyperlocal_weather" in tool_names
    assert "get_crop_stage_guidance" in tool_names
    assert "get_mandi_prices" in tool_names
    assert "get_pending_tasks" in tool_names
    assert "check_scheme_eligibility" in tool_names
    assert "execute_quick_farm_action" in tool_names


@pytest.mark.asyncio
async def test_dispatch_weather_tool():
    res = await dispatcher.execute_tool(
        "get_hyperlocal_weather",
        {"village": "Ananthagiri", "district": "Vikarabad"}
    )
    assert res.success is True
    assert res.data is not None
    assert res.data["forecast_rain_expected"] is True
    assert res.data["expected_precipitation_mm"] == 14.0
    assert res.data["spray_hazard"] == "HIGH_RISK"
    assert res.execution_time_ms >= 0


@pytest.mark.asyncio
async def test_dispatch_crop_guidance_tool():
    res = await dispatcher.execute_tool(
        "get_crop_stage_guidance",
        {"crop_name": "Soybean", "stage": "vegetative", "days_since_sowing": 42}
    )
    assert res.success is True
    assert res.data["crop"] == "Soybean (JS-335)"
    assert res.data["stage"] == "vegetative"
    assert any("Whitefly" in v for v in res.data["key_vulnerabilities"])


@pytest.mark.asyncio
async def test_dispatch_mandi_prices_tool():
    res = await dispatcher.execute_tool(
        "get_mandi_prices",
        {"commodity": "Soybean", "market": "Vikarabad"}
    )
    assert res.success is True
    assert res.data["modal_price_per_q"] == 4850
    assert res.data["trend"] == "UPWARD"
    assert "Vikarabad APMC" in res.data["market_name"]


@pytest.mark.asyncio
async def test_dispatch_scheme_eligibility_tool():
    res = await dispatcher.execute_tool(
        "check_scheme_eligibility",
        {"land_acres": 2.5, "crop_name": "Soybean", "village": "Ananthagiri"}
    )
    assert res.success is True
    assert res.data["total_eligible_schemes"] >= 2
    schemes = res.data["schemes"]
    assert any(s["scheme_id"] == "pm_kisan" for s in schemes)
    assert any(s["scheme_id"] == "rythu_bharosa" for s in schemes)


@pytest.mark.asyncio
async def test_dispatch_quick_farm_action_tool():
    res = await dispatcher.execute_tool(
        "execute_quick_farm_action",
        {"user_id": MOCK_USER_ID, "action_type": "check_soil", "notes": "Tested furrow moisture"}
    )
    assert res.success is True
    assert res.data["action_type"] == "check_soil"
    assert res.data["user_id"] == MOCK_USER_ID


@pytest.mark.asyncio
async def test_dispatch_unknown_tool_fails_gracefully():
    res = await dispatcher.execute_tool(
        "non_existent_tool_xyz",
        {"param": "val"}
    )
    assert res.success is False
    assert "not registered" in res.error.lower()


@pytest.mark.asyncio
async def test_api_get_tools_endpoint():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get("/v1/ask/tools")
        assert response.status_code == 200
        payload = response.json()
        assert payload["success"] is True
        data = payload["data"]
        assert data["total_tools"] >= 6
        assert any(t["name"] == "get_hyperlocal_weather" for t in data["tools"])


@pytest.mark.asyncio
async def test_api_post_action_card_dispatch():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        # 1. Soil inspection action
        resp1 = await client.post(
            "/v1/ask/action",
            json={
                "action_id": "act_101",
                "action_type": "check_soil",
                "payload": {"crop": "Soybean"}
            }
        )
        assert resp1.status_code == 200
        data1 = resp1.json()["data"]
        assert data1["success"] is True
        assert data1["action_status"] == "completed"
        assert "Recorded 'check_soil'" in data1["feedback_message"]

        # 2. View Mandi action
        resp2 = await client.post(
            "/v1/ask/action",
            json={
                "action_id": "act_102",
                "action_type": "view_mandi",
                "payload": {"commodity": "Soybean", "market": "Vikarabad"}
            }
        )
        assert resp2.status_code == 200
        data2 = resp2.json()["data"]
        assert data2["action_status"] == "retrieved"
        assert data2["result_data"]["modal_price_per_q"] == 4850

        # 3. Check scheme action
        resp3 = await client.post(
            "/v1/ask/action",
            json={
                "action_id": "act_103",
                "action_type": "check_scheme",
                "payload": {"scheme_id": "pm_kisan"}
            }
        )
        assert resp3.status_code == 200
        data3 = resp3.json()["data"]
        assert data3["action_status"] == "verified"
        assert "pm_kisan" in str(data3["result_data"])

        # 4. Photo observation action
        resp4 = await client.post(
            "/v1/ask/action",
            json={
                "action_id": "act_104",
                "action_type": "photo_observation",
                "payload": {"mode": "diagnostic"}
            }
        )
        assert resp4.status_code == 200
        data4 = resp4.json()["data"]
        assert data4["action_status"] == "ready_for_capture"
        assert "obs_sess_act_104" in data4["result_data"]["session_id"]
