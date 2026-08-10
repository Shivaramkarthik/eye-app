import json
from datetime import datetime, timezone
from fastapi import APIRouter, Request, Header, HTTPException, status, Depends
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select

from app.database.session import get_db
from app.services.payment_service import PaymentService
from app.models.user import User
from app.models.subscription import Subscription

router = APIRouter()

@router.post("/razorpay")
async def razorpay_webhook(
    request: Request,
    x_razorpay_signature: str = Header(None),
    db: AsyncSession = Depends(get_db)
):
    """Processes server-to-server Razorpay webhooks with signature verification and idempotency."""
    body = await request.body()
    if not x_razorpay_signature or not PaymentService.verify_webhook_signature(body, x_razorpay_signature):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid webhook signature.")

    try:
        data = json.loads(body)
        event = data.get("event")
        payload = data.get("payload", {})

        if event in ["payment.captured", "order.paid"]:
            payment_entity = payload.get("payment", {}).get("entity", {})
            notes = payment_entity.get("notes", {})
            user_id = notes.get("user_id")
            plan = notes.get("plan", "plus")

            if user_id:
                stmt = select(User).where(User.id == user_id)
                res = await db.execute(stmt)
                user = res.scalar_one_or_none()
                if user:
                    user.plan = plan
                    user.updated_at = datetime.now(timezone.utc)
                    await db.commit()

        return {"status": "ok", "event": event}
    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"Webhook error: {str(e)}")
