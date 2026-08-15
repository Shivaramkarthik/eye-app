import pytest
from httpx import AsyncClient
from conftest import make_google_payload

@pytest.mark.asyncio
async def test_prescription_preserves_null_cyl(client: AsyncClient, mock_google_verify):
    # Setup User via Google Sign-In
    mock_google_verify.return_value = make_google_payload(
        sub="presc_user_sub", email="presc_user@specz.co", name="Presc User"
    )
    reg = await client.post("/api/v1/auth/google", json={"google_id_token": "token"})
    token = reg.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    prof = await client.post("/api/v1/profiles", headers=headers, json={"name": "Presc Profile", "dob": "1988-08-08", "gender": "Female"})
    pid = prof.json()["id"]

    # Create prescription with right_eye SPH=-1.50, CYL=None (Missing cylinder power)
    presc_payload = {
        "prescription_date": "2026-08-10",
        "doctor_name": "Dr. Smith",
        "clinic_name": "Optical Center",
        "source": "MANUAL",
        "eye_values": [
            {
                "eye": "OD",
                "sph": -1.50,
                "cyl": None, # MUST preserve NULL
                "axis": None,
                "sph_status": "CONFIRMED",
                "cyl_status": "MISSING",
                "axis_status": "MISSING"
            }
        ]
    }

    res = await client.post(f"/api/v1/profiles/{pid}/prescriptions", headers=headers, json=presc_payload)
    assert res.status_code == 201
    data = res.json()
    assert len(data["eye_values"]) == 1
    assert data["eye_values"][0]["sph"] == -1.50
    assert data["eye_values"][0]["cyl"] is None # Preserved NULL!
