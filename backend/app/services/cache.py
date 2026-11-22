"""
VillageNova Semantic Response Cache & Rate Limiter (Phase 3, Week 10)

Provides:
1. Sub-50ms semantic response caching for frequent seasonal and agricultural queries.
2. Sliding-window rate limiting to prevent conversational endpoint abuse and protect API quotas.
"""

from typing import Dict, Any, Optional, Tuple, List
import time
import re
import logging
from fastapi import Request, HTTPException, status

logger = logging.getLogger(__name__)


class CacheEntry:
    def __init__(self, data: Dict[str, Any], ttl_seconds: int = 300):
        self.data = data
        self.cached_at = time.time()
        self.expires_at = self.cached_at + ttl_seconds
        self.hit_count = 0

    @property
    def is_expired(self) -> bool:
        return time.time() > self.expires_at


class SemanticResponseCache:
    """
    In-memory semantic cache for Ask VillageNova queries.
    Normalizes query keywords and matches equivalent user intents
    to deliver sub-50ms responses for common agricultural and market questions.
    """

    def __init__(self, default_ttl: int = 300):
        self.default_ttl = default_ttl
        self._cache: Dict[str, CacheEntry] = {}
        self.hits: int = 0
        self.misses: int = 0

    @staticmethod
    def normalize_key(query: str, context_scope: str = "default") -> str:
        """Normalizes query string for semantic matching."""
        q = query.lower().strip()
        # Remove punctuation
        q = re.sub(r"[^\w\s]", " ", q)
        q = re.sub(r"\s+", " ", q).strip()

        # Semantic canonicalization of frequent rural prompts (specific domains prioritized)
        if any(w in q for w in ("mandi", "rate", "price", "apmc", "market", "ధర")):
            canonical = "intent:mandi_rates"
        elif any(w in q for w in ("leaf", "pest", "yellow", "insect", "doctor", "disease", "పురుగు", "ఆకు")):
            canonical = "intent:crop_health"
        elif any(w in q for w in ("rain", "spray", "weather", "forecast", "cloud", "వర్షం", "వాతావరణం")):
            canonical = "intent:spray_weather"
        elif any(w in q for w in ("scheme", "subsidy", "subsidies", "pm-kisan", "pmkisan", "rythu", "pension", "grant", "పథకం", "సబ్సిడీ")):
            canonical = "intent:schemes_subsidies"
        elif any(w in q for w in ("farm today", "what to do on my farm", "what should i do", "today", "morning")):
            canonical = "intent:farm_today"
        else:
            # Hash tokens sorted
            words = sorted([w for w in q.split() if len(w) > 2])
            canonical = "words:" + "_".join(words[:8])

        return f"{context_scope}:{canonical}"

    def get(self, query: str, context_scope: str = "default") -> Optional[Dict[str, Any]]:
        """Retrieves cached response if valid and unexpired."""
        key = self.normalize_key(query, context_scope)
        entry = self._cache.get(key)
        if entry:
            if not entry.is_expired:
                entry.hit_count += 1
                self.hits += 1
                logger.info(f"Semantic Cache HIT for key: {key} (hits={entry.hit_count})")
                cached_data = dict(entry.data)
                cached_data["cached"] = True
                return cached_data
            else:
                # Remove expired entry
                del self._cache[key]

        self.misses += 1
        return None

    def set(
        self,
        query: str,
        response_payload: Dict[str, Any],
        context_scope: str = "default",
        ttl_seconds: Optional[int] = None
    ) -> None:
        """Caches response payload under normalized key."""
        ttl = ttl_seconds or self.default_ttl
        key = self.normalize_key(query, context_scope)
        self._cache[key] = CacheEntry(data=response_payload, ttl_seconds=ttl)
        logger.info(f"Semantic Cache STORED key: {key} (ttl={ttl}s)")

    def clear(self) -> None:
        """Clears all cached entries and resets statistics."""
        self._cache.clear()
        self.hits = 0
        self.misses = 0

    def get_stats(self) -> Dict[str, Any]:
        """Returns cache telemetry."""
        total_queries = self.hits + self.misses
        hit_ratio = round(self.hits / total_queries, 3) if total_queries > 0 else 0.0
        return {
            "total_entries": len(self._cache),
            "hits": self.hits,
            "misses": self.misses,
            "hit_ratio": hit_ratio,
            "active_keys": list(self._cache.keys())
        }


class RateLimiter:
    """
    Sliding-window request rate limiter per client/user.
    Prevents conversational endpoint exhaustion and guarantees fair access.
    """

    def __init__(self, default_limit: int = 30, window_seconds: int = 60):
        self.default_limit = default_limit
        self.window_seconds = window_seconds
        # client_id -> list of float timestamps
        self._request_history: Dict[str, List[float]] = {}
        self.exempt_clients: set = set()

    def check_rate_limit(
        self,
        client_id: str,
        limit: Optional[int] = None,
        window_seconds: Optional[int] = None
    ) -> Tuple[bool, int]:
        """
        Validates whether client is within request allowance.
        Returns: (is_allowed: bool, retry_after_seconds: int)
        """
        if client_id in self.exempt_clients:
            return True, 0

        max_reqs = limit if limit is not None else self.default_limit
        window = window_seconds if window_seconds is not None else self.window_seconds
        now = time.time()
        window_start = now - window

        # Retrieve and filter timestamps within sliding window
        history = self._request_history.get(client_id, [])
        valid_history = [ts for ts in history if ts > window_start]

        if len(valid_history) >= max_reqs:
            # Exceeded rate limit
            oldest_ts = valid_history[0]
            retry_after = max(1, int(oldest_ts + window - now))
            self._request_history[client_id] = valid_history
            return False, retry_after

        valid_history.append(now)
        self._request_history[client_id] = valid_history
        return True, 0

    def reset(self, client_id: Optional[str] = None) -> None:
        """Resets rate limiter records for one or all clients."""
        if client_id:
            self._request_history.pop(client_id, None)
        else:
            self._request_history.clear()


# Global Singleton Instances
semantic_cache = SemanticResponseCache(default_ttl=300)
rate_limiter = RateLimiter(default_limit=30, window_seconds=60)


async def check_ask_rate_limit(request: Request) -> None:
    """
    FastAPI dependency enforcing rate limits for /ask endpoints.
    Uses authenticated user ID or client host IP.
    """
    # Check if testing flag is set
    import os
    if os.getenv("DISABLE_RATE_LIMIT", "").lower() in ("true", "1"):
        return

    # Extract client identifier
    auth_header = request.headers.get("Authorization", "")
    client_ip = request.client.host if request.client else "127.0.0.1"
    client_id = auth_header if auth_header else client_ip

    allowed, retry_after = rate_limiter.check_rate_limit(client_id)
    if not allowed:
        logger.warning(f"Rate limit exceeded for client: {client_id}. Retry-After: {retry_after}s")
        raise HTTPException(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            detail=f"Rate limit exceeded. Please wait {retry_after} seconds before sending another query.",
            headers={"Retry-After": str(retry_after)}
        )
