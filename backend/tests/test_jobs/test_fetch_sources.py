import uuid
from unittest.mock import AsyncMock, MagicMock, patch

import pytest

from app.services.adapters.base import RawCameraRecord


async def test_fetch_all_sources_processes_enabled_sources():
    mock_source = MagicMock()
    mock_source.id = uuid.uuid4()
    mock_source.name = "Test OSM"
    mock_source.adapter = "osm_overpass"
    mock_source.country_code = "IL"
    mock_source.config = {"query": "test", "type_mapping": {}}
    mock_source.enabled = True

    mock_records = [
        RawCameraRecord(lat=32.0, lon=34.0, type="fixed_speed", external_id="osm:1"),
    ]

    mock_session = AsyncMock()
    mock_result = MagicMock()
    mock_result.scalars.return_value.all.return_value = [mock_source]
    mock_session.execute = AsyncMock(return_value=mock_result)
    mock_session.add = MagicMock()
    mock_session.commit = AsyncMock()

    with (
        patch("jobs.fetch_sources.async_session_factory") as mock_factory,
        patch("jobs.fetch_sources.get_adapter") as mock_get_adapter,
    ):
        mock_factory.return_value.__aenter__ = AsyncMock(return_value=mock_session)
        mock_factory.return_value.__aexit__ = AsyncMock(return_value=False)

        mock_adapter = AsyncMock()
        mock_adapter.fetch = AsyncMock(return_value=mock_records)
        mock_get_adapter.return_value = mock_adapter

        from jobs.fetch_sources import fetch_all_sources
        await fetch_all_sources()

        mock_get_adapter.assert_called_once_with("osm_overpass")
        mock_adapter.fetch.assert_called_once()
        mock_session.add.assert_called_once()
        mock_session.commit.assert_called()
