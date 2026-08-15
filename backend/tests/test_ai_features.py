import pytest
from httpx import AsyncClient
from conftest import make_google_payload


@pytest.mark.asyncio
async def test_ai_ocr_prescription_extraction(client: AsyncClient, mock_google_verify):
    """Tests optical prescription OCR extraction endpoint."""
    mock_google_verify.return_value = make_google_payload(
        sub="ocr_user_sub", email="ocr_user@specz.co", name="OCR Test User"
    )
    auth_res = await client.post("/api/v1/auth/google", json={"google_id_token": "ocr_token"})
    token = auth_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Post sample image base64
    res = await client.post(
        "/api/v1/ai/ocr-prescription",
        headers=headers,
        json={"image_base64": "data:image/jpeg;base64,sample_dummy_base64_data"},
    )
    assert res.status_code == 200
    data = res.json()
    assert "right_eye" in data
    assert "left_eye" in data
    assert "sph" in data["right_eye"]
    assert "cyl" in data["right_eye"]
    assert "axis" in data["right_eye"]
    assert "doctor_name" in data
    assert "confidence" in data


@pytest.mark.asyncio
async def test_ai_doctor_questions_generator(client: AsyncClient, mock_google_verify):
    """Tests AI clinical question generator for upcoming doctor appointments."""
    mock_google_verify.return_value = make_google_payload(
        sub="quest_user_sub", email="quest_user@specz.co", name="Questions User"
    )
    auth_res = await client.post("/api/v1/auth/google", json={"google_id_token": "quest_token"})
    token = auth_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Create profile
    p_res = await client.post(
        "/api/v1/profiles",
        headers=headers,
        json={"name": "Doctor Prep Profile", "dob": "1988-03-20", "gender": "Male"},
    )
    pid = p_res.json()["id"]

    # Request doctor questions with symptoms
    q_res = await client.post(
        "/api/v1/ai/doctor-questions",
        headers=headers,
        json={
            "profile_id": pid,
            "symptoms": ["Blurred Vision", "Dry Eyes", "Headaches"],
            "prescription_summary": "OD -2.00 OS -2.25",
            "language": "en",
        },
    )
    assert q_res.status_code == 200
    data = q_res.json()
    assert len(data["questions"]) >= 3
    assert "disclaimer" in data
    assert "Not medical advice" in data["disclaimer"]


@pytest.mark.asyncio
async def test_ai_summary_generator(client: AsyncClient, mock_google_verify):
    """Tests AI care routine summary generation."""
    mock_google_verify.return_value = make_google_payload(
        sub="summary_user_sub", email="summary_user@specz.co", name="Summary User"
    )
    auth_res = await client.post("/api/v1/auth/google", json={"google_id_token": "summary_token"})
    token = auth_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Create profile
    p_res = await client.post(
        "/api/v1/profiles",
        headers=headers,
        json={"name": "Summary Profile", "dob": "1992-11-11", "gender": "Female"},
    )
    pid = p_res.json()["id"]

    # Request summary
    s_res = await client.post(
        "/api/v1/ai/summary",
        headers=headers,
        json={"profile_id": pid, "language": "en"},
    )
    assert s_res.status_code == 200
    data = s_res.json()
    assert "summary_text" in data
    assert "Summary Profile" in data["summary_text"]
    assert "disclaimer" in data
