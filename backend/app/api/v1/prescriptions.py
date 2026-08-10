from datetime import datetime, timezone
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from app.database.session import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.models.profile import Profile
from app.models.prescription import Prescription, PrescriptionEyeValue
from app.schemas.prescription import PrescriptionCreate, PrescriptionOut, EyeValueSchema

router = APIRouter()

@router.get("/profiles/{profile_id}/prescriptions", response_model=List[PrescriptionOut])
async def list_prescriptions(
    profile_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Lists prescriptions for a profile with strict IDOR multi-tenant check."""
    # Verify profile ownership
    p_stmt = select(Profile).where(Profile.id == profile_id, Profile.user_id == current_user.id, Profile.deleted_at.is_(None))
    p_res = await db.execute(p_stmt)
    if not p_res.scalar_one_or_none():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Profile not found or access denied.")

    stmt = select(Prescription).where(Prescription.profile_id == profile_id, Prescription.user_id == current_user.id).order_by(Prescription.created_at.desc())
    res = await db.execute(stmt)
    prescriptions = res.scalars().all()

    out: List[PrescriptionOut] = []
    for p in prescriptions:
        ev_stmt = select(PrescriptionEyeValue).where(PrescriptionEyeValue.prescription_id == p.id)
        ev_res = await db.execute(ev_stmt)
        ev_list = ev_res.scalars().all()

        eye_values = [
            EyeValueSchema(
                eye=ev.eye,
                sph=ev.sph,
                cyl=ev.cyl,
                axis=ev.axis,
                sph_status=ev.sph_status,
                cyl_status=ev.cyl_status,
                axis_status=ev.axis_status
            )
            for ev in ev_list
        ]

        out.append(PrescriptionOut(
            id=p.id,
            profile_id=p.profile_id,
            user_id=p.user_id,
            prescription_date=p.prescription_date,
            doctor_name=p.doctor_name,
            clinic_name=p.clinic_name,
            add_power=p.add_power,
            pd=p.pd,
            notes=p.notes,
            image_url=p.image_url,
            source=p.source,
            ocr_confidence=p.ocr_confidence,
            confirmed_by_user=p.confirmed_by_user,
            is_current=p.is_current,
            eye_values=eye_values,
            created_at=p.created_at,
            updated_at=p.updated_at
        ))
    return out

@router.post("/profiles/{profile_id}/prescriptions", response_model=PrescriptionOut, status_code=status.HTTP_201_CREATED)
async def create_prescription(
    profile_id: str,
    req: PrescriptionCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Creates a confirmed prescription record with normalized eye values."""
    p_stmt = select(Profile).where(Profile.id == profile_id, Profile.user_id == current_user.id, Profile.deleted_at.is_(None))
    p_res = await db.execute(p_stmt)
    if not p_res.scalar_one_or_none():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Profile not found or access denied.")

    pid = f"presc_{int(datetime.now().timestamp() * 1000)}"
    presc = Prescription(
        id=pid,
        profile_id=profile_id,
        user_id=current_user.id,
        prescription_date=req.prescription_date,
        doctor_name=req.doctor_name,
        clinic_name=req.clinic_name,
        add_power=req.add_power,
        pd=req.pd,
        notes=req.notes,
        image_url=req.image_url,
        source=req.source,
        ocr_confidence=req.ocr_confidence,
        confirmed_by_user=req.confirmed_by_user,
        is_current=req.is_current,
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc)
    )
    db.add(presc)
    await db.flush()

    for ev in req.eye_values:
        db.add(PrescriptionEyeValue(
            id=f"{pid}_{ev.eye}",
            prescription_id=pid,
            eye=ev.eye,
            sph=ev.sph,
            cyl=ev.cyl,
            axis=ev.axis,
            sph_status=ev.sph_status,
            cyl_status=ev.cyl_status,
            axis_status=ev.axis_status,
            created_at=datetime.now(timezone.utc)
        ))

    await db.commit()
    await db.refresh(presc)

    return PrescriptionOut(
        id=presc.id,
        profile_id=presc.profile_id,
        user_id=presc.user_id,
        prescription_date=presc.prescription_date,
        doctor_name=presc.doctor_name,
        clinic_name=presc.clinic_name,
        add_power=presc.add_power,
        pd=presc.pd,
        notes=presc.notes,
        image_url=presc.image_url,
        source=presc.source,
        ocr_confidence=presc.ocr_confidence,
        confirmed_by_user=presc.confirmed_by_user,
        is_current=presc.is_current,
        eye_values=req.eye_values,
        created_at=presc.created_at,
        updated_at=presc.updated_at
    )

@router.delete("/prescriptions/{id}")
async def delete_prescription(
    id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Deletes a prescription with strict IDOR verification."""
    stmt = select(Prescription).where(Prescription.id == id, Prescription.user_id == current_user.id)
    res = await db.execute(stmt)
    presc = res.scalar_one_or_none()
    if not presc:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Prescription not found or access denied.")

    await db.delete(presc)
    await db.commit()
    return {"message": "Prescription successfully deleted."}
