from datetime import datetime, timezone
from sqlalchemy import Column, String, DateTime, Integer, ForeignKey
from sqlalchemy.orm import relationship
from app.database.session import Base

class Medication(Base):
    __tablename__ = "medications"

    id = Column(String, primary_key=True, index=True)
    profile_id = Column(String, ForeignKey("profiles.id", ondelete="CASCADE"), nullable=False, index=True)
    user_id = Column(String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    name = Column(String, nullable=False)
    type = Column(String, nullable=False, default="Drop")
    dosage = Column(String, nullable=False)
    start_date = Column(String, nullable=False)
    end_date = Column(String, nullable=True)
    active = Column(Integer, nullable=False, default=1)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc), nullable=False)

    # Relationships
    profile = relationship("Profile", back_populates="medications")
    user = relationship("User", back_populates="medications")
    schedules = relationship("MedicationSchedule", back_populates="medication", cascade="all, delete-orphan")
    logs = relationship("MedicationLog", back_populates="medication", cascade="all, delete-orphan")

class MedicationSchedule(Base):
    __tablename__ = "medication_schedules"

    id = Column(String, primary_key=True, index=True)
    medication_id = Column(String, ForeignKey("medications.id", ondelete="CASCADE"), nullable=False, index=True)
    time = Column(String, nullable=False)
    tone = Column(String, nullable=False, default="Soft Chime")
    vibration_enabled = Column(Integer, nullable=False, default=1)
    enabled = Column(Integer, nullable=False, default=1)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc), nullable=False)

    medication = relationship("Medication", back_populates="schedules")

class MedicationLog(Base):
    __tablename__ = "medication_logs"

    id = Column(String, primary_key=True, index=True)
    medication_id = Column(String, ForeignKey("medications.id", ondelete="CASCADE"), nullable=False, index=True)
    schedule_id = Column(String, nullable=False)
    scheduled_at = Column(String, nullable=False)
    actual_at = Column(String, nullable=True)
    status = Column(String, nullable=False, default="TAKEN") # TAKEN, SNOOZED, SKIPPED, MISSED
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)

    medication = relationship("Medication", back_populates="logs")
