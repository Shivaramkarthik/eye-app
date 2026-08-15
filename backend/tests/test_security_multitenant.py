import pytest
import pytest_asyncio
from httpx import AsyncClient
from conftest import make_google_payload


async def create_test_user(client: AsyncClient, mock_google_verify, sub: str, email: str, name: str):
    """Helper to authenticate and create an isolated user."""
    mock_google_verify.return_value = make_google_payload(sub=sub, email=email, name=name)
    res = await client.post("/api/v1/auth/google", json={"google_id_token": f"token_{sub}"})
    token = res.json()["access_token"]
    user_id = res.json()["user_id"]
    headers = {"Authorization": f"Bearer {token}"}
    return {"id": user_id, "headers": headers}


@pytest.mark.asyncio
async def test_cross_tenant_profile_isolation(client: AsyncClient, mock_google_verify):
    """User B cannot read, update, or delete User A's profile."""
    user_a = await create_test_user(client, mock_google_verify, "user_a_sec", "a_sec@specz.co", "User A")
    user_b = await create_test_user(client, mock_google_verify, "user_b_sec", "b_sec@specz.co", "User B")

    # User A creates a profile
    p_res = await client.post(
        "/api/v1/profiles",
        headers=user_a["headers"],
        json={"name": "Confidential Profile A", "dob": "1990-01-01", "gender": "Male", "relationship": "Self"},
    )
    assert p_res.status_code == 201
    profile_a_id = p_res.json()["id"]

    # User B attempts to read User A's profile
    read_res = await client.get(f"/api/v1/profiles/{profile_a_id}", headers=user_b["headers"])
    assert read_res.status_code in [403, 404]

    # User B attempts to modify User A's profile
    patch_res = await client.patch(
        f"/api/v1/profiles/{profile_a_id}",
        headers=user_b["headers"],
        json={"name": "Compromised Profile"},
    )
    assert patch_res.status_code in [403, 404]

    # User B attempts to delete User A's profile
    del_res = await client.delete(f"/api/v1/profiles/{profile_a_id}", headers=user_b["headers"])
    assert del_res.status_code in [403, 404]


@pytest.mark.asyncio
async def test_cross_tenant_prescription_isolation(client: AsyncClient, mock_google_verify):
    """User B cannot view, inject, or delete prescriptions in User A's profile."""
    user_a = await create_test_user(client, mock_google_verify, "user_a_presc", "a_presc@specz.co", "User A Presc")
    user_b = await create_test_user(client, mock_google_verify, "user_b_presc", "b_presc@specz.co", "User B Presc")

    # User A creates profile and prescription
    p_res = await client.post(
        "/api/v1/profiles",
        headers=user_a["headers"],
        json={"name": "Presc Profile A", "dob": "1991-02-02", "gender": "Female"},
    )
    pid = p_res.json()["id"]

    presc_res = await client.post(
        f"/api/v1/profiles/{pid}/prescriptions",
        headers=user_a["headers"],
        json={
            "prescription_date": "2026-08-15",
            "doctor_name": "Dr. Confidential",
            "eye_values": [{"eye": "OD", "sph": -2.5, "cyl": -0.5, "axis": 90}],
        },
    )
    assert presc_res.status_code == 201
    presc_id = presc_res.json()["id"]

    # User B attempts to list prescriptions of User A's profile
    list_res = await client.get(f"/api/v1/profiles/{pid}/prescriptions", headers=user_b["headers"])
    assert list_res.status_code in [403, 404]

    # User B attempts to create prescription in User A's profile
    inject_res = await client.post(
        f"/api/v1/profiles/{pid}/prescriptions",
        headers=user_b["headers"],
        json={
            "prescription_date": "2026-08-15",
            "eye_values": [{"eye": "OD", "sph": -9.0}],
        },
    )
    assert inject_res.status_code in [403, 404]

    # User B attempts to delete User A's prescription
    del_res = await client.delete(f"/api/v1/prescriptions/{presc_id}", headers=user_b["headers"])
    assert del_res.status_code in [403, 404]


@pytest.mark.asyncio
async def test_cross_tenant_medication_isolation(client: AsyncClient, mock_google_verify):
    """User B cannot view, create, or delete eye drops in User A's profile."""
    user_a = await create_test_user(client, mock_google_verify, "user_a_med", "a_med@specz.co", "User A Med")
    user_b = await create_test_user(client, mock_google_verify, "user_b_med", "b_med@specz.co", "User B Med")

    p_res = await client.post(
        "/api/v1/profiles",
        headers=user_a["headers"],
        json={"name": "Med Profile A", "dob": "1993-04-04", "gender": "Other"},
    )
    pid = p_res.json()["id"]

    med_res = await client.post(
        f"/api/v1/profiles/{pid}/medications",
        headers=user_a["headers"],
        json={
            "name": "Secret Eye Drops",
            "type": "Drop",
            "dosage": "1 drop twice daily",
            "start_date": "2026-08-15",
            "schedules": [{"time": "08:00 AM"}, {"time": "08:00 PM"}],
        },
    )
    assert med_res.status_code == 201
    med_id = med_res.json()["id"]

    # User B attempts to list User A's medications
    list_res = await client.get(f"/api/v1/profiles/{pid}/medications", headers=user_b["headers"])
    assert list_res.status_code in [403, 404]

    # User B attempts to delete User A's medication
    del_res = await client.delete(f"/api/v1/medications/{med_id}", headers=user_b["headers"])
    assert del_res.status_code in [403, 404]
