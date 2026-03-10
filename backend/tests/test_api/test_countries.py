from unittest.mock import AsyncMock, MagicMock

import pytest
from httpx import ASGITransport, AsyncClient

from app.api.deps import get_db
from app.main import app


def _mock_country(code="IL", name="Israel", name_local="ישראל", speed_unit="kmh", enabled=True):
    c = MagicMock()
    c.code = code
    c.name = name
    c.name_local = name_local
    c.speed_unit = speed_unit
    c.enabled = enabled
    return c


@pytest.fixture
def client():
    return AsyncClient(transport=ASGITransport(app=app), base_url="http://test")


async def test_list_countries_returns_enabled(client):
    countries = [_mock_country()]
    pack_row = MagicMock()
    pack_row.country_code = "IL"
    pack_row.version = 3
    pack_row.camera_count = 148

    mock_session = AsyncMock()
    # First execute: countries query
    mock_countries_result = MagicMock()
    mock_countries_result.scalars.return_value.all.return_value = countries
    # Second execute: packs subquery
    mock_packs_result = MagicMock()
    mock_packs_result.all.return_value = [pack_row]

    mock_session.execute = AsyncMock(
        side_effect=[mock_countries_result, mock_packs_result]
    )

    async def fake_db():
        yield mock_session

    app.dependency_overrides[get_db] = fake_db
    response = await client.get("/api/v1/countries")
    app.dependency_overrides.clear()

    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["code"] == "IL"
    assert data[0]["name"] == "Israel"
    assert data[0]["pack_version"] == 3
    assert data[0]["camera_count"] == 148


async def test_list_countries_empty(client):
    mock_session = AsyncMock()
    mock_countries_result = MagicMock()
    mock_countries_result.scalars.return_value.all.return_value = []
    mock_packs_result = MagicMock()
    mock_packs_result.all.return_value = []

    mock_session.execute = AsyncMock(
        side_effect=[mock_countries_result, mock_packs_result]
    )

    async def fake_db():
        yield mock_session

    app.dependency_overrides[get_db] = fake_db
    response = await client.get("/api/v1/countries")
    app.dependency_overrides.clear()

    assert response.status_code == 200
    assert response.json() == []


async def test_list_countries_without_pack(client):
    countries = [_mock_country(code="DE", name="Germany", name_local="Deutschland")]

    mock_session = AsyncMock()
    mock_countries_result = MagicMock()
    mock_countries_result.scalars.return_value.all.return_value = countries
    mock_packs_result = MagicMock()
    mock_packs_result.all.return_value = []

    mock_session.execute = AsyncMock(
        side_effect=[mock_countries_result, mock_packs_result]
    )

    async def fake_db():
        yield mock_session

    app.dependency_overrides[get_db] = fake_db
    response = await client.get("/api/v1/countries")
    app.dependency_overrides.clear()

    assert response.status_code == 200
    data = response.json()
    assert data[0]["code"] == "DE"
    assert data[0]["pack_version"] is None
    assert data[0]["camera_count"] is None
