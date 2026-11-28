import pytest
from app.core import supabase_client
from app.core.config import settings
from app.core.supabase_client import get_supabase_client

_TEST_DUMMY_JWT = (
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9."
    "eyJpc3MiOiJzdXBhYmFzZSIsInJvbGUiOiJhbm9uIn0."
    "offline-ci-test-signature"
)


def _looks_like_jwt(value: str | None) -> bool:
    return bool(value and value.count(".") == 2)


def test_supabase_client_instantiation(monkeypatch: pytest.MonkeyPatch):
    """
    Verifies that the Supabase client initializes with configured project URL.
    Falls back to a syntactically valid test JWT in CI environments without .env.
    """
    prev_client = supabase_client._client
    monkeypatch.setattr(supabase_client, "_client", None)

    has_real_key = any(
        _looks_like_jwt(k)
        for k in (
            settings.SUPABASE_SERVICE_ROLE_KEY,
            settings.SUPABASE_ANON_KEY,
            settings.SUPABASE_KEY,
        )
    )
    if not has_real_key:
        monkeypatch.setattr(settings, "SUPABASE_SERVICE_ROLE_KEY", None)
        monkeypatch.setattr(settings, "SUPABASE_ANON_KEY", None)
        monkeypatch.setattr(settings, "SUPABASE_KEY", _TEST_DUMMY_JWT)

    try:
        client = get_supabase_client()
        assert client is not None
        assert "supabase.co" in settings.SUPABASE_URL
    finally:
        supabase_client._client = prev_client
