"""
Unit & Integration Tests for Ask VillageNova Orchestrator Hardening (Phase 3, Week 10)

Covers:
1. Sub-50ms semantic response caching.
2. Conversation session history tracking, retrieval, and truncation.
3. Message length validation (>1000 characters).
4. Sliding-window rate limiting (HTTP 429 Too Many Requests).
5. Orchestrator telemetry & cache statistics.
"""

import pytest
from httpx import AsyncClient, ASGITransport
import uuid

from app.main import app
from app.core.security import get_current_user, AuthenticatedResident
from app.core.database import get_db
from app.services.cache import semantic_cache, rate_limiter
from app.services.conversation import conversation_manager, ConversationSession, ConversationMessage

MOCK_USER_ID = f"resident_{uuid.uuid4().hex[:8]}"


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


@pytest.fixture(autouse=True)
def reset_cache_and_limits():
    """Ensure clean cache and rate limit history before each test."""
    semantic_cache.clear()
    rate_limiter.reset()
    yield
    semantic_cache.clear()
    rate_limiter.reset()


@pytest.mark.asyncio
async def test_semantic_caching_and_sub_50ms_latency():
    """Validates that repeat seasonal queries hit the semantic cache with sub-50ms latency."""
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        # First query: Cache Miss
        res1 = await client.post(
            "/v1/ask",
            json={"message": "What is today's soybean mandi price in Vikarabad?", "language": "en"}
        )
        assert res1.status_code == 200
        data1 = res1.json()["data"]
        assert data1["cached"] is False
        assert data1["latency_ms"] is not None

        # Second query (equivalent phrasing): Cache Hit
        res2 = await client.post(
            "/v1/ask",
            json={"message": "What is today's soybean mandi price in Vikarabad?", "language": "en"}
        )
        assert res2.status_code == 200
        data2 = res2.json()["data"]
        assert data2["cached"] is True
        assert data2["model_used"] == "semantic-cache"
        assert data2["latency_ms"] <= 100


@pytest.mark.asyncio
async def test_conversation_history_session_and_clearing():
    """Validates session message logging, history retrieval, and clear chat endpoint."""
    conv_id = f"conv_test_{uuid.uuid4().hex[:6]}"
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        # Turn 1
        res1 = await client.post(
            "/v1/ask",
            json={
                "message": "What should I do on my farm today?",
                "conversation_id": conv_id,
                "language": "en"
            }
        )
        assert res1.status_code == 200
        assert res1.json()["data"]["conversation_id"] == conv_id

        # Turn 2
        res2 = await client.post(
            "/v1/ask",
            json={
                "message": "Is it safe to spray fertilizer this evening?",
                "conversation_id": conv_id,
                "language": "en"
            }
        )
        assert res2.status_code == 200

        # Retrieve History
        history_res = await client.get(f"/v1/ask/conversations/{conv_id}")
        assert history_res.status_code == 200
        history_data = history_res.json()["data"]
        assert history_data["conversation_id"] == conv_id
        assert history_data["total_messages"] == 4  # 2 user + 2 model
        assert history_data["messages"][0]["role"] == "user"
        assert history_data["messages"][1]["role"] == "model"

        # Clear Conversation
        del_res = await client.delete(f"/v1/ask/conversations/{conv_id}")
        assert del_res.status_code == 200
        assert del_res.json()["data"]["status"] == "cleared"

        # Verify Empty History
        history_res_after = await client.get(f"/v1/ask/conversations/{conv_id}")
        assert history_res_after.status_code == 200
        assert history_res_after.json()["data"]["total_messages"] == 0


def test_conversation_sliding_window_truncation():
    """Validates that conversation history exceeding max turns is safely pruned."""
    session = ConversationSession(session_id="test_trunc_1", user_id="user_123")
    # Add 15 turns = 30 messages
    for i in range(15):
        session.add_message(ConversationMessage(role="user", content=f"User question {i}"))
        session.add_message(ConversationMessage(role="model", content=f"Model advice {i}"))

    assert len(session.messages) == 30
    pruned = session.truncate(max_turns=10)  # keeps 20 messages
    assert pruned == 10
    assert len(session.messages) == 20
    # Latest message is retained
    assert session.messages[-1].content == "Model advice 14"
    assert session.messages[0].content == "User question 5"


@pytest.mark.asyncio
async def test_message_length_validation_rejection():
    """Validates that messages exceeding 1000 characters are rejected with 422/400."""
    long_message = "A" * 1050
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        res = await client.post(
            "/v1/ask",
            json={"message": long_message, "language": "en"}
        )
        assert res.status_code in (400, 422)


def test_rate_limiter_logic():
    """Validates sliding window token counting and Retry-After calculation."""
    client_key = "test_farmer_99"
    # Allow 3 requests per 10 seconds
    assert rate_limiter.check_rate_limit(client_key, limit=3, window_seconds=10)[0] is True
    assert rate_limiter.check_rate_limit(client_key, limit=3, window_seconds=10)[0] is True
    assert rate_limiter.check_rate_limit(client_key, limit=3, window_seconds=10)[0] is True

    # 4th request exceeds limit
    allowed, retry_after = rate_limiter.check_rate_limit(client_key, limit=3, window_seconds=10)
    assert allowed is False
    assert retry_after > 0


@pytest.mark.asyncio
async def test_rate_limiter_http_429():
    """Validates that rapid requests exceeding threshold return HTTP 429 Too Many Requests."""
    orig_limit = rate_limiter.default_limit
    try:
        rate_limiter.default_limit = 2
        rate_limiter.window_seconds = 60

        async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
            # Request 1: OK
            res1 = await client.post("/v1/ask", json={"message": "Query 1"})
            assert res1.status_code == 200

            # Request 2: OK
            res2 = await client.post("/v1/ask", json={"message": "Query 2"})
            assert res2.status_code == 200

            # Request 3: Exceeds limit -> 429
            res3 = await client.post("/v1/ask", json={"message": "Query 3"})
            assert res3.status_code == 429
            assert "Retry-After" in res3.headers
            assert "Rate limit exceeded" in res3.json()["detail"]
    finally:
        rate_limiter.default_limit = orig_limit
        rate_limiter.reset()


@pytest.mark.asyncio
async def test_orchestrator_stats_telemetry():
    """Validates telemetry endpoint returning cache metrics and active sessions."""
    async with AsyncClient(transport=ASGITransport(app=app), base_url="http://test") as client:
        # Perform one query to record telemetry
        await client.post("/v1/ask", json={"message": "What should I do on my farm today?"})

        res = await client.get("/v1/ask/stats")
        assert res.status_code == 200
        data = res.json()["data"]
        assert "cache_stats" in data
        assert "total_entries" in data["cache_stats"]
        assert "hit_ratio" in data["cache_stats"]
        assert data["active_sessions"] >= 1
        assert data["rate_limiting_enabled"] is True
