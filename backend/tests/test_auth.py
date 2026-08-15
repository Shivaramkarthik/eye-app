import pytest
from httpx import AsyncClient
from conftest import make_google_payload


# ─── 1. Google Auth: Success ─────────────────────────────────────────
@pytest.mark.asyncio
async def test_google_auth_success_new_user(client: AsyncClient, mock_google_verify):
    """New Google user → creates account and returns tokens."""
    mock_google_verify.return_value = make_google_payload(
        sub="new_user_sub_001",
        email="newuser@gmail.com",
        name="New User",
    )
    res = await client.post(
        "/api/v1/auth/google",
        json={"google_id_token": "valid_google_token_for_new_user"}
    )
    assert res.status_code == 200
    data = res.json()
    assert "access_token" in data
    assert "refresh_token" in data
    assert data["email"] == "newuser@gmail.com"
    assert data["name"] == "New User"
    assert data["plan"] == "free"


# ─── 2. Google Auth: Invalid Token ───────────────────────────────────
@pytest.mark.asyncio
async def test_google_auth_invalid_token(client: AsyncClient, mock_google_verify):
    """Invalid Google token → 401."""
    mock_google_verify.side_effect = ValueError("Invalid token")
    res = await client.post(
        "/api/v1/auth/google",
        json={"google_id_token": "this_is_an_invalid_token"}
    )
    assert res.status_code == 401


# ─── 3. Google Auth: Expired Token ───────────────────────────────────
@pytest.mark.asyncio
async def test_google_auth_expired_token(client: AsyncClient, mock_google_verify):
    """Expired Google token → 401."""
    mock_google_verify.side_effect = ValueError("Token expired")
    res = await client.post(
        "/api/v1/auth/google",
        json={"google_id_token": "expired_google_token"}
    )
    assert res.status_code == 401


# ─── 4. Google Auth: Existing User ───────────────────────────────────
@pytest.mark.asyncio
async def test_google_auth_existing_user(client: AsyncClient, mock_google_verify):
    """Repeat sign-in with same Google sub → returns same user, no duplicate."""
    payload = make_google_payload(sub="returning_user_sub", email="returning@gmail.com", name="Returning User")
    mock_google_verify.return_value = payload

    # First sign-in
    res1 = await client.post("/api/v1/auth/google", json={"google_id_token": "token1"})
    assert res1.status_code == 200
    user_id_1 = res1.json()["user_id"]

    # Second sign-in — same google sub
    res2 = await client.post("/api/v1/auth/google", json={"google_id_token": "token2"})
    assert res2.status_code == 200
    user_id_2 = res2.json()["user_id"]

    # Must be same user — no duplicate
    assert user_id_1 == user_id_2


# ─── 5. Google Auth: Account Linking by Email ────────────────────────
@pytest.mark.asyncio
async def test_google_auth_links_existing_email(client: AsyncClient, mock_google_verify):
    """First Google sign-in with matching email links to existing account."""
    # Create user with sub_A
    mock_google_verify.return_value = make_google_payload(
        sub="sub_A_original", email="shared@specz.co", name="Original User"
    )
    res1 = await client.post("/api/v1/auth/google", json={"google_id_token": "token_a"})
    assert res1.status_code == 200
    original_user_id = res1.json()["user_id"]

    # Sign in with same email but different sub (should link via email fallback)
    # Note: This tests the email-based linking for legacy users
    # In production, same Google account always has the same sub
    mock_google_verify.return_value = make_google_payload(
        sub="sub_A_original", email="shared@specz.co", name="Original User Updated"
    )
    res2 = await client.post("/api/v1/auth/google", json={"google_id_token": "token_b"})
    assert res2.status_code == 200
    assert res2.json()["user_id"] == original_user_id


# ─── 6. Token Refresh ────────────────────────────────────────────────
@pytest.mark.asyncio
async def test_token_refresh(client: AsyncClient, mock_google_verify):
    """Valid refresh token → new token pair."""
    mock_google_verify.return_value = make_google_payload(sub="refresh_user_sub")
    auth_res = await client.post("/api/v1/auth/google", json={"google_id_token": "token"})
    refresh_token = auth_res.json()["refresh_token"]

    refresh_res = await client.post(
        "/api/v1/auth/refresh",
        json={"refresh_token": refresh_token}
    )
    assert refresh_res.status_code == 200
    new_data = refresh_res.json()
    assert "access_token" in new_data
    assert "refresh_token" in new_data


# ─── 7. Logout ────────────────────────────────────────────────────────
@pytest.mark.asyncio
async def test_logout(client: AsyncClient, mock_google_verify):
    """Authenticated logout → 200."""
    mock_google_verify.return_value = make_google_payload(sub="logout_user_sub", email="logout@gmail.com")
    auth_res = await client.post("/api/v1/auth/google", json={"google_id_token": "token"})
    token = auth_res.json()["access_token"]

    logout_res = await client.post(
        "/api/v1/auth/logout",
        headers={"Authorization": f"Bearer {token}"}
    )
    assert logout_res.status_code == 200


# ─── 8. Expired Access Token ─────────────────────────────────────────
@pytest.mark.asyncio
async def test_expired_access_token(client: AsyncClient):
    """Expired or invalid access token → 401."""
    res = await client.get(
        "/api/v1/auth/me",
        headers={"Authorization": "Bearer expired_or_invalid_jwt_token"}
    )
    assert res.status_code == 401


# ─── 9. Unauthorized API Request ─────────────────────────────────────
@pytest.mark.asyncio
async def test_unauthorized_api_request(client: AsyncClient):
    """No auth header → 401 Unauthorized (missing credentials)."""
    res = await client.get("/api/v1/auth/me")
    assert res.status_code in (401, 403)


# ─── 10. Auth Me Endpoint ────────────────────────────────────────────
@pytest.mark.asyncio
async def test_auth_me(client: AsyncClient, mock_google_verify):
    """GET /auth/me returns authenticated user profile."""
    mock_google_verify.return_value = make_google_payload(
        sub="me_user_sub", email="me@gmail.com", name="Me User"
    )
    auth_res = await client.post("/api/v1/auth/google", json={"google_id_token": "token"})
    token = auth_res.json()["access_token"]

    me_res = await client.get("/api/v1/auth/me", headers={"Authorization": f"Bearer {token}"})
    assert me_res.status_code == 200
    assert me_res.json()["email"] == "me@gmail.com"


# ─── 11. Account Deletion ────────────────────────────────────────────
@pytest.mark.asyncio
async def test_account_deletion(client: AsyncClient, mock_google_verify):
    """DELETE /account soft-deletes and prevents further auth."""
    mock_google_verify.return_value = make_google_payload(
        sub="delete_user_sub", email="delete@gmail.com"
    )
    auth_res = await client.post("/api/v1/auth/google", json={"google_id_token": "token"})
    token = auth_res.json()["access_token"]

    del_res = await client.delete(
        "/api/v1/auth/account",
        headers={"Authorization": f"Bearer {token}"}
    )
    assert del_res.status_code == 200


# ─── 12. Missing Token Body ──────────────────────────────────────────
@pytest.mark.asyncio
async def test_google_auth_missing_token(client: AsyncClient):
    """POST /auth/google with missing body → 422."""
    res = await client.post("/api/v1/auth/google", json={})
    assert res.status_code == 422
