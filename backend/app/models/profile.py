from datetime import datetime, timezone
from sqlalchemy import Column, String, DateTime, Integer, ForeignKey
from sqlalchemy.orm import relationship
from app.database.session import Base

class Profile(Base):
    __tablename__ = "profiles"

    id = Column(String, primary_key=True, index=True)
    user_id = Column(String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    name = Column(String, nullable=False)
    dob = Column(String, nullable=False)
    gender = Column(String, nullable=False)
    relationship_type = Column("relationship", String, nullable=False, default="Self")
    profile_type = Column(String, nullable=False, default="Adult")
    prescription_type = Column(String, nullable=True)
    blurred_vision_type = Column(String, nullable=True)
    archived = Column(Integer, nullable=False, default=0)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)
    updated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc), nullable=False)
    deleted_at = Column(DateTime(timezone=True), nullable=True)

    # Relationships
    user = relationship("User", back_populates="profiles")
    symptoms = relationship("ProfileSymptom", back_populates="profile", cascade="all, delete-orphan")
    prescriptions = relationship("Prescription", back_populates="profile", cascade="all, delete-orphan")
    medications = relationship("Medication", back_populates="profile", cascade="all, delete-orphan")
    scores = relationship("EyeCareScore", back_populates="profile", cascade="all, delete-orphan")
    reports = relationship("Report", back_populates="profile", cascade="all, delete-orphan")

class ProfileSymptom(Base):
    __tablename__ = "profile_symptoms"

    id = Column(String, primary_key=True, index=True)
    profile_id = Column(String, ForeignKey("profiles.id", ondelete="CASCADE"), nullable=False, index=True)
    symptom = Column(String, nullable=False)
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)

    profile = relationship("Profile", back_populates="symptoms")
