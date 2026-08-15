import hmac
import hashlib
import pytest
from httpx import AsyncClient
from conftest import make_google_payload
from app.core.config import settings


@pytest.mark.asyncio
async def test_payment_invalid_signature_rejected(client: AsyncClient, mock_google_verify, monkeypatch):
    """Payment verification with forged signature must be rejected with 400 Bad Request."""
    monkeypatch.setattr(settings, "RAZORPAY_KEY_SECRET", "test_hmac_secret_123")

    mock_google_verify.return_value = make_google_payload(
        sub="pay_user_sub", email="payuser@specz.co", name="Payment User"
    )
    auth_res = await client.post("/api/v1/auth/google", json={"google_id_token": "pay_token"})
    token = auth_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Attempt verification with bogus signature
    verify_res = await client.post(
        "/api/v1/subscriptions/verify-payment",
        headers=headers,
        json={
            "razorpay_order_id": "order_test_12345",
            "razorpay_payment_id": "pay_test_12345",
            "razorpay_signature": "invalid_forged_hmac_signature",
            "plan": "plus",
        },
    )
    assert verify_res.status_code == 400
    assert "Invalid payment signature" in verify_res.json()["detail"]


@pytest.mark.asyncio
async def test_payment_valid_signature_and_idempotency(client: AsyncClient, mock_google_verify, monkeypatch):
    """Verifies that authentic HMAC signature activates Plus tier and repeated calls are idempotent."""
    secret = "test_hmac_secret_123"
    monkeypatch.setattr(settings, "RAZORPAY_KEY_SECRET", secret)

    mock_google_verify.return_value = make_google_payload(
        sub="pay_user_sub_2", email="payuser2@specz.co", name="Payment User 2"
    )
    auth_res = await client.post("/api/v1/auth/google", json={"google_id_token": "pay_token_2"})
    token = auth_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    order_id = "order_valid_998877"
    payment_id = "pay_valid_112233"

    # Compute genuine HMAC SHA256 signature using secret
    msg = f"{order_id}|{payment_id}".encode("utf-8")
    valid_sig = hmac.new(secret.encode("utf-8"), msg, hashlib.sha256).hexdigest()

    # 1. First Verification (Success)
    v1_res = await client.post(
        "/api/v1/subscriptions/verify-payment",
        headers=headers,
        json={
            "razorpay_order_id": order_id,
            "razorpay_payment_id": payment_id,
            "razorpay_signature": valid_sig,
            "plan": "plus",
        },
    )
    assert v1_res.status_code == 200
    assert v1_res.json()["plan"] == "plus"
    assert v1_res.json()["status"] == "ACTIVE"

    # 2. Check User Entitlements (Reflects Plus status)
    ent_res = await client.get("/api/v1/subscriptions/entitlements/me", headers=headers)
    assert ent_res.status_code == 200
    assert ent_res.json()["plan"] == "plus"
    assert ent_res.json()["max_profiles"] == 5

    # 3. Duplicate Verification Call (Idempotent Retry)
    v2_res = await client.post(
        "/api/v1/subscriptions/verify-payment",
        headers=headers,
        json={
            "razorpay_order_id": order_id,
            "razorpay_payment_id": payment_id,
            "razorpay_signature": valid_sig,
            "plan": "plus",
        },
    )
    assert v2_res.status_code == 200
    assert v2_res.json()["plan"] == "plus"
