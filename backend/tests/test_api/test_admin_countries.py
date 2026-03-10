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


def _mock_country(code="IL", name="Israel", name_local="ישראל", speed_unit="kmh", enabled=True):
    c = MagicMock()
    c.code = code
    c.name = name
    c.name_local = name_local
    c.speed_unit = speed_unit
    c.enabled = enabled
    return c


async def test_list_countries(client, auth_header):
    countries = [_mock_country(), _mock_country(code="DE", name="Germany", name_local="Deutschland")]

    mock_session = AsyncMock()
    mock_result = MagicMock()
    mock_result.scalars.return_value.all.return_value = countries
    mock_session.execute = AsyncMock(return_value=mock_result)

    async def fake_db():
        yield mock_session

    app.dependency_overrides[get_db] = fake_db
    response = await client.get("/admin/api/countries", headers=auth_header)
    app.dependency_overrides.clear()

    assert response.status_code == 200
    data = response.json()
    assert len(data) == 2
    assert data[0]["code"] == "IL"
    assert data[1]["code"] == "DE"


async def test_create_country(client, auth_header):
    mock_session = AsyncMock()
    mock_session.execute = AsyncMock(return_value=MagicMock(scalar_one_or_none=MagicMock(return_value=None)))

    async def fake_db():
        yield mock_session

    app.dependency_overrides[get_db] = fake_db
    response = await client.post(
        "/admin/api/countries",
        json={"code": "DE", "name": "Germany", "speed_unit": "kmh"},
        headers=auth_header,
    )
    app.dependency_overrides.clear()

    assert response.status_code == 201
    data = response.json()
    assert data["code"] == "DE"
    assert data["name"] == "Germany"
    mock_session.add.assert_called_once()
    mock_session.commit.assert_awaited_once()


async def test_create_country_duplicate(client, auth_header):
    existing = _mock_country(code="IL")

    mock_session = AsyncMock()
    mock_session.execute = AsyncMock(return_value=MagicMock(scalar_one_or_none=MagicMock(return_value=existing)))

    async def fake_db():
        yield mock_session

    app.dependency_overrides[get_db] = fake_db
    response = await client.post(
        "/admin/api/countries",
        json={"code": "IL", "name": "Israel", "speed_unit": "kmh"},
        headers=auth_header,
    )
    app.dependency_overrides.clear()

    assert response.status_code == 409


async def test_update_country(client, auth_header):
    existing = _mock_country(code="IL")

    mock_session = AsyncMock()
    mock_session.execute = AsyncMock(return_value=MagicMock(scalar_one_or_none=MagicMock(return_value=existing)))

    async def fake_db():
        yield mock_session

    app.dependency_overrides[get_db] = fake_db
    response = await client.put(
        "/admin/api/countries/IL",
        json={"name": "Israel Updated"},
        headers=auth_header,
    )
    app.dependency_overrides.clear()

    assert response.status_code == 200
    assert existing.name == "Israel Updated"
    mock_session.commit.assert_awaited_once()


async def test_update_country_not_found(client, auth_header):
    mock_session = AsyncMock()
    mock_session.execute = AsyncMock(return_value=MagicMock(scalar_one_or_none=MagicMock(return_value=None)))

    async def fake_db():
        yield mock_session

    app.dependency_overrides[get_db] = fake_db
    response = await client.put(
        "/admin/api/countries/XX",
        json={"name": "Unknown"},
        headers=auth_header,
    )
    app.dependency_overrides.clear()

    assert response.status_code == 404


async def test_delete_country(client, auth_header):
    existing = _mock_country(code="IL")

    mock_session = AsyncMock()
    mock_session.execute = AsyncMock(return_value=MagicMock(scalar_one_or_none=MagicMock(return_value=existing)))

    async def fake_db():
        yield mock_session

    app.dependency_overrides[get_db] = fake_db
    response = await client.delete("/admin/api/countries/IL", headers=auth_header)
    app.dependency_overrides.clear()

    assert response.status_code == 204
    mock_session.delete.assert_awaited_once_with(existing)
    mock_session.commit.assert_awaited_once()


async def test_delete_country_not_found(client, auth_header):
    mock_session = AsyncMock()
    mock_session.execute = AsyncMock(return_value=MagicMock(scalar_one_or_none=MagicMock(return_value=None)))

    async def fake_db():
        yield mock_session

    app.dependency_overrides[get_db] = fake_db
    response = await client.delete("/admin/api/countries/XX", headers=auth_header)
    app.dependency_overrides.clear()

    assert response.status_code == 404
