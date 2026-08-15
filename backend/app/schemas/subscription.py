from datetime import datetime
from typing import Optional, Dict, Any
from pydantic import BaseModel, ConfigDict


class RazorpayOrderCreate(BaseModel):
    plan: str = "plus"  # free / plus
    billing_period: str = "monthly"


class RazorpayOrderResponse(BaseModel):
    order_id: str
    amount: int
    currency: str = "INR"
    key_id: str


class PaymentVerifyRequest(BaseModel):
    razorpay_order_id: str
    razorpay_payment_id: str
    razorpay_signature: str
    plan: str = "plus"


class EntitlementOut(BaseModel):
    user_id: str
    plan: str
    status: str
    max_profiles: int
    features: Dict[str, Any]
    expires_at: Optional[datetime] = None


class SubscriptionOut(BaseModel):
    id: str
    user_id: str
    provider: str
    plan: str
    status: str
    started_at: datetime
    expires_at: Optional[datetime] = None
    created_at: datetime

    model_config = ConfigDict(from_attributes=True)
