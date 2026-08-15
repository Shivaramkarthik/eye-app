from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from app.database.session import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.models.profile import Profile
from app.models.score import EyeCareScore
from app.schemas.ai import (
    OCRRequest,
    OCRResponse,
    AIQuestionsRequest,
    AIQuestionsResponse,
    AISummaryRequest,
    AISummaryResponse,
)
from app.core.rate_limiter import limiter
from app.services.ocr_service import OCRService
from app.services.ai_service import AIService
from starlette.requests import Request

router = APIRouter()

@router.post("/ocr-prescription", response_model=OCRResponse)
@limiter.limit("10/minute")
async def extract_ocr_prescription(
    req: OCRRequest,
    request: Request,
    current_user: User = Depends(get_current_user)
):
    """Extracts optical prescription parameters from image. (User confirmation in Flutter is mandatory)."""
    return await OCRService.extract_prescription(
        image_base64=req.image_base64,
        image_url=req.image_url
    )

@router.post("/doctor-questions", response_model=AIQuestionsResponse)
async def generate_doctor_questions(
    req: AIQuestionsRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Generates non-diagnostic clinical questions for doctor appointments."""
    p_stmt = select(Profile).where(Profile.id == req.profile_id, Profile.user_id == current_user.id, Profile.deleted_at.is_(None))
    p_res = await db.execute(p_stmt)
    if not p_res.scalar_one_or_none():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Profile not found or access denied.")

    return await AIService.generate_doctor_questions(
        symptoms=req.symptoms,
        prescription_summary=req.prescription_summary,
        language=req.language
    )

@router.post("/summary", response_model=AISummaryResponse)
async def generate_ai_summary(
    req: AISummaryRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Generates a non-diagnostic eye care overview summary."""
    p_stmt = select(Profile).where(Profile.id == req.profile_id, Profile.user_id == current_user.id, Profile.deleted_at.is_(None))
    p_res = await db.execute(p_stmt)
    profile = p_res.scalar_one_or_none()
    if not profile:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Profile not found or access denied.")

    s_stmt = select(EyeCareScore.score).where(EyeCareScore.profile_id == req.profile_id).order_by(EyeCareScore.calculated_at.desc())
    s_res = await db.execute(s_stmt)
    score = s_res.scalar() or 85

    return await AIService.generate_summary(
        profile_name=profile.name,
        score=score
    )
