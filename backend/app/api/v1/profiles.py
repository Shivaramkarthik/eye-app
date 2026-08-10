import uuid
from datetime import datetime, timezone
from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from app.database.session import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.models.profile import Profile, ProfileSymptom
from app.schemas.profile import ProfileCreate, ProfileUpdate, ProfileOut
from app.services.entitlement_service import EntitlementService

router = APIRouter()

@router.get("", response_model=List[ProfileOut])
async def list_profiles(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Lists profiles belonging strictly to the authenticated user."""
    stmt = select(Profile).where(Profile.user_id == current_user.id, Profile.deleted_at.is_(None))
    res = await db.execute(stmt)
    profiles = res.scalars().all()
    
    out: List[ProfileOut] = []
    for p in profiles:
        s_stmt = select(ProfileSymptom.symptom).where(ProfileSymptom.profile_id == p.id)
        s_res = await db.execute(s_stmt)
        symptoms = s_res.scalars().all()
        
        p_dict = {
            "id": p.id,
            "user_id": p.user_id,
            "name": p.name,
            "dob": p.dob,
            "gender": p.gender,
            "relationship": p.relationship_type,
            "profile_type": p.profile_type,
            "prescription_type": p.prescription_type,
            "blurred_vision_type": p.blurred_vision_type,
            "symptoms": symptoms,
            "archived": p.archived,
            "created_at": p.created_at,
            "updated_at": p.updated_at,
        }
        out.append(ProfileOut(**p_dict))
    return out

@router.post("", response_model=ProfileOut, status_code=status.HTTP_201_CREATED)
async def create_profile(
    req: ProfileCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Creates a new family profile after checking subscription entitlement limits."""
    # Server-Authoritative Entitlement Verification
    await EntitlementService.check_profile_limit(db, current_user)

    pid = f"profile_{int(datetime.now().timestamp() * 1000)}"
    profile = Profile(
        id=pid,
        user_id=current_user.id,
        name=req.name,
        dob=req.dob,
        gender=req.gender,
        relationship_type=req.relationship,
        profile_type=req.profile_type,
        prescription_type=req.prescription_type,
        blurred_vision_type=req.blurred_vision_type,
        archived=0,
        created_at=datetime.now(timezone.utc),
        updated_at=datetime.now(timezone.utc)
    )
    db.add(profile)
    await db.flush()

    # Add symptoms
    for sym in req.symptoms:
        db.add(ProfileSymptom(
            id=f"{pid}_{hash(sym)}",
            profile_id=pid,
            symptom=sym,
            created_at=datetime.now(timezone.utc)
        ))
        
    await db.commit()
    await db.refresh(profile)

    return ProfileOut(
        id=profile.id,
        user_id=profile.user_id,
        name=profile.name,
        dob=profile.dob,
        gender=profile.gender,
        relationship=profile.relationship_type,
        profile_type=profile.profile_type,
        prescription_type=profile.prescription_type,
        blurred_vision_type=profile.blurred_vision_type,
        symptoms=req.symptoms,
        archived=profile.archived,
        created_at=profile.created_at,
        updated_at=profile.updated_at
    )

@router.get("/{profile_id}", response_model=ProfileOut)
async def get_profile(
    profile_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Fetches a profile with strict multi-tenant IDOR protection."""
    stmt = select(Profile).where(Profile.id == profile_id, Profile.user_id == current_user.id, Profile.deleted_at.is_(None))
    res = await db.execute(stmt)
    profile = res.scalar_one_or_none()
    if not profile:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Profile not found or access denied.")

    s_stmt = select(ProfileSymptom.symptom).where(ProfileSymptom.profile_id == profile.id)
    s_res = await db.execute(s_stmt)
    symptoms = s_res.scalars().all()

    return ProfileOut(
        id=profile.id,
        user_id=profile.user_id,
        name=profile.name,
        dob=profile.dob,
        gender=profile.gender,
        relationship=profile.relationship_type,
        profile_type=profile.profile_type,
        prescription_type=profile.prescription_type,
        blurred_vision_type=profile.blurred_vision_type,
        symptoms=symptoms,
        archived=profile.archived,
        created_at=profile.created_at,
        updated_at=profile.updated_at
    )

@router.patch("/{profile_id}", response_model=ProfileOut)
async def update_profile(
    profile_id: str,
    req: ProfileUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Updates a profile with strict IDOR ownership checks."""
    stmt = select(Profile).where(Profile.id == profile_id, Profile.user_id == current_user.id, Profile.deleted_at.is_(None))
    res = await db.execute(stmt)
    profile = res.scalar_one_or_none()
    if not profile:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Profile not found or access denied.")

    if req.name is not None:
        profile.name = req.name
    if req.dob is not None:
        profile.dob = req.dob
    if req.gender is not None:
        profile.gender = req.gender
    if req.relationship is not None:
        profile.relationship_type = req.relationship
    if req.profile_type is not None:
        profile.profile_type = req.profile_type
    if req.prescription_type is not None:
        profile.prescription_type = req.prescription_type
    if req.blurred_vision_type is not None:
        profile.blurred_vision_type = req.blurred_vision_type
    if req.archived is not None:
        profile.archived = req.archived

    profile.updated_at = datetime.now(timezone.utc)
    await db.commit()
    await db.refresh(profile)

    s_stmt = select(ProfileSymptom.symptom).where(ProfileSymptom.profile_id == profile.id)
    s_res = await db.execute(s_stmt)
    symptoms = s_res.scalars().all()

    return ProfileOut(
        id=profile.id,
        user_id=profile.user_id,
        name=profile.name,
        dob=profile.dob,
        gender=profile.gender,
        relationship=profile.relationship_type,
        profile_type=profile.profile_type,
        prescription_type=profile.prescription_type,
        blurred_vision_type=profile.blurred_vision_type,
        symptoms=symptoms,
        archived=profile.archived,
        created_at=profile.created_at,
        updated_at=profile.updated_at
    )

@router.delete("/{profile_id}")
async def delete_profile(
    profile_id: str,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Soft deletes profile record."""
    stmt = select(Profile).where(Profile.id == profile_id, Profile.user_id == current_user.id, Profile.deleted_at.is_(None))
    res = await db.execute(stmt)
    profile = res.scalar_one_or_none()
    if not profile:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Profile not found or access denied.")

    profile.deleted_at = datetime.now(timezone.utc)
    await db.commit()
    return {"message": "Profile successfully deleted."}
