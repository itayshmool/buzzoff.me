from unittest.mock import AsyncMock

import pytest

from app.services.geocoding.service import GeocodingService, GeocodingResult


@pytest.fixture
def mock_cache():
    cache = AsyncMock()
    cache.get = AsyncMock(return_value=None)
    cache.put = AsyncMock()
    return cache


@pytest.fixture
def mock_nominatim():
    return AsyncMock()


@pytest.fixture
def service(mock_cache, mock_nominatim):
    return GeocodingService(cache=mock_cache, nominatim=mock_nominatim)


async def test_returns_cached_result(service, mock_cache):
    cached = GeocodingResult(lat=32.0, lon=34.0, provider="nominatim")
    mock_cache.get = AsyncMock(return_value=cached)
    result = await service.geocode("Tel Aviv")
    assert result == cached
    # Should not call nominatim when cache hits
    service._nominatim.geocode.assert_not_called()


async def test_calls_nominatim_on_cache_miss(service, mock_nominatim):
    nominatim_result = GeocodingResult(lat=32.0, lon=34.0, provider="nominatim")
    mock_nominatim.geocode = AsyncMock(return_value=nominatim_result)
    result = await service.geocode("Tel Aviv")
    assert result == nominatim_result
    mock_nominatim.geocode.assert_called_once_with("Tel Aviv")


async def test_caches_nominatim_result(service, mock_cache, mock_nominatim):
    nominatim_result = GeocodingResult(lat=32.0, lon=34.0, provider="nominatim")
    mock_nominatim.geocode = AsyncMock(return_value=nominatim_result)
    await service.geocode("Tel Aviv")
    mock_cache.put.assert_called_once_with("Tel Aviv", nominatim_result)


async def test_returns_none_when_all_providers_fail(service, mock_nominatim):
    mock_nominatim.geocode = AsyncMock(return_value=None)
    result = await service.geocode("unknown place")
    assert result is None


async def test_does_not_cache_failures(service, mock_cache, mock_nominatim):
    mock_nominatim.geocode = AsyncMock(return_value=None)
    await service.geocode("unknown place")
    mock_cache.put.assert_not_called()


async def test_normalizes_address_whitespace(service, mock_nominatim):
    nominatim_result = GeocodingResult(lat=32.0, lon=34.0, provider="nominatim")
    mock_nominatim.geocode = AsyncMock(return_value=nominatim_result)
    await service.geocode("  Tel  Aviv  ")
    mock_nominatim.geocode.assert_called_once_with("Tel Aviv")


async def test_batch_geocode(service, mock_nominatim):
    mock_nominatim.geocode = AsyncMock(
        side_effect=[
            GeocodingResult(lat=32.0, lon=34.0, provider="nominatim"),
            None,
            GeocodingResult(lat=31.0, lon=35.0, provider="nominatim"),
        ]
    )
    results = await service.batch_geocode(["Tel Aviv", "Unknown", "Jerusalem"])
    assert len(results) == 3
    assert results[0] is not None
    assert results[1] is None
    assert results[2] is not None
