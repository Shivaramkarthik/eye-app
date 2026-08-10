from typing import Dict, Any, Optional
from pydantic import BaseModel
from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.database.session import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.services.analytics_service import AnalyticsService

router = APIRouter()

class AnalyticsEventRequest(BaseModel):
    event_type: str
    device_id: Optional[str] = None
    properties: Optional[Dict[str, Any]] = None

@router.post("/events")
async def record_analytics_event(
    req: AnalyticsEventRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Records privacy-safe analytics events without medical payload or secrets."""
    await AnalyticsService.log_event(
        db,
        event_type=req.event_type,
        user_id=current_user.id,
        device_id=req.device_id,
        properties=req.properties
    )
    return {"status": "recorded"}
