from typing import Optional, List, Dict, Any
from pydantic import BaseModel

class OCRRequest(BaseModel):
    image_base64: Optional[str] = None
    image_url: Optional[str] = None

class EyeOCRResult(BaseModel):
    sph: Optional[float] = None
    cyl: Optional[float] = None
    axis: Optional[int] = None
    status: str = "CONFIRMED"

class OCRResponse(BaseModel):
    doctor_name: Optional[str] = None
    clinic_name: Optional[str] = None
    prescription_date: Optional[str] = None
    add_power: Optional[float] = None
    pd: Optional[float] = None
    right_eye: EyeOCRResult
    left_eye: EyeOCRResult
    confidence: Dict[str, float] = {}

class AIQuestionsRequest(BaseModel):
    profile_id: str
    symptoms: List[str] = []
    prescription_summary: Optional[str] = None
    language: str = "en"

class AIQuestionsResponse(BaseModel):
    questions: List[str]
    category: str = "General"
    disclaimer: str = "Informational only. Not medical advice."

class AISummaryRequest(BaseModel):
    profile_id: str
    language: str = "en"

class AISummaryResponse(BaseModel):
    summary_text: str
    disclaimer: str = "Informational care summary only. Consult an eye doctor for diagnosis."
