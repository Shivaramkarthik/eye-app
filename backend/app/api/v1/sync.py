from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from app.database.session import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.schemas.sync import SyncPushRequest, SyncPushResponse, SyncPullResponse
from app.services.sync_service import SyncService

router = APIRouter()

@router.post("/push", response_model=SyncPushResponse)
async def push_sync_queue(
    req: SyncPushRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Processes enqueued offline client operations idempotently."""
    return await SyncService.process_push(db, current_user, req)

@router.get("/pull", response_model=SyncPullResponse)
async def pull_sync_state(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Pulls full cloud user state down to local device."""
    return await SyncService.process_pull(db, current_user)
