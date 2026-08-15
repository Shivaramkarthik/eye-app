import pytest
from httpx import AsyncClient
from conftest import make_google_payload

@pytest.mark.asyncio
async def test_sync_push_idempotency(client: AsyncClient, mock_google_verify):
    mock_google_verify.return_value = make_google_payload(
        sub="sync_user_sub", email="sync_user@specz.co", name="Sync User"
    )
    reg = await client.post("/api/v1/auth/google", json={"google_id_token": "token"})
    token = reg.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    sync_payload = {
        "device_id": "test_device_001",
        "operations": [
            {
                "operation_id": "op_test_unique_12345",
                "entity_type": "profile",
                "entity_id": "profile_sync_001",
                "operation": "CREATE",
                "payload": {"name": "Synced Profile", "dob": "1995-01-01", "gender": "Other"},
                "version": 1,
                "timestamp": "2026-08-10T21:00:00Z"
            }
        ]
    }

    # 1. First Sync Push
    res1 = await client.post("/api/v1/sync/push", headers=headers, json=sync_payload)
    assert res1.status_code == 200
    data1 = res1.json()
    assert data1["processed_count"] == 1
    assert data1["results"][0]["status"] == "PROCESSED"

    # 2. Second Sync Push with exact same operation_id (Retry / Idempotency Test)
    res2 = await client.post("/api/v1/sync/push", headers=headers, json=sync_payload)
    assert res2.status_code == 200
    data2 = res2.json()
    assert data2["results"][0]["status"] == "PROCESSED" # Idempotent acknowledgment!
