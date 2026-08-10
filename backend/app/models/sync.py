from datetime import datetime, timezone
from sqlalchemy import Column, String, DateTime, Text, Integer, ForeignKey
from sqlalchemy.orm import relationship
from app.database.session import Base

class SyncRecord(Base):
    __tablename__ = "sync_records"

    id = Column(String, primary_key=True, index=True)
    user_id = Column(String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    device_id = Column(String, nullable=False, index=True)
    operation_id = Column(String, nullable=False, unique=True, index=True) # Idempotency check
    entity_type = Column(String, nullable=False) # profile, prescription, medication, report, etc.
    entity_id = Column(String, nullable=False)
    operation = Column(String, nullable=False)   # CREATE, UPDATE, DELETE
    payload = Column(Text, nullable=False)       # JSON string payload
    version = Column(Integer, nullable=False, default=1)
    status = Column(String, nullable=False, default="PROCESSED") # PROCESSED, CONFLICT, REJECTED
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)

    user = relationship("User", back_populates="sync_records")
