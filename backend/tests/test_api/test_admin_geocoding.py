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


def _mock_raw_camera(
    id=None,
    address="123 Main St, Tel Aviv",
    lat=None,
    lon=None,
    geocode_failed=False,
    country_code="IL",
):
    c = MagicMock()
    c.id = id or uuid.uuid4()
    c.address = address
    c.lat = lat
    c.lon = lon
    c.geocode_failed = geocode_failed
    c.geocoded = lat is not None
    c.country_code = country_code
    c.type = "fixed_speed"
    return c


async def test_geocoding_queue(client, auth_header):
    pending = [_mock_raw_camera(), _mock_raw_camera(address="456 Oak Ave")]

    mock_session = AsyncMock()
    mock_result = MagicMock()
    mock_result.scalars.return_value.all.return_value = pending
    mock_session.execute = AsyncMock(return_value=mock_result)

    async def fake_db():
        yield mock_session

    app.dependency_overrides[get_db] = fake_db
    response = await client.get("/admin/api/geocoding/queue", headers=auth_header)
    app.dependency_overrides.clear()

    assert response.status_code == 200
    data = response.json()
    assert len(data) == 2


async def test_geocoding_failed(client, auth_header):
    failed = [_mock_raw_camera(geocode_failed=True)]

    mock_session = AsyncMock()
    mock_result = MagicMock()
    mock_result.scalars.return_value.all.return_value = failed
    mock_session.execute = AsyncMock(return_value=mock_result)

    async def fake_db():
        yield mock_session

    app.dependency_overrides[get_db] = fake_db
    response = await client.get("/admin/api/geocoding/failed", headers=auth_header)
    app.dependency_overrides.clear()

    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1


async def test_resolve_geocoding(client, auth_header):
    raw = _mock_raw_camera()
    cam_id = raw.id

    mock_session = AsyncMock()
    mock_result = MagicMock()
    mock_result.scalar_one_or_none.return_value = raw
    mock_session.execute = AsyncMock(return_value=mock_result)

    async def fake_db():
        yield mock_session

    app.dependency_overrides[get_db] = fake_db
    response = await client.put(
        f"/admin/api/geocoding/{cam_id}/resolve",
        json={"lat": 32.0853, "lon": 34.7818},
        headers=auth_header,
    )
    app.dependency_overrides.clear()

    assert response.status_code == 200
    assert raw.lat == 32.0853
    assert raw.lon == 34.7818
    assert raw.geocoded is True
    assert raw.geocode_failed is False
    mock_session.commit.assert_awaited_once()


async def test_resolve_geocoding_not_found(client, auth_header):
    mock_session = AsyncMock()
    mock_result = MagicMock()
    mock_result.scalar_one_or_none.return_value = None
    mock_session.execute = AsyncMock(return_value=mock_result)

    async def fake_db():
        yield mock_session

    app.dependency_overrides[get_db] = fake_db
    response = await client.put(
        f"/admin/api/geocoding/{uuid.uuid4()}/resolve",
        json={"lat": 32.0, "lon": 34.0},
        headers=auth_header,
    )
    app.dependency_overrides.clear()

    assert response.status_code == 404
