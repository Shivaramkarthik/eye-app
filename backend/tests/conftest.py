import sys
import os
os.environ["DATABASE_URL"] = "sqlite+aiosqlite:///:memory:"
os.environ["SYNC_DATABASE_URL"] = "sqlite:///:memory:"
os.environ["ENVIRONMENT"] = "testing"
os.environ["TESTING"] = "1"
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

import pytest
import asyncio
from typing import AsyncGenerator
from unittest.mock import patch, MagicMock
from httpx import AsyncClient, ASGITransport
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker
from sqlalchemy.pool import StaticPool

from app.database.session import Base, get_db
from app.main import app


# Test Async Engine using SQLite in-memory for fast CI execution
TEST_DATABASE_URL = "sqlite+aiosqlite:///:memory:"

test_engine = create_async_engine(
    TEST_DATABASE_URL,
    connect_args={"check_same_thread": False},
    poolclass=StaticPool,
)

TestingSessionLocal = async_sessionmaker(
    bind=test_engine,
    class_=AsyncSession,
    expire_on_commit=False,
    autocommit=False,
    autoflush=False
)

@pytest.fixture(scope="session")
def event_loop():
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()

import pytest_asyncio

@pytest_asyncio.fixture(autouse=True)
async def init_test_db():
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)
    yield
    async with test_engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)

async def override_get_db() -> AsyncGenerator[AsyncSession, None]:
    async with TestingSessionLocal() as session:
        yield session

app.dependency_overrides[get_db] = override_get_db

@pytest_asyncio.fixture
async def client() -> AsyncGenerator[AsyncClient, None]:
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://testserver") as ac:
        yield ac


def make_google_payload(
    sub: str = "google_user_12345",
    email: str = "testuser@gmail.com",
    name: str = "Test User",
    picture: str = "https://lh3.googleusercontent.com/photo.jpg",
    email_verified: bool = True,
    iss: str = "accounts.google.com",
):
    """Creates a mock Google ID token payload for testing."""
    return {
        "iss": iss,
        "sub": sub,
        "email": email,
        "email_verified": email_verified,
        "name": name,
        "picture": picture,
        "aud": "test_client_id",
        "iat": 1700000000,
        "exp": 1700003600,
    }


@pytest.fixture
def mock_google_verify():
    """Patches Google token verification to return a controlled payload.
    
    Usage in tests:
        def test_example(mock_google_verify):
            mock_google_verify.return_value = make_google_payload(email="custom@test.com")
    """
    with patch("app.core.security.id_token.verify_oauth2_token") as mock:
        mock.return_value = make_google_payload()
        yield mock
