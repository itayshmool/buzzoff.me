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


SOURCE_ID = uuid.uuid4()


def _mock_source(
    id=SOURCE_ID,
    country_code="IL",
    name="OSM Israel",
    adapter="osm_overpass",
    config=None,
    schedule=None,
    confidence=0.7,
    enabled=True,
):
    s = MagicMock()
    s.id = id
    s.country_code = country_code
    s.name = name
    s.adapter = adapter
    s.config = config or {"country_code": "IL"}
    s.schedule = schedule
    s.confidence = confidence
    s.enabled = enabled
    return s


async def test_list_sources(client, auth_header):
    sources = [_mock_source()]

    mock_session = AsyncMock()
    mock_result = MagicMock()
    mock_result.scalars.return_value.all.return_value = sources
    mock_session.execute = AsyncMock(return_value=mock_result)

    async def fake_db():
        yield mock_session

    app.dependency_overrides[get_db] = fake_db
    response = await client.get("/admin/api/countries/IL/sources", headers=auth_header)
    app.dependency_overrides.clear()

    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["name"] == "OSM Israel"
    assert data[0]["adapter"] == "osm_overpass"


async def test_create_source(client, auth_header):
    mock_session = AsyncMock()
    # Country lookup returns a country
    mock_country_result = MagicMock()
    mock_country_result.scalar_one_or_none.return_value = MagicMock(code="IL")
    mock_session.execute = AsyncMock(return_value=mock_country_result)

    async def fake_db():
        yield mock_session

    app.dependency_overrides[get_db] = fake_db
    response = await client.post(
        "/admin/api/countries/IL/sources",
        json={
            "name": "New CSV Source",
            "adapter": "csv",
            "config": {"url": "https://example.com/data.csv"},
            "confidence": 0.6,
        },
        headers=auth_header,
    )
    app.dependency_overrides.clear()

    assert response.status_code == 201
    data = response.json()
    assert data["name"] == "New CSV Source"
    assert data["adapter"] == "csv"
    mock_session.add.assert_called_once()
    mock_session.commit.assert_awaited_once()


async def test_create_source_country_not_found(client, auth_header):
    mock_session = AsyncMock()
    mock_result = MagicMock()
    mock_result.scalar_one_or_none.return_value = None
    mock_session.execute = AsyncMock(return_value=mock_result)

    async def fake_db():
        yield mock_session

    app.dependency_overrides[get_db] = fake_db
    response = await client.post(
        "/admin/api/countries/XX/sources",
        json={"name": "Test", "adapter": "csv", "config": {}},
        headers=auth_header,
    )
    app.dependency_overrides.clear()

    assert response.status_code == 404


async def test_update_source(client, auth_header):
    source = _mock_source()

    mock_session = AsyncMock()
    mock_result = MagicMock()
    mock_result.scalar_one_or_none.return_value = source
    mock_session.execute = AsyncMock(return_value=mock_result)

    async def fake_db():
        yield mock_session

    app.dependency_overrides[get_db] = fake_db
    response = await client.put(
        f"/admin/api/sources/{SOURCE_ID}",
        json={"name": "Updated Name", "enabled": False},
        headers=auth_header,
    )
    app.dependency_overrides.clear()

    assert response.status_code == 200
    assert source.name == "Updated Name"
    assert source.enabled is False
    mock_session.commit.assert_awaited_once()


async def test_update_source_not_found(client, auth_header):
    mock_session = AsyncMock()
    mock_result = MagicMock()
    mock_result.scalar_one_or_none.return_value = None
    mock_session.execute = AsyncMock(return_value=mock_result)

    async def fake_db():
        yield mock_session

    app.dependency_overrides[get_db] = fake_db
    response = await client.put(
        f"/admin/api/sources/{uuid.uuid4()}",
        json={"name": "Updated"},
        headers=auth_header,
    )
    app.dependency_overrides.clear()

    assert response.status_code == 404


async def test_delete_source(client, auth_header):
    source = _mock_source()

    mock_session = AsyncMock()
    mock_result = MagicMock()
    mock_result.scalar_one_or_none.return_value = source
    mock_session.execute = AsyncMock(return_value=mock_result)

    async def fake_db():
        yield mock_session

    app.dependency_overrides[get_db] = fake_db
    response = await client.delete(f"/admin/api/sources/{SOURCE_ID}", headers=auth_header)
    app.dependency_overrides.clear()

    assert response.status_code == 204
    mock_session.delete.assert_awaited_once_with(source)
    mock_session.commit.assert_awaited_once()


async def test_delete_source_not_found(client, auth_header):
    mock_session = AsyncMock()
    mock_result = MagicMock()
    mock_result.scalar_one_or_none.return_value = None
    mock_session.execute = AsyncMock(return_value=mock_result)

    async def fake_db():
        yield mock_session

    app.dependency_overrides[get_db] = fake_db
    response = await client.delete(f"/admin/api/sources/{uuid.uuid4()}", headers=auth_header)
    app.dependency_overrides.clear()

    assert response.status_code == 404
