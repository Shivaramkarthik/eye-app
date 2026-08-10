from datetime import datetime
from typing import Optional
from pydantic import BaseModel

class ReportCreate(BaseModel):
    profile_id: str
    report_date: str
    title: str
    clinic_name: Optional[str] = None
    file_path: Optional[str] = None
    notes: Optional[str] = None
    follow_up_date: Optional[str] = None
    score_snapshot: int = 85
    score_explanation_snapshot: Optional[str] = None
    ai_summary_snapshot: Optional[str] = None
    doctor_questions_snapshot: Optional[str] = None

class ReportOut(BaseModel):
    id: str
    profile_id: str
    user_id: str
    report_date: str
    title: str
    clinic_name: Optional[str] = None
    file_path: Optional[str] = None
    notes: Optional[str] = None
    follow_up_date: Optional[str] = None
    score_snapshot: int
    score_explanation_snapshot: Optional[str] = None
    ai_summary_snapshot: Optional[str] = None
    doctor_questions_snapshot: Optional[str] = None
    created_at: datetime

    class Config:
        from_attributes = True
