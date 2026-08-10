from datetime import datetime, timezone
from sqlalchemy import Column, String, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from app.database.session import Base

class Subscription(Base):
    __tablename__ = "subscriptions"

    id = Column(String, primary_key=True, index=True)
    user_id = Column(String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    provider = Column(String, nullable=False, default="razorpay")
    provider_customer_id = Column(String, nullable=True)
    provider_order_id = Column(String, nullable=True)
    provider_payment_id = Column(String, nullable=True)
    provider_subscription_id = Column(String, nullable=True)
    plan = Column(String, nullable=False, default="free")
    status = Column(String, nullable=False, default="ACTIVE")
    started_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)
    expires_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc), nullable=False)

    user = relationship("User", back_populates="subscriptions")
