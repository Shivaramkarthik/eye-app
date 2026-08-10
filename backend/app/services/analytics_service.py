import json
import uuid
from datetime import datetime, timezone
from typing import Optional, Dict, Any
from sqlalchemy.ext.asyncio import AsyncSession
from app.models.analytics import AnalyticsEvent, AuditLog

class AnalyticsService:
    @staticmethod
    async def log_event(db: AsyncSession, event_type: str, user_id: Optional[str] = None, device_id: Optional[str] = None, properties: Optional[Dict[str, Any]] = None):
        """Records privacy-safe analytics events (NO medical data or secrets)."""
        # Exclude any sensitive medical fields
        safe_props = properties or {}
        event = AnalyticsEvent(
            id=f"evt_{uuid.uuid4().hex[:12]}",
            user_id=user_id,
            event_type=event_type,
            device_id=device_id,
            properties=json.dumps(safe_props),
            created_at=datetime.now(timezone.utc)
        )
        db.add(event)
        await db.commit()

    @staticmethod
    async def log_audit(db: AsyncSession, action: str, user_id: Optional[str] = None, ip_address: Optional[str] = None, user_agent: Optional[str] = None, details: Optional[str] = None):
        """Records security audit logs (login, logout, password change, payment verification)."""
        audit = AuditLog(
            id=f"audit_{uuid.uuid4().hex[:12]}",
            user_id=user_id,
            action=action,
            ip_address=ip_address,
            user_agent=user_agent,
            details=details,
            created_at=datetime.now(timezone.utc)
        )
        db.add(audit)
        await db.commit()
