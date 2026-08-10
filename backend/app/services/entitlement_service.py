from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from sqlalchemy import func
from fastapi import HTTPException, status

from app.models.user import User
from app.models.profile import Profile
from app.schemas.subscription import EntitlementOut

PLAN_PROFILE_LIMITS = {
    "free": 1,
    "plus": 5,
    "admin": 20
}

class EntitlementService:
    @staticmethod
    async def get_user_entitlement(db: AsyncSession, user: User) -> EntitlementOut:
        """Calculates server-authoritative entitlements for user."""
        max_profiles = PLAN_PROFILE_LIMITS.get(user.plan.lower(), 1)
        features = {
            "ai_summary": user.plan.lower() == "plus",
            "cloud_reports": True,
            "ocr_unlimited": user.plan.lower() == "plus",
            "family_sharing": user.plan.lower() == "plus",
        }
        return EntitlementOut(
            user_id=user.id,
            plan=user.plan,
            status=user.account_status,
            max_profiles=max_profiles,
            features=features,
            expires_at=None
        )

    @staticmethod
    async def check_profile_limit(db: AsyncSession, user: User):
        """Verifies if the user is allowed to create another profile under their active subscription tier."""
        stmt = select(func.count(Profile.id)).where(
            Profile.user_id == user.id,
            Profile.deleted_at.is_(None),
            Profile.archived == 0
        )
        res = await db.execute(stmt)
        active_count = res.scalar() or 0
        
        limit = PLAN_PROFILE_LIMITS.get(user.plan.lower(), 1)
        if active_count >= limit:
            raise HTTPException(
                status_code=status.HTTP_402_PAYMENT_REQUIRED,
                detail=f"Profile limit reached ({active_count}/{limit}) for {user.plan.capitalize()} plan. Upgrade to Plus for up to 5 profiles."
            )
