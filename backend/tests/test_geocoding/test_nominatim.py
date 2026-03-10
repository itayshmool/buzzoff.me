from unittest.mock import AsyncMock, MagicMock

import pytest

from app.services.geocoding.nominatim import NominatimGeocoder


@pytest.fixture
def geocoder():
    return NominatimGeocoder(user_agent="test-agent")


def _mock_response(json_data, status_code=200):
    response = MagicMock()
    response.status_code = status_code
    response.json.return_value = json_data
    response.raise_for_status = MagicMock()
    return response


async def test_geocode_returns_lat_lon(geocoder):
    geocoder._client = AsyncMock()
    geocoder._client.get = AsyncMock(return_value=_mock_response([
        {"lat": "32.0853", "lon": "34.7818", "display_name": "Tel Aviv"}
    ]))
    result = await geocoder.geocode("Tel Aviv, Israel")
    assert result is not None
    assert result.lat == pytest.approx(32.0853)
    assert result.lon == pytest.approx(34.7818)
    assert result.provider == "nominatim"


async def test_geocode_returns_none_on_empty_results(geocoder):
    geocoder._client = AsyncMock()
    geocoder._client.get = AsyncMock(return_value=_mock_response([]))
    result = await geocoder.geocode("nonexistent address xyz123")
    assert result is None


async def test_geocode_returns_none_on_http_error(geocoder):
    geocoder._client = AsyncMock()
    geocoder._client.get = AsyncMock(side_effect=Exception("HTTP 500"))
    result = await geocoder.geocode("Tel Aviv")
    assert result is None


async def test_geocode_passes_correct_params(geocoder):
    geocoder._client = AsyncMock()
    geocoder._client.get = AsyncMock(return_value=_mock_response([
        {"lat": "32.0", "lon": "34.0", "display_name": "Test"}
    ]))
    await geocoder.geocode("Main St, Tel Aviv")
    geocoder._client.get.assert_called_once()
    call_kwargs = geocoder._client.get.call_args
    params = call_kwargs.kwargs.get("params") or call_kwargs[1].get("params")
    assert params["q"] == "Main St, Tel Aviv"
    assert params["format"] == "json"
    assert params["limit"] == 1
