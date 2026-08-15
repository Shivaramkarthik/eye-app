import os
import logging
from slowapi import Limiter
from slowapi.util import get_remote_address
from starlette.requests import Request
from app.core.config import settings

logger = logging.getLogger("specz_rate_limiter")


def get_client_identifier(request: Request) -> str:
    """Extracts client IP or authorization header token subject for per-user rate limiting."""
    # Check if user is authenticated
    auth_header = request.headers.get("Authorization")
    if auth_header and auth_header.startswith("Bearer "):
        # Use first 16 chars of token as unique user bucket
        return f"user_{auth_header[7:23]}"
    
    # Fallback to client IP
    return get_remote_address(request)


is_test_env = os.getenv("ENVIRONMENT") == "testing" or os.getenv("TESTING") == "1"

# Initialize Limiter with Redis storage or in-memory fallback
try:
    limiter = Limiter(
        key_func=get_client_identifier,
        default_limits=["300/minute"],
        storage_uri=settings.REDIS_URL if settings.ENVIRONMENT not in ("development", "testing") else "memory://",
        enabled=not is_test_env,
    )
except Exception as e:
    logger.warning(f"Could not connect to Redis for rate limiting, falling back to memory: {e}")
    limiter = Limiter(
        key_func=get_client_identifier,
        default_limits=["300/minute"],
        storage_uri="memory://",
        enabled=not is_test_env,
    )
