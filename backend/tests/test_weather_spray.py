import pytest
from httpx import AsyncClient, ASGITransport

from app.main import app
from app.agents.dispatcher import dispatcher
from app.services.weather import (
    resolve_village_coordinates,
    build_simulated_weather,
    parse_open_meteo_response,
    evaluate_spray_advisory,
)


class TestWeatherSprayEngine:
    """Unit tests for Week 13 Hyperlocal Weather & Dynamic Spray Advisory Engine."""

    def test_resolve_village_coordinates(self):
        lat, lon = resolve_village_coordinates("Ananthagiri")
        assert 17.0 < lat < 18.0
        assert 77.0 < lon < 78.5

        lat_k, lon_k = resolve_village_coordinates("Kondurg")
        assert lat_k == 17.06
        assert lon_k == 78.22

        # Unknown village gracefully resolves to Vikarabad baseline
        assert resolve_village_coordinates("UnknownHamlet") == (17.31, 77.86)

    def test_evening_rain_triggers_hold_spray_and_hold_irrigation(self):
        w = build_simulated_weather("Ananthagiri", scenario="default", crop_name="Soybean", crop_stage="vegetative")
        assert w.rainfall_mm == 14.0
        assert w.rain_prob_pct == 85
        assert w.spray_risk_level == "HIGH_RISK"
        assert w.spray_action == "HOLD_SPRAY"
        assert w.irrigation_action == "HOLD_IRRIGATION"
        assert any("Rain-Fastness" in r for r in w.trigger_reasons)
        assert "Tomorrow" in w.best_spray_window

    def test_clear_morning_triggers_spray_allowed(self):
        w = build_simulated_weather("Dharur", scenario="clear_morning", crop_name="Soybean", crop_stage="vegetative")
        assert w.spray_risk_level == "SAFE"
        assert w.spray_action == "SPRAY_ALLOWED"
        assert w.rainfall_mm == 0.0
        assert all(h.spray_safe for h in w.hourly)
        assert "Safe Today" in w.best_spray_window

    def test_high_wind_triggers_drift_hazard(self):
        w = build_simulated_weather("Parigi", scenario="high_wind")
        assert w.wind_speed_kmh >= 20.0
        assert w.spray_risk_level == "HIGH_RISK"
        assert w.spray_action == "HOLD_SPRAY"
        assert any("Wind Drift" in r for r in w.trigger_reasons)

    def test_dry_spell_flowering_triggers_protective_irrigation_and_bee_shield(self):
        w = build_simulated_weather("Ananthagiri", scenario="dry_spell", crop_name="Soybean", crop_stage="flowering")
        assert w.irrigation_action == "LIGHT_PROTECTIVE_IRRIGATION"
        assert w.spray_action == "SPRAY_ALLOWED"
        assert w.crop_stage_note is not None
        assert "Pollinator" in w.crop_stage_note
        assert any("Bee Pollinator" in r for r in w.trigger_reasons)

    def test_parse_open_meteo_response(self):
        sample_open_meteo_json = {
            "current": {
                "temperature_2m": 30.2,
                "relative_humidity_2m": 74,
                "wind_speed_10m": 11.5,
                "weather_code": 61,
            },
            "hourly": {
                "time": [
                    "2026-11-28T14:00",
                    "2026-11-28T15:00",
                    "2026-11-28T16:00",
                    "2026-11-28T17:00",
                    "2026-11-28T18:00",
                ],
                "temperature_2m": [30.5, 29.8, 28.0, 26.5, 25.0],
                "precipitation_probability": [20, 35, 75, 85, 40],
                "precipitation": [0.0, 0.4, 5.2, 7.0, 0.5],
                "wind_speed_10m": [10.0, 12.0, 16.5, 14.0, 9.0],
                "weather_code": [2, 3, 63, 80, 3],
            },
        }
        parsed = parse_open_meteo_response(
            sample_open_meteo_json,
            village_name="Kotepally",
            lat=17.345,
            lon=77.752,
        )
        assert parsed.village_name == "Kotepally"
        assert parsed.temp_c == 30.2
        assert parsed.rain_prob_pct == 85
        assert parsed.rainfall_mm == 13.1
        assert len(parsed.hourly) == 5
        assert parsed.hourly[0].time == "2:00 PM"
        assert parsed.hourly[0].spray_safe is True
        assert parsed.hourly[2].spray_safe is False
        assert parsed.spray_action == "HOLD_SPRAY"
        assert parsed.expected_rain_time == "5:00 PM"

    def test_evaluate_spray_advisory_heat_caution(self):
        meta = evaluate_spray_advisory(
            temp_c=37.5,
            humidity_pct=28,
            wind_speed_kmh=9.0,
            rain_prob_pct=5,
            rainfall_mm=0.0,
            hourly=[],
            crop_name="Cotton",
            crop_stage="vegetative",
        )
        assert meta["spray_risk_level"] == "CAUTION"
        assert meta["spray_action"] == "SPRAY_WITH_CAUTION"
        assert any("Evaporation" in r for r in meta["trigger_reasons"])


class TestWeatherSprayAPI:
    """Integration tests for Week 13 Weather & Dynamic Spray Advisory endpoints."""

    @pytest.mark.asyncio
    async def test_get_village_weather_scenarios(self):
        vid = "3fa85f64-5717-4562-b3fc-2c963f66afa6"
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            r_clear = await client.get(f"/v1/villages/{vid}/weather?scenario=clear_morning")
            assert r_clear.status_code == 200
            d_clear = r_clear.json()["data"]
            assert d_clear["spray_risk_level"] == "SAFE"
            assert d_clear["spray_action"] == "SPRAY_ALLOWED"

            r_wind = await client.get(f"/v1/villages/{vid}/weather?scenario=high_wind")
            assert r_wind.status_code == 200
            d_wind = r_wind.json()["data"]
            assert d_wind["spray_risk_level"] == "HIGH_RISK"
            assert d_wind["spray_action"] == "HOLD_SPRAY"

    @pytest.mark.asyncio
    async def test_get_village_spray_advisory_endpoint(self):
        vid = "4fa85f64-5717-4562-b3fc-2c963f66afa7"  # Dharur
        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            resp = await client.get(
                f"/v1/villages/{vid}/spray-advisory?crop_name=Soybean&crop_stage=flowering&scenario=dry_spell"
            )
            assert resp.status_code == 200
            data = resp.json()["data"]
            assert data["village_name"] == "Dharur"
            assert data["is_spray_safe_now"] is True
            assert data["irrigation_action"] == "LIGHT_PROTECTIVE_IRRIGATION"
            assert data["rain_fast_hours_required"] == 4
            assert len(data["trigger_reasons"]) >= 1

    @pytest.mark.asyncio
    async def test_tool_dispatcher_evaluate_spray_window(self):
        tools = dispatcher.list_tools()
        assert any(t.name == "evaluate_spray_window" for t in tools)

        res = await dispatcher.execute_tool(
            "evaluate_spray_window",
            {
                "village": "Ananthagiri",
                "crop_name": "Soybean",
                "crop_stage": "vegetative",
                "scenario": "clear_morning",
            },
        )
        assert res.success is True
        assert res.data is not None
        assert res.data["is_spray_safe_now"] is True
        assert res.data["spray_action"] == "SPRAY_ALLOWED"
