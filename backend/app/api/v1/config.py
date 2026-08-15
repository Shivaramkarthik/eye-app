import os
from fastapi import APIRouter
from pydantic import BaseModel

router = APIRouter()


class FeatureFlagsResponse(BaseModel):
    ocr_enabled: bool
    ai_enabled: bool
    pdf_export_enabled: bool
    plus_enabled: bool
    sync_enabled: bool
    maintenance_mode: bool
    min_app_version: str
    server_time: str


@router.get("/feature-flags", response_model=FeatureFlagsResponse)
async def get_feature_flags():
    """Returns remote feature flags and launch kill switches.
    
    Allows disabling individual subsystems (e.g. OCR, AI, Payments)
    during third-party provider outages without requiring an emergency app release.
    """
    from datetime import datetime, timezone

    return FeatureFlagsResponse(
        ocr_enabled=os.getenv("FLAG_OCR_ENABLED", "true").lower() == "true",
        ai_enabled=os.getenv("FLAG_AI_ENABLED", "true").lower() == "true",
        pdf_export_enabled=os.getenv("FLAG_PDF_EXPORT_ENABLED", "true").lower() == "true",
        plus_enabled=os.getenv("FLAG_PLUS_ENABLED", "true").lower() == "true",
        sync_enabled=os.getenv("FLAG_SYNC_ENABLED", "true").lower() == "true",
        maintenance_mode=os.getenv("FLAG_MAINTENANCE_MODE", "false").lower() == "true",
        min_app_version=os.getenv("MIN_APP_VERSION", "2.0.0"),
        server_time=datetime.now(timezone.utc).isoformat(),
    )
