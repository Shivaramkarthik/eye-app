import pytest
from httpx import AsyncClient

@pytest.mark.asyncio
async def test_auth_register_and_login(client: AsyncClient):
    # 1. Register User A
    reg_res = await client.post(
        "/api/v1/auth/register",
        json={"email": "testuser_a@specz.co", "password": "SecurePassword123!", "name": "User A"}
    )
    assert reg_res.status_code == 201
    token_data = reg_res.json()
    assert "access_token" in token_data
    assert token_data["email"] == "testuser_a@specz.co"

    # 2. Login User A
    login_res = await client.post(
        "/api/v1/auth/login",
        json={"email": "testuser_a@specz.co", "password": "SecurePassword123!"}
    )
    assert login_res.status_code == 200
    assert "access_token" in login_res.json()

    # 3. Test Invalid Credentials
    bad_login = await client.post(
        "/api/v1/auth/login",
        json={"email": "testuser_a@specz.co", "password": "WrongPassword!"}
    )
    assert bad_login.status_code == 401

@pytest.mark.asyncio
async def test_auth_me(client: AsyncClient):
    # Register & get token
    reg_res = await client.post(
        "/api/v1/auth/register",
        json={"email": "testuser_me@specz.co", "password": "SecurePassword123!", "name": "User Me"}
    )
    token = reg_res.json()["access_token"]

    headers = {"Authorization": f"Bearer {token}"}
    me_res = await client.get("/api/v1/auth/me", headers=headers)
    assert me_res.status_code == 200
    assert me_res.json()["email"] == "testuser_me@specz.co"
