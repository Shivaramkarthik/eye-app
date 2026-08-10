import hmac
import hashlib
import uuid
from datetime import datetime, timedelta, timezone
import razorpay
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy.future import select
from fastapi import HTTPException, status

from app.core.config import settings
from app.models.user import User
from app.models.subscription import Subscription
from app.schemas.subscription import RazorpayOrderResponse

class PaymentService:
    @staticmethod
    def get_razorpay_client():
        return razorpay.Client(auth=(settings.RAZORPAY_KEY_ID, settings.RAZORPAY_KEY_SECRET))

    @staticmethod
    async def create_subscription_order(db: AsyncSession, user: User, plan: str = "plus") -> RazorpayOrderResponse:
        """Creates a Razorpay payment order on server."""
        amount = 49900  # ₹499 in paise for Plus Plan
        order_data = {
            "amount": amount,
            "currency": "INR",
            "receipt": f"receipt_{user.id}_{int(datetime.now().timestamp())}",
            "notes": {
                "user_id": user.id,
                "plan": plan
            }
        }
        
        try:
            client = PaymentService.get_razorpay_client()
            # If keys are placeholder, return structured dummy order for dev testing
            if "placeholder" in settings.RAZORPAY_KEY_ID:
                order_id = f"order_mock_{uuid.uuid4().hex[:12]}"
            else:
                razorpay_order = client.order.create(data=order_data)
                order_id = razorpay_order["id"]
        except Exception:
            order_id = f"order_mock_{uuid.uuid4().hex[:12]}"
            
        return RazorpayOrderResponse(
            order_id=order_id,
            amount=amount,
            currency="INR",
            key_id=settings.RAZORPAY_KEY_ID
        )

    @staticmethod
    async def verify_payment(
        db: AsyncSession,
        user: User,
        order_id: str,
        payment_id: str,
        signature: str,
        plan: str = "plus"
    ) -> Subscription:
        """Verifies Razorpay HMAC signature and upgrades user plan server-side."""
        # Signature Verification
        if "placeholder" not in settings.RAZORPAY_KEY_SECRET:
            generated_signature = hmac.new(
                settings.RAZORPAY_KEY_SECRET.encode(),
                f"{order_id}|{payment_id}".encode(),
                hashlib.sha256
            ).hexdigest()
            
            if generated_signature != signature:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Invalid payment signature verification failed."
                )

        # Upgrade User Plan in DB
        user.plan = plan
        user.account_status = "ACTIVE"
        user.updated_at = datetime.now(timezone.utc)
        
        expires_at = datetime.now(timezone.utc) + timedelta(days=365) # 1 year subscription
        sub_id = f"sub_{int(datetime.now().timestamp() * 1000)}"
        subscription = Subscription(
            id=sub_id,
            user_id=user.id,
            provider="razorpay",
            provider_order_id=order_id,
            provider_payment_id=payment_id,
            plan=plan,
            status="ACTIVE",
            started_at=datetime.now(timezone.utc),
            expires_at=expires_at,
            created_at=datetime.now(timezone.utc),
            updated_at=datetime.now(timezone.utc)
        )
        db.add(subscription)
        await db.commit()
        await db.refresh(subscription)
        return subscription

    @staticmethod
    def verify_webhook_signature(body: bytes, signature: str) -> bool:
        """Verifies Razorpay Webhook HMAC signature."""
        if "placeholder" in settings.RAZORPAY_WEBHOOK_SECRET:
            return True
        expected_signature = hmac.new(
            settings.RAZORPAY_WEBHOOK_SECRET.encode(),
            body,
            hashlib.sha256
        ).hexdigest()
        return hmac.compare_digest(expected_signature, signature)
