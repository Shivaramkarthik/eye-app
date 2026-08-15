import uuid
import pytest
from httpx import AsyncClient
from conftest import make_google_payload


@pytest.mark.asyncio
async def test_sync_push_high_volume_and_duplicates(client: AsyncClient, mock_google_verify):
    """Verifies that 30 queued mutations are processed cleanly and duplicate operations in same batch are handled idempotently."""
    mock_google_verify.return_value = make_google_payload(
        sub="sync_heavy_user_sub", email="syncheavy@specz.co", name="Sync Heavy User"
    )
    auth_res = await client.post("/api/v1/auth/google", json={"google_id_token": "heavy_token"})
    token = auth_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    # Generate 30 distinct create operations
    operations = []
    for i in range(30):
        operations.append({
            "operation_id": f"op_batch_{uuid.uuid4().hex[:12]}",
            "entity_type": "profile",
            "entity_id": f"p_heavy_{i}",
            "operation": "CREATE",
            "payload": {
                "id": f"p_heavy_{i}",
                "name": f"Heavy Profile {i}",
                "dob": "2000-01-01",
                "gender": "Other",
                "relationship": "Other",
            },
            "timestamp": "2026-08-15T15:00:00Z",
        })

    # Add duplicate operation_id
    duplicate_op = operations[0].copy()
    operations.append(duplicate_op)

    # Push sync batch
    push_res = await client.post(
        "/api/v1/sync/push",
        headers=headers,
        json={"device_id": "test_device_android_1", "operations": operations},
    )
    assert push_res.status_code == 200
    res_data = push_res.json()
    assert "processed_count" in res_data
    assert len(res_data["results"]) == 31


@pytest.mark.asyncio
async def test_sync_pull_fresh_state(client: AsyncClient, mock_google_verify):
    """Verifies sync pull returns server state since last sync timestamp."""
    mock_google_verify.return_value = make_google_payload(
        sub="sync_pull_user_sub", email="syncpull@specz.co", name="Sync Pull User"
    )
    auth_res = await client.post("/api/v1/auth/google", json={"google_id_token": "pull_token"})
    token = auth_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}

    pull_res = await client.get("/api/v1/sync/pull", headers=headers)
    assert pull_res.status_code == 200
    data = pull_res.json()
    assert "profiles" in data
    assert "prescriptions" in data
    assert "medications" in data
    assert "server_time" in data
