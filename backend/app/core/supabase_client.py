from typing import Optional
from supabase import create_client, Client
from app.core.config import settings
import logging

logger = logging.getLogger(__name__)

_client: Optional[Client] = None


def get_supabase_client() -> Optional[Client]:
    """
    Returns an authenticated Supabase client using project credentials.
    Prefers the service role key for backend operations when available.
    """
    global _client
    if _client is not None:
        return _client

    key = settings.SUPABASE_SERVICE_ROLE_KEY or settings.SUPABASE_ANON_KEY or settings.SUPABASE_KEY
    try:
        _client = create_client(settings.SUPABASE_URL, key)
        return _client
    except Exception as e:
        logger.warning(f"Supabase client could not be initialized: {e}")
        return None


# Global client instance (safely initialized)
try:
    supabase: Optional[Client] = get_supabase_client()
except Exception:
    supabase = None
