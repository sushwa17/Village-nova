import base64
import uuid
import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.core.security import get_current_user, AuthenticatedResident
from app.core.database import get_db
from app.services.leaf_doctor import diagnose_leaf_observation
from app.agents.dispatcher import dispatcher

client = TestClient(app)

MOCK_USER_ID = str(uuid.uuid4())
# Tiny valid 1x1 PNG bytes encoded to base64
SAMPLE_IMAGE_B64 = base64.b64encode(
    b"\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDR\x00\x00\x00\x01\x00\x00\x00\x01"
    b"\x08\x02\x00\x00\x00\x90wS\xde\x00\x00\x00\x0cIDATx\x9cc`\x00\x00\x00"
    b"\x02\x00\x01\xe2!\xbc3\x00\x00\x00\x00IEND\xaeB`\x82"
).decode("ascii")


async def override_get_current_user():
    return AuthenticatedResident(
        user_id=MOCK_USER_ID,
        phone="+919876543210",
        role="authenticated",
    )


async def override_get_db():
    yield None


app.dependency_overrides[get_current_user] = override_get_current_user
app.dependency_overrides[get_db] = override_get_db


class TestLeafDoctorService:
    """Unit tests for Week 12 Leaf Crop Doctor pathology engine."""

    def test_diagnose_yellow_mosaic_and_whitefly(self):
        diag = diagnose_leaf_observation(
            symptom_text="Leaves show bright yellow mosaic spots with small whiteflies underneath.",
            crop_name="Soybean",
            crop_stage="vegetative",
        )
        assert diag.is_healthy is False
        assert diag.severity_level == "high"
        assert "yellow mosaic" in diag.disease_or_pest_name.lower()
        assert diag.confidence_score >= 0.85
        assert diag.weather_spray_warning is not None
        assert "rain" in diag.weather_spray_warning.lower()
        assert len(diag.organic_remedies) >= 1
        assert len(diag.chemical_remedies) >= 1
        assert any("acetamiprid" in r.title.lower() for r in diag.chemical_remedies)
        assert len(diag.citations) >= 1

    def test_diagnose_spodoptera_caterpillar(self):
        diag = diagnose_leaf_observation(
            symptom_text="Leaves are chewed at margins by green leaf caterpillars.",
            crop_name="Soybean",
            crop_stage="vegetative",
        )
        assert diag.is_healthy is False
        assert diag.severity_level == "moderate"
        assert "spodoptera" in diag.disease_or_pest_name.lower()
        assert any("emamectin" in r.title.lower() for r in diag.chemical_remedies)

    def test_diagnose_pod_borer(self):
        diag = diagnose_leaf_observation(
            symptom_text="Green pods have holes from pod borer attack.",
            crop_name="Soybean",
            crop_stage="pod_formation",
        )
        assert diag.is_healthy is False
        assert diag.severity_level == "critical"
        assert diag.affected_organ == "pod"
        assert "pod borer" in diag.disease_or_pest_name.lower()
        assert any("chlorantraniliprole" in r.title.lower() for r in diag.chemical_remedies)

    def test_diagnose_cotton_pink_bollworm(self):
        diag = diagnose_leaf_observation(
            symptom_text="Cotton flowers look like rosette blooms due to pink bollworm.",
            crop_name="Cotton",
            crop_stage="flowering",
        )
        assert diag.is_healthy is False
        assert diag.severity_level == "high"
        assert "pink bollworm" in diag.disease_or_pest_name.lower()
        assert diag.affected_organ == "flower"

    def test_diagnose_fungal_rust_blight(self):
        diag = diagnose_leaf_observation(
            symptom_text="Reddish brown rust pustules appearing on lower soybean leaves.",
            crop_name="Soybean",
            crop_stage="pod_formation",
        )
        assert diag.is_healthy is False
        assert diag.severity_level == "high"
        assert "rust" in diag.disease_or_pest_name.lower()
        assert any("hexaconazole" in r.title.lower() for r in diag.chemical_remedies)

    def test_diagnose_healthy_canopy(self):
        diag = diagnose_leaf_observation(
            symptom_text="Healthy dark green leaf canopy with no spots or pests.",
            crop_name="Soybean",
            crop_stage="vegetative",
        )
        assert diag.is_healthy is True
        assert diag.severity_level == "healthy"
        assert diag.weather_spray_warning is None
        assert len(diag.chemical_remedies) == 0

    def test_base64_image_decoding_and_data_url_prefix(self):
        data_url = f"data:image/png;base64,{SAMPLE_IMAGE_B64}"
        diag = diagnose_leaf_observation(
            symptom_text="Yellow mosaic mottling observed in photo",
            crop_name="Soybean",
            image_base64=data_url,
        )
        assert diag.has_image_input is True
        assert diag.confidence_score >= 0.90
        assert "multimodal" in diag.model_used.lower()


class TestLeafDoctorAPI:
    """Integration tests for Week 12 Leaf Doctor endpoints."""

    def test_post_leaf_doctor_diagnose_ymv(self):
        response = client.post(
            "/v1/farm/leaf-doctor/diagnose",
            json={
                "crop_name": "Soybean",
                "symptom_text": "Yellow patches and whiteflies on leaf undersides",
                "affected_organ": "leaf",
                "save_observation": True,
            },
        )
        assert response.status_code == 201
        payload = response.json()
        assert payload["success"] is True
        data = payload["data"]
        assert data["severity_level"] == "high"
        assert "Yellow Mosaic" in data["disease_or_pest_name"]
        assert data["weather_spray_warning"] is not None
        assert len(data["organic_remedies"]) >= 1
        assert len(data["chemical_remedies"]) >= 1
        assert len(data["citations"]) >= 1

    def test_post_leaf_doctor_with_base64_image(self):
        response = client.post(
            "/v1/farm/leaf-doctor/diagnose",
            json={
                "crop_name": "Soybean",
                "symptom_text": "Chewed leaf margins seen in photo capture",
                "image_base64": SAMPLE_IMAGE_B64,
                "image_mime_type": "image/png",
            },
        )
        assert response.status_code == 201
        data = response.json()["data"]
        assert data["has_image_input"] is True
        assert data["severity_level"] == "moderate"
        assert "Spodoptera" in data["disease_or_pest_name"]

    def test_post_leaf_doctor_validation_error(self):
        response = client.post(
            "/v1/farm/leaf-doctor/diagnose",
            json={"crop_name": "Soybean", "symptom_text": "hi"},
        )
        assert response.status_code == 422

    def test_get_observations_list(self):
        response = client.get("/v1/farm/observations")
        assert response.status_code == 200
        payload = response.json()
        assert payload["success"] is True
        assert isinstance(payload["data"], list)
        assert len(payload["data"]) >= 1
        assert "ai_diagnosis_summary" in payload["data"][0]

    def test_post_observations_runs_leaf_doctor(self):
        response = client.post(
            "/v1/farm/observations",
            json={
                "crop_name": "Soybean",
                "observation_text": "Brown rust pustules noticed after cloudy week.",
                "severity_level": "moderate",
            },
        )
        assert response.status_code == 201
        data = response.json()["data"]
        assert data["severity_level"] == "high"
        assert "rust" in data["ai_diagnosis_summary"].lower()
        assert data["diagnosis"] is not None
        assert data["diagnosis"]["severity_level"] == "high"


@pytest.mark.asyncio
async def test_tool_dispatcher_diagnose_crop_leaf():
    """Verify diagnose_crop_leaf is registered in ToolDispatcher and executes cleanly."""
    tools = dispatcher.list_tools()
    assert any(t.name == "diagnose_crop_leaf" for t in tools)

    res = await dispatcher.execute_tool(
        "diagnose_crop_leaf",
        {
            "symptom_text": "Yellow mosaic specks and whitefly nymphs on leaves",
            "crop_name": "Soybean",
            "crop_stage": "vegetative",
        },
    )
    assert res.success is True
    assert res.data is not None
    assert res.data["severity_level"] == "high"
    assert len(res.data["organic_remedies"]) >= 1
