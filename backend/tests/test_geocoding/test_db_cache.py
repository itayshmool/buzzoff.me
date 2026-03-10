from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from app.services.geocoding.db_cache import DbGeocodeCache
from app.services.geocoding.service import GeocodingResult, GeocodingService


@pytest.fixture
def mock_session():
    session = AsyncMock()
    session.execute = AsyncMock()
    return session


@pytest.fixture
def cache(mock_session):
    return DbGeocodeCache(session=mock_session)


async def test_get_returns_none_on_cache_miss(cache, mock_session):
    mock_result = MagicMock()
    mock_result.scalar_one_or_none.return_value = None
    mock_session.execute.return_value = mock_result
    result = await cache.get("Tel Aviv")
    assert result is None


async def test_get_returns_result_on_cache_hit(cache, mock_session):
    mock_row = MagicMock()
    mock_row.lat = 32.0
    mock_row.lon = 34.0
    mock_row.provider = "nominatim"
    mock_result = MagicMock()
    mock_result.scalar_one_or_none.return_value = mock_row
    mock_session.execute.return_value = mock_result
    result = await cache.get("Tel Aviv")
    assert result is not None
    assert result.lat == 32.0
    assert result.lon == 34.0
    assert result.provider == "nominatim"


async def test_put_stores_result(cache, mock_session):
    result = GeocodingResult(lat=32.0, lon=34.0, provider="nominatim")
    await cache.put("Tel Aviv", result)
    mock_session.execute.assert_called_once()
    mock_session.commit.assert_called_once()


async def test_address_hash_is_deterministic(cache):
    h1 = GeocodingService.address_hash("Tel Aviv")
    h2 = GeocodingService.address_hash("Tel Aviv")
    assert h1 == h2


async def test_address_hash_normalizes_case_and_whitespace(cache):
    h1 = GeocodingService.address_hash("Tel Aviv")
    h2 = GeocodingService.address_hash("  tel  aviv  ")
    assert h1 == h2
