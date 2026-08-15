from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, Field, ConfigDict


class ProfileCreate(BaseModel):
    name: str = Field(..., min_length=1)
    dob: str
    gender: str
    relationship: str = "Self"
    profile_type: str = "Adult"
    prescription_type: Optional[str] = None
    blurred_vision_type: Optional[str] = None
    symptoms: List[str] = []


class ProfileUpdate(BaseModel):
    name: Optional[str] = None
    dob: Optional[str] = None
    gender: Optional[str] = None
    relationship: Optional[str] = None
    profile_type: Optional[str] = None
    prescription_type: Optional[str] = None
    blurred_vision_type: Optional[str] = None
    symptoms: Optional[List[str]] = None
    archived: Optional[int] = None


class ProfileOut(BaseModel):
    id: str
    user_id: str
    name: str
    dob: str
    gender: str
    relationship: str
    profile_type: str
    prescription_type: Optional[str] = None
    blurred_vision_type: Optional[str] = None
    symptoms: List[str] = []
    archived: int = 0
    created_at: datetime
    updated_at: datetime

    model_config = ConfigDict(from_attributes=True)
