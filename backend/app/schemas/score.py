from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel

class EyeCareScoreOut(BaseModel):
    id: str
    profile_id: str
    score: int
    prescription_completeness_score: int
    prescription_stability_score: int
    medication_adherence_score: int
    followup_recency_score: int
    record_completeness_score: int
    care_routine_consistency_score: int
    history_quality_score: int
    explanation: str
    algorithm_version: int = 2
    calculated_at: datetime

    class Config:
        from_attributes = True

class AISummaryOut(BaseModel):
    id: str
    profile_id: str
    summary_text: str
    language: str = "en"
    model_version: str = "gemini-1.5-flash"
    prompt_version: str = "v2.0"
    generated_at: datetime

    class Config:
        from_attributes = True

class DoctorQuestionOut(BaseModel):
    id: str
    profile_id: str
    question_text: str
    category: str = "General"
    generated_at: datetime

    class Config:
        from_attributes = True
