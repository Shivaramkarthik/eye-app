import os
import uuid
from datetime import datetime, timezone
from typing import List, Dict, Any
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from app.database.session import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.models.profile import Profile
from app.models.report import Report
from app.schemas.report import ReportCreate, ReportOut
from app.services.storage_service import StorageService

router = APIRouter()

@router.get("/profiles/{profile_id}/reports", response_model=List[ReportOut])
async def list_reports(
    profile_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Lists reports for a profile with strict ownership verification."""
    p_stmt = select(Profile).where(Profile.id == profile_id, Profile.user_id == current_user.id, Profile.deleted_at.is_(None))
    p_res = await db.execute(p_stmt)
    if not p_res.scalar_one_or_none():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Profile not found or access denied.")

    stmt = select(Report).where(Report.profile_id == profile_id, Report.user_id == current_user.id).order_by(Report.created_at.desc())
    res = await db.execute(stmt)
    return res.scalars().all()

@router.post("/reports", response_model=ReportOut, status_code=status.HTTP_201_CREATED)
async def create_report(
    req: ReportCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Saves PDF report metadata to cloud."""
    p_stmt = select(Profile).where(Profile.id == req.profile_id, Profile.user_id == current_user.id, Profile.deleted_at.is_(None))
    p_res = await db.execute(p_stmt)
    if not p_res.scalar_one_or_none():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Profile not found or access denied.")

    rid = f"rpt_{int(datetime.now().timestamp() * 1000)}"
    report = Report(
        id=rid,
        profile_id=req.profile_id,
        user_id=current_user.id,
        report_date=req.report_date,
        title=req.title,
        clinic_name=req.clinic_name,
        file_path=req.file_path,
        notes=req.notes,
        follow_up_date=req.follow_up_date,
        score_snapshot=req.score_snapshot,
        score_explanation_snapshot=req.score_explanation_snapshot,
        ai_summary_snapshot=req.ai_summary_snapshot,
        doctor_questions_snapshot=req.doctor_questions_snapshot,
        created_at=datetime.now(timezone.utc)
    )
    db.add(report)
    await db.commit()
    await db.refresh(report)
    return report

@router.get("/reports/upload-url")
async def get_presigned_upload_url(
    filename: str,
    current_user: User = Depends(get_current_user)
) -> Dict[str, Any]:
    """Returns a pre-signed S3 upload URL for private medical document backup."""
    safe_filename = os.path.basename(filename)
    object_name = f"users/{current_user.id}/reports/{uuid.uuid4().hex}_{safe_filename}"
    return StorageService.generate_presigned_upload_url(object_name)
