from typing import List
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from app.database.session import get_db
from app.api.deps import get_current_user
from app.models.user import User
from app.models.subscription import Subscription
from app.schemas.subscription import (
    RazorpayOrderCreate,
    RazorpayOrderResponse,
    PaymentVerifyRequest,
    EntitlementOut,
    SubscriptionOut,
)
from app.services.payment_service import PaymentService
from app.services.entitlement_service import EntitlementService

router = APIRouter()

@router.post("/create-order", response_model=RazorpayOrderResponse)
async def create_order(
    req: RazorpayOrderCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Creates a Razorpay order on backend server."""
    return await PaymentService.create_subscription_order(db, current_user, plan=req.plan)

@router.post("/verify-payment", response_model=SubscriptionOut)
async def verify_payment(
    req: PaymentVerifyRequest,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Verifies Razorpay HMAC signature and activates Plus entitlement."""
    return await PaymentService.verify_payment(
        db,
        user=current_user,
        order_id=req.razorpay_order_id,
        payment_id=req.razorpay_payment_id,
        signature=req.razorpay_signature,
        plan=req.plan
    )

@router.get("/me", response_model=List[SubscriptionOut])
async def get_subscriptions(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Fetches user subscription history."""
    stmt = select(Subscription).where(Subscription.user_id == current_user.id).order_by(Subscription.created_at.desc())
    res = await db.execute(stmt)
    return res.scalars().all()

@router.get("/entitlements/me", response_model=EntitlementOut)
async def get_entitlements(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    """Returns server-authoritative entitlements and profile limits."""
    return await EntitlementService.get_user_entitlement(db, current_user)
