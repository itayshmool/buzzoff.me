from unittest.mock import AsyncMock, MagicMock

import pytest
from httpx import ASGITransport, AsyncClient

from app.api.deps import get_db
from app.main import app


@pytest.fixture
def client():
    return AsyncClient(transport=ASGITransport(app=app), base_url="http://test")


@pytest.fixture
async def auth_header(client):
    response = await client.post(
        "/admin/api/auth/login",
        json={"username": "admin", "password": "changeme"},
    )
    token = response.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


async def test_dashboard_stats(client, auth_header):
    mock_session = AsyncMock()

    # Countries count
    mock_countries = MagicMock()
    mock_countries.scalar.return_value = 2
    # Sources count
    mock_sources = MagicMock()
    mock_sources.scalar.return_value = 5
    # Cameras count
    mock_cameras = MagicMock()
    mock_cameras.scalar.return_value = 148
    # Packs count
    mock_packs = MagicMock()
    mock_packs.scalar.return_value = 3

    mock_session.execute = AsyncMock(
        side_effect=[mock_countries, mock_sources, mock_cameras, mock_packs]
    )

    async def fake_db():
        yield mock_session

    app.dependency_overrides[get_db] = fake_db
    response = await client.get("/admin/api/dashboard/stats", headers=auth_header)
    app.dependency_overrides.clear()

    assert response.status_code == 200
    data = response.json()
    assert data["countries"] == 2
    assert data["sources"] == 5
    assert data["cameras"] == 148
    assert data["packs"] == 3
