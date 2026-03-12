"""Tests for Overpass adapter retry logic (standalone, no app imports needed)."""

import asyncio
from unittest.mock import AsyncMock, patch

import httpx
import pytest

# Import directly — these don't need FastAPI/pydantic
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent.parent.parent))

from app.services.adapters.osm_overpass import (
    OSMOverpassAdapter,
    MAX_RETRIES,
    RETRY_BASE_DELAY,
)


def _make_response(status_code: int, json_data: dict | None = None) -> httpx.Response:
    if json_data is not None:
        return httpx.Response(
            status_code,
            json=json_data,
            request=httpx.Request("POST", "http://test"),
        )
    return httpx.Response(
        status_code,
        request=httpx.Request("POST", "http://test"),
    )


@pytest.mark.asyncio
@patch("app.services.adapters.osm_overpass.asyncio.sleep", new_callable=AsyncMock)
async def test_retry_on_429_then_succeed(mock_sleep):
    mock_client = AsyncMock()
    mock_client.post = AsyncMock(side_effect=[
        _make_response(429),
        _make_response(200, {"elements": []}),
    ])
    adapter = OSMOverpassAdapter(http_client=mock_client)
    result = await adapter._execute_query("test query")

    assert result == {"elements": []}
    assert mock_sleep.call_count == 1
    mock_sleep.assert_called_with(RETRY_BASE_DELAY)  # 60s


@pytest.mark.asyncio
@patch("app.services.adapters.osm_overpass.asyncio.sleep", new_callable=AsyncMock)
async def test_retry_on_504_then_succeed(mock_sleep):
    mock_client = AsyncMock()
    mock_client.post = AsyncMock(side_effect=[
        _make_response(504),
        _make_response(200, {"elements": [{"type": "node", "id": 1, "lat": 0, "lon": 0, "tags": {}}]}),
    ])
    adapter = OSMOverpassAdapter(http_client=mock_client)
    result = await adapter._execute_query("test query")

    assert len(result["elements"]) == 1
    mock_sleep.assert_called_once_with(RETRY_BASE_DELAY)


@pytest.mark.asyncio
@patch("app.services.adapters.osm_overpass.asyncio.sleep", new_callable=AsyncMock)
async def test_exponential_backoff_delays(mock_sleep):
    """Verify delays are 60s, 120s, 240s for 3 consecutive failures."""
    mock_client = AsyncMock()
    mock_client.post = AsyncMock(side_effect=[
        _make_response(429),
        _make_response(429),
        _make_response(429),
        _make_response(200, {"elements": []}),
    ])
    adapter = OSMOverpassAdapter(http_client=mock_client)
    result = await adapter._execute_query("test query")

    assert result == {"elements": []}
    assert mock_sleep.call_count == 3
    calls = [c.args[0] for c in mock_sleep.call_args_list]
    assert calls == [
        RETRY_BASE_DELAY * 1,  # 60s
        RETRY_BASE_DELAY * 2,  # 120s
        RETRY_BASE_DELAY * 4,  # 240s
    ]


@pytest.mark.asyncio
@patch("app.services.adapters.osm_overpass.asyncio.sleep", new_callable=AsyncMock)
async def test_raises_after_all_retries_exhausted(mock_sleep):
    """After MAX_RETRIES failures, the error is raised."""
    mock_client = AsyncMock()
    mock_client.post = AsyncMock(
        side_effect=[_make_response(429)] * (MAX_RETRIES + 1)
    )
    adapter = OSMOverpassAdapter(http_client=mock_client)

    with pytest.raises(httpx.HTTPStatusError) as exc_info:
        await adapter._execute_query("test query")

    assert exc_info.value.response.status_code == 429
    assert mock_sleep.call_count == MAX_RETRIES


@pytest.mark.asyncio
@patch("app.services.adapters.osm_overpass.asyncio.sleep", new_callable=AsyncMock)
async def test_no_retry_on_non_retryable_errors(mock_sleep):
    """500 and other errors should NOT be retried."""
    mock_client = AsyncMock()
    mock_client.post = AsyncMock(side_effect=[_make_response(500)])
    adapter = OSMOverpassAdapter(http_client=mock_client)

    with pytest.raises(httpx.HTTPStatusError) as exc_info:
        await adapter._execute_query("test query")

    assert exc_info.value.response.status_code == 500
    mock_sleep.assert_not_called()


@pytest.mark.asyncio
@patch("app.services.adapters.osm_overpass.asyncio.sleep", new_callable=AsyncMock)
async def test_retry_mixed_429_and_504(mock_sleep):
    """Both 429 and 504 should be retried."""
    mock_client = AsyncMock()
    mock_client.post = AsyncMock(side_effect=[
        _make_response(429),
        _make_response(504),
        _make_response(200, {"elements": []}),
    ])
    adapter = OSMOverpassAdapter(http_client=mock_client)
    result = await adapter._execute_query("test query")

    assert result == {"elements": []}
    assert mock_sleep.call_count == 2


@pytest.mark.asyncio
@patch("app.services.adapters.osm_overpass.asyncio.sleep", new_callable=AsyncMock)
async def test_success_on_first_attempt_no_retry(mock_sleep):
    """No retries when the first request succeeds."""
    mock_client = AsyncMock()
    mock_client.post = AsyncMock(
        return_value=_make_response(200, {"elements": []})
    )
    adapter = OSMOverpassAdapter(http_client=mock_client)
    result = await adapter._execute_query("test query")

    assert result == {"elements": []}
    mock_sleep.assert_not_called()
    assert mock_client.post.call_count == 1
