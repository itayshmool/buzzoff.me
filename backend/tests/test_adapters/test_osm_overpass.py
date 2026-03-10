import json
from pathlib import Path
from unittest.mock import AsyncMock, patch

import pytest

from app.services.adapters.osm_overpass import OSMOverpassAdapter

FIXTURES = Path(__file__).parent.parent / "fixtures"


@pytest.fixture
def adapter():
    return OSMOverpassAdapter()


@pytest.fixture
def osm_response():
    return json.loads((FIXTURES / "osm_overpass_response.json").read_text())


@pytest.fixture
def config():
    return {
        "query": "[out:json][timeout:60];area['name:en'='Israel']->.a;(node['highway'='speed_camera'](area.a););out body;",
        "type_mapping": {
            "traffic_signals": "red_light",
            "average_speed": "avg_speed_start",
        },
    }


def _mock_query(adapter, response_data):
    adapter._execute_query = AsyncMock(return_value=response_data)


async def test_fetch_parses_nodes_into_records(adapter, config, osm_response):
    _mock_query(adapter, osm_response)
    records = await adapter.fetch(config)
    assert len(records) == 5


async def test_fetch_extracts_lat_lon(adapter, config, osm_response):
    _mock_query(adapter, osm_response)
    records = await adapter.fetch(config)
    assert records[0].lat == 32.2744984
    assert records[0].lon == 34.8533643


async def test_fetch_maps_enforcement_type(adapter, config, osm_response):
    _mock_query(adapter, osm_response)
    records = await adapter.fetch(config)
    # enforcement=traffic_signals → mapped to red_light
    assert records[0].type == "red_light"


async def test_fetch_defaults_to_fixed_speed(adapter, config, osm_response):
    _mock_query(adapter, osm_response)
    records = await adapter.fetch(config)
    # No enforcement tag → default fixed_speed
    assert records[1].type == "fixed_speed"


async def test_fetch_extracts_maxspeed(adapter, config, osm_response):
    _mock_query(adapter, osm_response)
    records = await adapter.fetch(config)
    assert records[2].speed_limit == 50
    assert records[1].speed_limit is None


async def test_fetch_extracts_direction_as_heading(adapter, config, osm_response):
    _mock_query(adapter, osm_response)
    records = await adapter.fetch(config)
    # direction=180
    assert records[4].heading == 180.0
    assert records[0].heading is None


async def test_fetch_sets_external_id_from_osm_id(adapter, config, osm_response):
    _mock_query(adapter, osm_response)
    records = await adapter.fetch(config)
    assert records[0].external_id == "osm:452459007"


async def test_fetch_stores_raw_data(adapter, config, osm_response):
    _mock_query(adapter, osm_response)
    records = await adapter.fetch(config)
    assert records[0].raw_data is not None
    assert records[0].raw_data["id"] == 452459007


async def test_fetch_raises_on_api_error(adapter, config):
    adapter._execute_query = AsyncMock(side_effect=Exception("HTTP 500"))
    with pytest.raises(Exception, match="HTTP 500"):
        await adapter.fetch(config)


async def test_fetch_handles_empty_response(adapter, config):
    _mock_query(adapter, {"version": 0.6, "elements": []})
    records = await adapter.fetch(config)
    assert records == []


async def test_fetch_ignores_non_node_elements(adapter, config):
    _mock_query(adapter, {
        "elements": [
            {"type": "way", "id": 1, "tags": {"highway": "speed_camera"}},
            {"type": "node", "id": 2, "lat": 31.0, "lon": 34.0, "tags": {"highway": "speed_camera"}},
        ]
    })
    records = await adapter.fetch(config)
    assert len(records) == 1
    assert records[0].external_id == "osm:2"
