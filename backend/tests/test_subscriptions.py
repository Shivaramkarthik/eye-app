import pytest
from httpx import AsyncClient
from conftest import make_google_payload

@pytest.mark.asyncio
async def test_subscription_and_entitlements(client: AsyncClient, mock_google_verify):
    mock_google_verify.return_value = make_google_payload(
        sub="sub_user_sub", email="sub_user@specz.co", name="Sub User"
    )
    reg = await client.post("/api/v1/auth/google", json={"google_id_token": "token"})
    token = reg.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # 1. Get Initial Entitlement (Free plan, max 1 profile)
    ent1 = await client.get("/api/v1/subscriptions/entitlements/me", headers=headers)
    assert ent1.status_code == 200
    assert ent1.json()["plan"] == "free"
    assert ent1.json()["max_profiles"] == 1

    # 2. Create Razorpay Order
    order_res = await client.post("/api/v1/subscriptions/create-order", headers=headers, json={"plan": "plus"})
    assert order_res.status_code == 200
    order_id = order_res.json()["order_id"]
    assert order_id.startswith("order_")

    # 3. Verify Payment & Upgrade to Plus
    verify_res = await client.post(
        "/api/v1/subscriptions/verify-payment",
        headers=headers,
        json={
            "razorpay_order_id": order_id,
            "razorpay_payment_id": "pay_mock_123456",
            "razorpay_signature": "mock_signature_valid",
            "plan": "plus"
        }
    )
    assert verify_res.status_code == 200
    assert verify_res.json()["plan"] == "plus"

    # 4. Get Upgraded Entitlement (Plus plan, max 5 profiles)
    ent2 = await client.get("/api/v1/subscriptions/entitlements/me", headers=headers)
    assert ent2.status_code == 200
    assert ent2.json()["plan"] == "plus"
    assert ent2.json()["max_profiles"] == 5
