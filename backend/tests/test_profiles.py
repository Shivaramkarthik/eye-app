import pytest
from httpx import AsyncClient
from conftest import make_google_payload

@pytest.mark.asyncio
async def test_profile_creation_and_limit(client: AsyncClient, mock_google_verify):
    # Register Free Tier User via Google Sign-In
    mock_google_verify.return_value = make_google_payload(
        sub="free_user_sub", email="freeuser@specz.co", name="Free User"
    )
    reg_res = await client.post(
        "/api/v1/auth/google",
        json={"google_id_token": "token"}
    )
    token = reg_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # 1. Create First Profile (Allowed under Free Tier limit)
    p1_res = await client.post(
        "/api/v1/profiles",
        headers=headers,
        json={"name": "Self Profile", "dob": "1990-01-01", "gender": "Male", "relationship": "Self"}
    )
    assert p1_res.status_code == 201
    p1_id = p1_res.json()["id"]

    # 2. Attempt Second Profile (Must be blocked by Server Entitlement Enforcement: 402 Payment Required)
    p2_res = await client.post(
        "/api/v1/profiles",
        headers=headers,
        json={"name": "Child Profile", "dob": "2015-05-05", "gender": "Female", "relationship": "Child"}
    )
    assert p2_res.status_code == 402
    assert "Profile limit reached" in p2_res.json()["detail"]

@pytest.mark.asyncio
async def test_profile_idor_protection(client: AsyncClient, mock_google_verify):
    # Register User A
    mock_google_verify.return_value = make_google_payload(
        sub="user_a_sub", email="user_a@specz.co", name="User A"
    )
    user_a = await client.post("/api/v1/auth/google", json={"google_id_token": "token_a"})
    token_a = user_a.json()["access_token"]
    headers_a = {"Authorization": f"Bearer {token_a}"}

    # Register User B
    mock_google_verify.return_value = make_google_payload(
        sub="user_b_sub", email="user_b@specz.co", name="User B"
    )
    user_b = await client.post("/api/v1/auth/google", json={"google_id_token": "token_b"})
    token_b = user_b.json()["access_token"]
    headers_b = {"Authorization": f"Bearer {token_b}"}

    # User A creates a profile
    p_a = await client.post("/api/v1/profiles", headers=headers_a, json={"name": "User A Profile", "dob": "1992-02-02", "gender": "Male"})
    p_a_id = p_a.json()["id"]

    # User B attempts to access User A's profile (IDOR Attack -> Must fail with 404/403)
    idor_res = await client.get(f"/api/v1/profiles/{p_a_id}", headers=headers_b)
    assert idor_res.status_code in [403, 404]
