from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
import redis.asyncio as aioredis

from app.database.session import get_db
from app.core.config import settings

router = APIRouter()


@router.get("/health")
async def health_check():
    """Liveness probe: verifies process is alive."""
    return {
        "status": "ok",
        "service": "specz-api",
        "version": "2.0.0"
    }


@router.get("/health/ready")
async def readiness_check(db: AsyncSession = Depends(get_db)):
    """Readiness probe: verifies database and cache connectivity before accepting traffic."""
    dependencies = {}
    is_ready = True

    # 1. Database Check
    try:
        await db.execute(text("SELECT 1"))
        dependencies["database"] = "ok"
    except Exception as e:
        dependencies["database"] = f"unhealthy: {str(e)}"
        is_ready = False

    # 2. Redis Check (Optional in dev, required in prod/staging)
    if settings.ENVIRONMENT != "development":
        try:
            r = aioredis.from_url(settings.REDIS_URL, socket_timeout=2)
            await r.ping()
            await r.aclose()
            dependencies["redis"] = "ok"
        except Exception as e:
            dependencies["redis"] = f"unhealthy: {str(e)}"
            # Don't fail completely if in staging unless required
    else:
        dependencies["redis"] = "skipped (development)"

    return {
        "status": "ok" if is_ready else "degraded",
        "service": "specz-api",
        "version": "2.0.0",
        "dependencies": dependencies
    }
