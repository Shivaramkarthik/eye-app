from datetime import datetime, timezone
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from app.database.session import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.models.profile import Profile
from app.models.medication import Medication, MedicationSchedule, MedicationLog
from app.schemas.medication import MedicationCreate, MedicationOut, ScheduleSchema, LogSchema

router = APIRouter()

@router.get("/profiles/{profile_id}/medications", response_model=List[MedicationOut])
async def list_medications(
    profile_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Lists medications and schedules for a profile with strict ownership verification."""
    p_stmt = select(Profile).where(Profile.id == profile_id, Profile.user_id == current_user.id, Profile.deleted_at.is_(None))
    p_res = await db.execute(p_stmt)
    if not p_res.scalar_one_or_none():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Profile not found or access denied.")

    stmt = select(Medication).where(Medication.profile_id == profile_id, Medication.user_id == current_user.id)
    res = await db.execute(stmt)
    meds = res.scalars().all()

    out: List[MedicationOut] = []
    for m in meds:
        s_stmt = select(MedicationSchedule).where(MedicationSchedule.medication_id == m.id)
        s_res = await db.execute(s_stmt)
        schedules_db = s_res.scalars().all()
        schedules = [
            ScheduleSchema(id=s.id, time=s.time, tone=s.tone, vibration_enabled=s.vibration_enabled, enabled=s.enabled)
            for s in schedules_db
        ]

        l_stmt = select(MedicationLog.scheduled_at).where(MedicationLog.medication_id == m.id, MedicationLog.status == "TAKEN")
        l_res = await db.execute(l_stmt)
        completed_logs = l_res.scalars().all()

        out.append(MedicationOut(
            id=m.id,
            profile_id=m.profile_id,
            user_id=m.user_id,
            name=m.name,
            type=m.type,
            dosage=m.dosage,
            start_date=m.start_date,
            end_date=m.end_date,
            active=m.active,
            schedules=schedules,
            completed_logs=completed_logs,
            created_at=m.created_at,
            updated_at=m.updated_at
        ))
    return out

@router.post("/profiles/{profile_id}/medications", response_model=MedicationOut, status_code=status.HTTP_201_CREATED)
async def create_medication(
    profile_id: str,
    req: MedicationCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Creates a new eye drop medication and associated schedules."""
    p_stmt = select(Profile).where(Profile.id == profile_id, Profile.user_id == current_user.id, Profile.deleted_at.is_(None))
    p_res = await db.execute(p_stmt)
    if not p_res.scalar_one_or_none():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Profile not found or access denied.")

    mid = f"med_{int(datetime.now().timestamp() * 1000)}"
    med = Medication(
        id=mid,
        profile_id=profile_id,
        user_id=current_user.id,
        name=req.name,
        type=req.type,
        dosage=req.dosage,
        start_date=req.start_date,
        end_date=req.end_date,
        active=req.active,
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc)
    )
    db.add(med)
    await db.flush()

    schedules_out: List[ScheduleSchema] = []
    for idx, s in enumerate(req.schedules):
        sid = f"{mid}_sched_{idx}"
        db.add(MedicationSchedule(
            id=sid,
            medication_id=mid,
            time=s.time,
            tone=s.tone,
            vibration_enabled=s.vibration_enabled,
            enabled=s.enabled,
            created_at=datetime.now(timezone.utc),
            updated_at=datetime.now(timezone.utc)
        ))
        schedules_out.append(ScheduleSchema(id=sid, time=s.time, tone=s.tone, vibration_enabled=s.vibration_enabled, enabled=s.enabled))

    await db.commit()
    await db.refresh(med)

    return MedicationOut(
        id=med.id,
        profile_id=med.profile_id,
        user_id=med.user_id,
        name=med.name,
        type=med.type,
        dosage=med.dosage,
        start_date=med.start_date,
        end_date=med.end_date,
        active=med.active,
        schedules=schedules_out,
        completed_logs=[],
        created_at=med.created_at,
        updated_at=med.updated_at
    )

@router.delete("/medications/{id}")
async def delete_medication(
    id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Deletes a medication and linked schedules/logs with strict IDOR verification."""
    stmt = select(Medication).where(Medication.id == id, Medication.user_id == current_user.id)
    res = await db.execute(stmt)
    med = res.scalar_one_or_none()
    if not med:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Medication not found or access denied.")

    await db.delete(med)
    await db.commit()
    return {"message": "Medication successfully deleted."}
