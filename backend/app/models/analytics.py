from datetime import datetime, timezone
from sqlalchemy import Column, String, DateTime, Text
from app.database.session import Base

class AnalyticsEvent(Base):
    __tablename__ = "analytics_events"

    id = Column(String, primary_key=True, index=True)
    user_id = Column(String, nullable=True, index=True)
    event_type = Column(String, nullable=False, index=True) # app_opened, profile_created, etc.
    device_id = Column(String, nullable=True)
    properties = Column(Text, nullable=True) # Privacy-safe properties (NO medical data/secrets)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)

class AuditLog(Base):
    __tablename__ = "audit_logs"

    id = Column(String, primary_key=True, index=True)
    user_id = Column(String, nullable=True, index=True)
    action = Column(String, nullable=False, index=True) # login, logout, password_change, payment_verified, etc.
    ip_address = Column(String, nullable=True)
    user_agent = Column(String, nullable=True)
    details = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)
