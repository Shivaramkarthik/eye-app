from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from app.database.session import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.models.profile import Profile
from app.models.score import EyeCareScore
from app.schemas.score import EyeCareScoreOut

router = APIRouter()

@router.get("/profiles/{profile_id}/score", response_model=Optional[EyeCareScoreOut])
async def get_latest_score(
    profile_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Fetches the latest Vision Care Score for a profile."""
    p_stmt = select(Profile).where(Profile.id == profile_id, Profile.user_id == current_user.id, Profile.deleted_at.is_(None))
    p_res = await db.execute(p_stmt)
    if not p_res.scalar_one_or_none():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Profile not found or access denied.")

    stmt = select(EyeCareScore).where(EyeCareScore.profile_id == profile_id).order_by(EyeCareScore.calculated_at.desc())
    res = await db.execute(stmt)
    score = res.scalar_one_or_none()
    return score
