from datetime import datetime, timezone
from sqlalchemy import Column, String, DateTime, Integer, Text, ForeignKey
from sqlalchemy.orm import relationship
from app.database.session import Base

class EyeCareScore(Base):
    __tablename__ = "eye_care_scores"

    id = Column(String, primary_key=True, index=True)
    profile_id = Column(String, ForeignKey("profiles.id", ondelete="CASCADE"), nullable=False, index=True)
    score = Column(Integer, nullable=False)
    prescription_completeness_score = Column(Integer, nullable=False, default=20)
    prescription_stability_score = Column(Integer, nullable=False, default=15)
    medication_adherence_score = Column(Integer, nullable=False, default=20)
    followup_recency_score = Column(Integer, nullable=False, default=10)
    record_completeness_score = Column(Integer, nullable=False, default=10)
    care_routine_consistency_score = Column(Integer, nullable=False, default=10)
    history_quality_score = Column(Integer, nullable=False, default=15)
    explanation = Column(Text, nullable=False)
    algorithm_version = Column(Integer, nullable=False, default=2)
    calculated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)

    profile = relationship("Profile", back_populates="scores")

class AISummary(Base):
    __tablename__ = "ai_summaries"

    id = Column(String, primary_key=True, index=True)
    profile_id = Column(String, ForeignKey("profiles.id", ondelete="CASCADE"), nullable=False, index=True)
    summary_text = Column(Text, nullable=False)
    language = Column(String, nullable=False, default="en")
    model_version = Column(String, nullable=False, default="gemini-1.5-flash")
    prompt_version = Column(String, nullable=False, default="v2.0")
    generated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)

class DoctorQuestion(Base):
    __tablename__ = "doctor_questions"

    id = Column(String, primary_key=True, index=True)
    profile_id = Column(String, ForeignKey("profiles.id", ondelete="CASCADE"), nullable=False, index=True)
    question_text = Column(Text, nullable=False)
    category = Column(String, nullable=False, default="General")
    generated_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)
