import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_health_check(client: AsyncClient):
    response = await client.get("/health")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert data["service"] == "specz-api"
    # Verify X-Request-ID header attached by middleware
    assert "X-Request-ID" in response.headers


@pytest.mark.asyncio
async def test_health_ready(client: AsyncClient):
    response = await client.get("/health/ready")
    assert response.status_code == 200
    data = response.json()
    assert data["status"] == "ok"
    assert "dependencies" in data
    assert data["dependencies"]["database"] == "ok"


@pytest.mark.asyncio
async def test_feature_flags_endpoint(client: AsyncClient):
    response = await client.get("/api/v1/config/feature-flags")
    assert response.status_code == 200
    data = response.json()
    assert "ocr_enabled" in data
    assert "ai_enabled" in data
    assert "pdf_export_enabled" in data
    assert "plus_enabled" in data
    assert "sync_enabled" in data
    assert data["ocr_enabled"] is True


@pytest.mark.asyncio
async def test_custom_request_id_propagated(client: AsyncClient):
    custom_req_id = "test_custom_req_id_9999"
    response = await client.get("/health", headers={"X-Request-ID": custom_req_id})
    assert response.status_code == 200
    assert response.headers["X-Request-ID"] == custom_req_id


@pytest.mark.asyncio
async def test_oversized_payload_rejected(client: AsyncClient):
    # Simulated 20MB content-length header
    fake_large_size = str(20 * 1024 * 1024)
    response = await client.post(
        "/api/v1/ai/ocr-prescription",
        headers={"Content-Length": fake_large_size, "Content-Type": "application/json"},
        content=b"{}",
    )
    assert response.status_code == 413
    data = response.json()
    assert data["error"]["code"] == "PAYLOAD_TOO_LARGE"
