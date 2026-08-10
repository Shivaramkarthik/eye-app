from datetime import datetime, timezone
from sqlalchemy import Column, String, DateTime, Float, Integer, ForeignKey
from sqlalchemy.orm import relationship
from app.database.session import Base

class Prescription(Base):
    __tablename__ = "prescriptions"

    id = Column(String, primary_key=True, index=True)
    profile_id = Column(String, ForeignKey("profiles.id", ondelete="CASCADE"), nullable=False, index=True)
    user_id = Column(String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    prescription_date = Column(String, nullable=False)
    doctor_name = Column(String, nullable=True)
    clinic_name = Column(String, nullable=True)
    add_power = Column(Float, nullable=True)
    pd = Column(Float, nullable=True)
    notes = Column(String, nullable=True)
    image_url = Column(String, nullable=True)
    source = Column(String, nullable=False, default="MANUAL")
    ocr_confidence = Column(Float, nullable=False, default=1.0)
    confirmed_by_user = Column(Integer, nullable=False, default=1)
    is_current = Column(Integer, nullable=False, default=1)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc), nullable=False)

    # Relationships
    profile = relationship("Profile", back_populates="prescriptions")
    user = relationship("User", back_populates="prescriptions")
    eye_values = relationship("PrescriptionEyeValue", back_populates="prescription", cascade="all, delete-orphan")

class PrescriptionEyeValue(Base):
    __tablename__ = "prescription_eye_values"

    id = Column(String, primary_key=True, index=True)
    prescription_id = Column(String, ForeignKey("prescriptions.id", ondelete="CASCADE"), nullable=False, index=True)
    eye = Column(String, nullable=False)  # 'OD' or 'OS'
    sph = Column(Float, nullable=True)     # NULL distinct from 0.0
    cyl = Column(Float, nullable=True)     # NULL distinct from 0.0
    axis = Column(Integer, nullable=True)
    sph_status = Column(String, nullable=False, default="CONFIRMED")
    cyl_status = Column(String, nullable=False, default="CONFIRMED")
    axis_status = Column(String, nullable=False, default="CONFIRMED")
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)

    prescription = relationship("Prescription", back_populates="eye_values")
