from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, ConfigDict


class EyeValueSchema(BaseModel):
    eye: str  # 'OD' or 'OS'
    sph: Optional[float] = None  # None distinct from 0.00
    cyl: Optional[float] = None  # None distinct from 0.00
    axis: Optional[int] = None
    sph_status: str = "CONFIRMED"
    cyl_status: str = "CONFIRMED"
    axis_status: str = "CONFIRMED"

    model_config = ConfigDict(from_attributes=True)


class PrescriptionCreate(BaseModel):
    prescription_date: str
    doctor_name: Optional[str] = None
    clinic_name: Optional[str] = None
    add_power: Optional[float] = None
    pd: Optional[float] = None
    notes: Optional[str] = None
    image_url: Optional[str] = None
    source: str = "MANUAL"
    ocr_confidence: float = 1.0
    confirmed_by_user: int = 1
    is_current: int = 1
    eye_values: List[EyeValueSchema] = []


class PrescriptionOut(BaseModel):
    id: str
    profile_id: str
    user_id: str
    prescription_date: str
    doctor_name: Optional[str] = None
    clinic_name: Optional[str] = None
    add_power: Optional[float] = None
    pd: Optional[float] = None
    notes: Optional[str] = None
    image_url: Optional[str] = None
    source: str
    ocr_confidence: float
    confirmed_by_user: int
    is_current: int
    eye_values: List[EyeValueSchema] = []
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
