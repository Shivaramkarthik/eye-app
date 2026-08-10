from typing import List, Dict, Any, Optional
from pydantic import BaseModel

class SyncOperationItem(BaseModel):
    operation_id: str  # Unique GUID per client operation (idempotency key)
    entity_type: str   # profile, prescription, medication, report, score
    entity_id: str
    operation: str     # CREATE, UPDATE, DELETE
    payload: Dict[str, Any]
    version: int = 1
    timestamp: str

class SyncPushRequest(BaseModel):
    device_id: str
    operations: List[SyncOperationItem]

class SyncOperationResult(BaseModel):
    operation_id: str
    entity_id: str
    status: str  # PROCESSED, CONFLICT, REJECTED
    error: Optional[str] = None

class SyncPushResponse(BaseModel):
    device_id: str
    processed_count: int
    results: List[SyncOperationResult]

class SyncPullResponse(BaseModel):
    server_time: str
    profiles: List[Dict[str, Any]] = []
    prescriptions: List[Dict[str, Any]] = []
    medications: List[Dict[str, Any]] = []
    reports: List[Dict[str, Any]] = []
    scores: List[Dict[str, Any]] = []
