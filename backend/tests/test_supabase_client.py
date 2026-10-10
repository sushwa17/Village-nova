from app.core.supabase_client import get_supabase_client
from app.core.config import settings


def test_supabase_client_instantiation():
    """
    Verifies that the Supabase client initializes with configured project URL.
    """
    client = get_supabase_client()
    assert client is not None
    assert "supabase.co" in settings.SUPABASE_URL
