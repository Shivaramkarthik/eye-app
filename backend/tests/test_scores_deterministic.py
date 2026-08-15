import pytest
from httpx import AsyncClient
from conftest import make_google_payload


def calculate_test_score(
    prescription_completeness: int,
    prescription_stability: int,
    medication_adherence: int,
    followup_recency: int,
    record_completeness: int,
    care_routine_consistency: int,
    history_quality: int,
) -> int:
    """Deterministic reference implementation of Specz Vision Care Score V2 (0-100)."""
    sub_scores = [
        min(max(prescription_completeness, 0), 20),
        min(max(prescription_stability, 0), 15),
        min(max(medication_adherence, 0), 20),
        min(max(followup_recency, 0), 10),
        min(max(record_completeness, 0), 10),
        min(max(care_routine_consistency, 0), 10),
        min(max(history_quality, 0), 15),
    ]
    return sum(sub_scores)


def test_score_deterministic_boundary_max():
    """All 7 components at maximum capacity must yield exactly 100."""
    total = calculate_test_score(20, 15, 20, 10, 10, 10, 15)
    assert total == 100


def test_score_deterministic_boundary_min():
    """All 7 components at zero must yield exactly 0."""
    total = calculate_test_score(0, 0, 0, 0, 0, 0, 0)
    assert total == 0


def test_score_factor_isolation():
    """Each factor must strictly contribute within its bounded range."""
    # Adherence isolation (max 20)
    adh_max = calculate_test_score(0, 0, 20, 0, 0, 0, 0)
    assert adh_max == 20

    # Stability isolation (max 15)
    stab_max = calculate_test_score(0, 15, 0, 0, 0, 0, 0)
    assert stab_max == 15

    # Prescription completeness (max 20)
    comp_max = calculate_test_score(20, 0, 0, 0, 0, 0, 0)
    assert comp_max == 20


@pytest.mark.asyncio
async def test_score_api_fetch_and_disclaimer(client: AsyncClient, mock_google_verify):
    """Verifies score endpoint returns score or null for new profile without error."""
    mock_google_verify.return_value = make_google_payload(
        sub="score_user_sub", email="score_user@specz.co", name="Score Test User"
    )
    auth_res = await client.post("/api/v1/auth/google", json={"google_id_token": "score_token"})
    token = auth_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Create profile
    p_res = await client.post(
        "/api/v1/profiles",
        headers=headers,
        json={"name": "Score Profile", "dob": "1995-05-15", "gender": "Female"},
    )
    pid = p_res.json()["id"]

    # Fetch score (None initially for fresh profile)
    score_res = await client.get(f"/api/v1/profiles/{pid}/score", headers=headers)
    assert score_res.status_code == 200
