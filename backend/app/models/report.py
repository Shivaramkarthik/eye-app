from datetime import datetime, timezone
from sqlalchemy import Column, String, DateTime, Integer, Text, ForeignKey
from sqlalchemy.orm import relationship
from app.database.session import Base

class Report(Base):
    __tablename__ = "reports"

    id = Column(String, primary_key=True, index=True)
    profile_id = Column(String, ForeignKey("profiles.id", ondelete="CASCADE"), nullable=False, index=True)
    user_id = Column(String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    report_date = Column(String, nullable=False)
    title = Column(String, nullable=False)
    clinic_name = Column(String, nullable=True)
    file_path = Column(String, nullable=True)
    notes = Column(Text, nullable=True)
    follow_up_date = Column(String, nullable=True)
    score_snapshot = Column(Integer, nullable=False, default=85)
    score_explanation_snapshot = Column(Text, nullable=True)
    ai_summary_snapshot = Column(Text, nullable=True)
    doctor_questions_snapshot = Column(Text, nullable=True)
    report_version = Column(Integer, nullable=False, default=2)
    language = Column(String, nullable=False, default="en")
    created_at = Column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc), nullable=False)

    profile = relationship("Profile", back_populates="reports")
    user = relationship("User", back_populates="reports")
