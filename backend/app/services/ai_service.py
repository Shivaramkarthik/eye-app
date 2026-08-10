from typing import List
from app.schemas.ai import AIQuestionsResponse, AISummaryResponse

class AIService:
    @staticmethod
    async def generate_doctor_questions(symptoms: List[str], prescription_summary: str = None, language: str = "en") -> AIQuestionsResponse:
        """Generates clinical questions to ask during doctor visits."""
        # Non-diagnostic informational question generation
        default_questions = [
            "Has there been any significant change in my spherical or cylindrical prescription power?",
            "Are my current eye drop medications still appropriate for my symptoms?",
            "How often should I schedule follow-up intraocular pressure or retina screenings?",
            "What specific preventative measures can reduce digital eye strain during daily work?"
        ]
        
        if symptoms:
            for sym in symptoms:
                default_questions.append(f"Regarding my symptoms of {sym.lower()}, is there any underlying treatment or precaution recommended?")

        return AIQuestionsResponse(
            questions=default_questions[:5],
            category="Clinical Follow-Up",
            disclaimer="Informational guide only. Not medical advice. Always consult your ophthalmologist or optometrist."
        )

    @staticmethod
    async def generate_summary(profile_name: str, score: int, prescription_date: str = None) -> AISummaryResponse:
        """Generates a non-diagnostic vision care routine summary."""
        summary = (
            f"Care routine summary for {profile_name}: Vision Care Score is currently {score}/100. "
            f"Prescription history is recorded and up-to-date. Ensure eye drop doses are logged regularly."
        )
        return AISummaryResponse(
            summary_text=summary,
            disclaimer="Informational vision care overview. Non-diagnostic. Consult your eye care professional for medical evaluation."
        )
