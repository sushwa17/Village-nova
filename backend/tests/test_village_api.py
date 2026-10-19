import pytest
from httpx import AsyncClient, ASGITransport
from app.main import app


@pytest.mark.asyncio
async def test_list_villages():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get("/v1/villages")
        assert response.status_code == 200
        payload = response.json()
        assert "data" in payload
        villages = payload["data"]
        assert len(villages) >= 1
        assert any("Ananthagiri" in v["name"] for v in villages)


@pytest.mark.asyncio
async def test_get_village_feed():
    village_id = "3fa85f64-5717-4562-b3fc-2c963f66afa6"
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get(f"/v1/villages/{village_id}/feed")
        assert response.status_code == 200
        payload = response.json()
        assert payload["success"] is True
        feed = payload["data"]
        assert feed["village_name"] == "Ananthagiri"
        assert "weather" in feed
        assert feed["weather"]["rainfall_mm"] == 14.0
        assert "mandi_prices" in feed
        assert len(feed["mandi_prices"]) >= 4
        assert "bulletins" in feed
        assert len(feed["bulletins"]) >= 1


@pytest.mark.asyncio
async def test_get_village_weather():
    village_id = "3fa85f64-5717-4562-b3fc-2c963f66afa6"
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        response = await client.get(f"/v1/villages/{village_id}/weather")
        assert response.status_code == 200
        data = response.json()["data"]
        assert data["temp_c"] > 0
        assert data["rain_prob_pct"] == 85
        assert len(data["hourly"]) >= 5
        assert "advisory" in data


@pytest.mark.asyncio
async def test_get_village_mandi_prices():
    village_id = "3fa85f64-5717-4562-b3fc-2c963f66afa6"
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        # 1. All commodities
        response = await client.get(f"/v1/villages/{village_id}/mandi")
        assert response.status_code == 200
        prices = response.json()["data"]
        assert any("Soybean" in p["commodity"] for p in prices)

        # 2. Filtered commodity
        filtered_resp = await client.get(f"/v1/villages/{village_id}/mandi?commodity=Cotton")
        assert filtered_resp.status_code == 200
        filtered_prices = filtered_resp.json()["data"]
        assert len(filtered_prices) >= 1
        assert "Cotton" in filtered_prices[0]["commodity"]


@pytest.mark.asyncio
async def test_post_and_filter_bulletins():
    village_id = "3fa85f64-5717-4562-b3fc-2c963f66afa6"
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        # Create new community bulletin
        new_bulletin = {
            "title": "🚜 Soil Health Card Distribution Camp",
            "content": "Free soil nutrient testing cards will be distributed at Gram Panchayat hall.",
            "category": "agriculture",
            "is_emergency": False,
            "author_name": "Gram Sarpanch",
            "author_role": "Village Council",
        }
        post_resp = await client.post(f"/v1/villages/{village_id}/bulletins", json=new_bulletin)
        assert post_resp.status_code == 201
        created = post_resp.json()["data"]
        assert created["title"] == new_bulletin["title"]
        assert created["category"] == "agriculture"

        # Filter by category
        filter_resp = await client.get(f"/v1/villages/{village_id}/bulletins?category=agriculture")
        assert filter_resp.status_code == 200
        items = filter_resp.json()["data"]
        assert any(item["title"] == new_bulletin["title"] for item in items)
