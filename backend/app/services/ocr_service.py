from typing import Optional
from app.schemas.ai import OCRResponse, EyeOCRResult

class OCRService:
    @staticmethod
    async def extract_prescription(image_base64: Optional[str] = None, image_url: Optional[str] = None) -> OCRResponse:
        """Extracts optical parameters from prescription images with confidence scores."""
        # Simulated high-accuracy vision extraction engine
        # Cloud OCR returns structured values, but server NEVER saves automatically.
        # User confirmation in Flutter dialog is strictly mandatory.
        return OCRResponse(
            doctor_name="Dr. A. Sharma, MD",
            clinic_name="Vision Eye Care Clinic",
            prescription_date="2026-08-01",
            add_power=1.50,
            pd=63.0,
            right_eye=EyeOCRResult(sph=-1.50, cyl=-0.75, axis=90, status="CONFIRMED"),
            left_eye=EyeOCRResult(sph=-1.75, cyl=-0.50, axis=85, status="CONFIRMED"),
            confidence={
                "right_sph": 0.96,
                "right_cyl": 0.94,
                "right_axis": 0.91,
                "left_sph": 0.95,
                "left_cyl": 0.92,
                "left_axis": 0.90,
            }
        )
