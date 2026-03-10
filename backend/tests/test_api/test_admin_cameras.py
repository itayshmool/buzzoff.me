import uuid
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


def _mock_camera(
    id=None,
    country_code="IL",
    lat=32.0853,
    lon=34.7818,
    type="fixed_speed",
    speed_limit=90,
    heading=180.0,
    road_name="Highway 1",
    confidence=0.8,
):
    c = MagicMock()
    c.id = id or uuid.uuid4()
    c.country_code = country_code
    c.lat = lat
    c.lon = lon
    c.type = type
    c.speed_limit = speed_limit
    c.heading = heading
    c.road_name = road_name
    c.confidence = confidence
    return c


async def test_list_cameras(client, auth_header):
    cameras = [_mock_camera(), _mock_camera(type="red_light")]

    mock_session = AsyncMock()
    # Count query
    mock_count_result = MagicMock()
    mock_count_result.scalar.return_value = 2
    # Camera list query
    mock_list_result = MagicMock()
    mock_list_result.all.return_value = cameras
    mock_session.execute = AsyncMock(side_effect=[mock_count_result, mock_list_result])

    async def fake_db():
        yield mock_session

    app.dependency_overrides[get_db] = fake_db
    response = await client.get("/admin/api/countries/IL/cameras", headers=auth_header)
    app.dependency_overrides.clear()

    assert response.status_code == 200
    data = response.json()
    assert data["total"] == 2
    assert len(data["items"]) == 2


async def test_list_cameras_pagination(client, auth_header):
    cameras = [_mock_camera()]

    mock_session = AsyncMock()
    mock_count_result = MagicMock()
    mock_count_result.scalar.return_value = 50
    mock_list_result = MagicMock()
    mock_list_result.all.return_value = cameras
    mock_session.execute = AsyncMock(side_effect=[mock_count_result, mock_list_result])

    async def fake_db():
        yield mock_session

    app.dependency_overrides[get_db] = fake_db
    response = await client.get(
        "/admin/api/countries/IL/cameras?limit=1&offset=0",
        headers=auth_header,
    )
    app.dependency_overrides.clear()

    assert response.status_code == 200
    data = response.json()
    assert data["total"] == 50


async def test_cameras_stats(client, auth_header):
    mock_session = AsyncMock()
    mock_result = MagicMock()
    # Stats returns rows of (type, count)
    mock_result.all.return_value = [
        MagicMock(type="fixed_speed", count=69),
        MagicMock(type="red_light", count=78),
    ]
    mock_session.execute = AsyncMock(return_value=mock_result)

    async def fake_db():
        yield mock_session

    app.dependency_overrides[get_db] = fake_db
    response = await client.get(
        "/admin/api/countries/IL/cameras/stats", headers=auth_header
    )
    app.dependency_overrides.clear()

    assert response.status_code == 200
    data = response.json()
    assert data["total"] == 147
    assert data["by_type"]["fixed_speed"] == 69
    assert data["by_type"]["red_light"] == 78
