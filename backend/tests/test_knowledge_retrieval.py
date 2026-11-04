import pytest
from httpx import AsyncClient, ASGITransport
import uuid

from app.main import app
from app.core.security import get_current_user, AuthenticatedResident
from app.core.database import get_db
from app.services.knowledge import knowledge_service

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


def test_search_soybean_pest_grounding():
    results = knowledge_service.search("whitefly yellow mosaic soybean treatment", top_k=2)
    assert len(results) >= 1
    top_doc = results[0]
    assert "Soybean" in top_doc.document_title or "PJTSAU" in top_doc.authority
    assert top_doc.is_verified is True
    assert "https://" in top_doc.official_url
    assert top_doc.similarity_score > 0.20


def test_search_pmkisan_scheme_grounding():
    results = knowledge_service.search("pm kisan subsidy aadhaar bank seeding", top_k=2, domain="schemes")
    assert len(results) >= 1
    titles = [r.document_title for r in results]
    assert any("PM-KISAN" in t or "Kisan" in t for t in titles)
    assert all(r.domain == "schemes" for r in results)


def test_search_weather_spray_grounding():
    results = knowledge_service.search("rain spray pesticide weather foliar safety", top_k=2, domain="weather")
    assert len(results) >= 1
    top = results[0]
    assert "IMD" in top.authority or "Weather" in top.document_title
    assert "mausam.imd.gov.in" in top.official_url


def test_search_mandi_standards_grounding():
    results = knowledge_service.search("vikarabad apmc soybean moisture price", top_k=2, domain="mandi")
    assert len(results) >= 1
    top = results[0]
    assert "AGMARKNET" in top.document_title or "APMC" in top.authority
    assert "agmarknet.gov.in" in top.official_url


def test_domain_filtering():
    results = knowledge_service.search("fertilizer", domain="schemes")
    assert all(r.domain == "schemes" for r in results)


def test_custom_chunk_indexing_and_retrieval():
    new_chunk = knowledge_service.index_chunk(
        document_title="Telangana Soil Health Card Micronutrient Advisory 2026",
        authority="Department of Agriculture Telangana",
        domain="agronomy",
        chunk_text="Zinc deficiency in Vikarabad red-chalka soils can be corrected by applying 50kg Zinc Sulphate per hectare.",
        official_url="https://agri.telangana.gov.in/soil-health"
    )
    assert new_chunk.id.startswith("kb_custom_")

    search_hits = knowledge_service.search("Zinc deficiency Vikarabad soil", top_k=2)
    assert any(h.chunk_id == new_chunk.id for h in search_hits)


@pytest.mark.asyncio
async def test_api_list_knowledge_documents():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        resp = await client.get("/v1/knowledge/documents")
        assert resp.status_code == 200
        data = resp.json()["data"]
        assert len(data) >= 6
        assert any("PJTSAU" in d["authority"] for d in data)
        assert any(d["domain"] == "schemes" for d in data)


@pytest.mark.asyncio
async def test_api_post_knowledge_search():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        resp = await client.post(
            "/v1/knowledge/search",
            json={
                "query": "soybean whitefly control",
                "domain": "agronomy",
                "top_k": 3
            }
        )
        assert resp.status_code == 200
        payload = resp.json()
        assert payload["success"] is True
        data = payload["data"]
        assert len(data) >= 1
        assert "PJTSAU" in data[0]["authority"]
        assert data[0]["official_url"] is not None


@pytest.mark.asyncio
async def test_api_post_knowledge_chunks():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        resp = await client.post(
            "/v1/knowledge/chunks",
            json={
                "document_title": "Telangana Drip Irrigation Subsidy Notification",
                "authority": "TSMIP Hyderabad",
                "domain": "schemes",
                "chunk_text": "Small farmers with up to 5 acres receive 70% capital subsidy on micro irrigation.",
                "official_url": "https://tsmip.cgg.gov.in"
            }
        )
        assert resp.status_code == 200
        data = resp.json()["data"]
        assert data["is_verified"] is True
        assert data["domain"] == "schemes"


@pytest.mark.asyncio
async def test_grounded_citation_in_ask_response():
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        resp = await client.post(
            "/v1/ask",
            json={"message": "I see yellow spots and insects on my soybean leaves, what to do?"}
        )
        assert resp.status_code == 200
        data = resp.json()["data"]
        assert len(data["sources"]) >= 1
        # Grounded citations must have official URLs
        assert any(s["url"] is not None for s in data["sources"])
        assert any("pjtsau.edu.in" in s["url"] for s in data["sources"] if s.get("url"))
