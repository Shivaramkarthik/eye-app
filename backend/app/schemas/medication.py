from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel

class ScheduleSchema(BaseModel):
    id: Optional[str] = None
    time: str
    tone: str = "Soft Chime"
    vibration_enabled: int = 1
    enabled: int = 1

class LogSchema(BaseModel):
    id: Optional[str] = None
    schedule_id: str
    scheduled_at: str
    actual_at: Optional[str] = None
    status: str = "TAKEN"

class MedicationCreate(BaseModel):
    name: str
    type: str = "Drop"
    dosage: str
    start_date: str
    end_date: Optional[str] = None
    active: int = 1
    schedules: List[ScheduleSchema] = []

class MedicationOut(BaseModel):
    id: str
    profile_id: str
    user_id: str
    name: str
    type: str
    dosage: str
    start_date: str
    end_date: Optional[str] = None
    active: int
    schedules: List[ScheduleSchema] = []
    completed_logs: List[str] = []
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
