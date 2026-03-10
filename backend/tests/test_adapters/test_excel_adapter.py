from pathlib import Path

import pytest

from app.services.adapters.excel_adapter import ExcelAdapter

FIXTURES = Path(__file__).parent.parent / "fixtures"


@pytest.fixture
def adapter():
    return ExcelAdapter()


@pytest.fixture
def config():
    return {
        "file_path": str(FIXTURES / "sample_cameras.xlsx"),
        "column_mapping": {
            "lat": "lat",
            "lon": "lon",
            "type": "type",
            "speed_limit": "speed_limit",
            "heading": "heading",
            "address": "address",
            "external_id": "external_id",
        },
    }


async def test_fetch_parses_all_rows(adapter, config):
    records = await adapter.fetch(config)
    assert len(records) == 3


async def test_fetch_extracts_lat_lon(adapter, config):
    records = await adapter.fetch(config)
    assert records[0].lat == 32.2744984
    assert records[0].lon == 34.8533643


async def test_fetch_extracts_type(adapter, config):
    records = await adapter.fetch(config)
    assert records[0].type == "red_light"


async def test_fetch_defaults_type_to_fixed_speed(adapter, config):
    records = await adapter.fetch(config)
    # Row 3 has None type
    assert records[2].type == "fixed_speed"


async def test_fetch_extracts_speed_limit(adapter, config):
    records = await adapter.fetch(config)
    assert records[0].speed_limit == 60
    assert records[1].speed_limit is None


async def test_fetch_extracts_heading(adapter, config):
    records = await adapter.fetch(config)
    assert records[0].heading == 90.0
    assert records[1].heading is None


async def test_fetch_extracts_address(adapter, config):
    records = await adapter.fetch(config)
    assert records[2].address == "Main St Beer Sheva"
    assert records[0].address is None


async def test_fetch_extracts_external_id(adapter, config):
    records = await adapter.fetch(config)
    assert records[0].external_id == "XLS-001"


async def test_fetch_stores_raw_data(adapter, config):
    records = await adapter.fetch(config)
    assert records[0].raw_data is not None
    assert records[0].raw_data["lat"] == 32.2744984


async def test_fetch_custom_column_mapping(adapter):
    config = {
        "file_path": str(FIXTURES / "sample_cameras_custom.xlsx"),
        "column_mapping": {
            "lat": "latitude",
            "lon": "longitude",
            "type": "camera_type",
            "speed_limit": "max_speed",
            "external_id": "id",
        },
    }
    records = await adapter.fetch(config)
    assert len(records) == 2
    assert records[0].lat == 32.0
    assert records[0].lon == 34.0
    assert records[0].type == "red_light"
    assert records[0].speed_limit == 50
    assert records[0].external_id == "ID-1"


async def test_fetch_raises_on_missing_file(adapter):
    config = {"file_path": "/nonexistent/file.xlsx", "column_mapping": {"lat": "lat", "lon": "lon"}}
    with pytest.raises(FileNotFoundError):
        await adapter.fetch(config)


async def test_fetch_handles_empty_file(adapter):
    config = {
        "file_path": str(FIXTURES / "empty_cameras.xlsx"),
        "column_mapping": {"lat": "lat", "lon": "lon"},
    }
    records = await adapter.fetch(config)
    assert records == []
