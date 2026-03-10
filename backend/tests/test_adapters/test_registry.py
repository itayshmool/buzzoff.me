import pytest

from app.services.adapters.registry import get_adapter
from app.services.adapters.csv_adapter import CSVAdapter
from app.services.adapters.excel_adapter import ExcelAdapter
from app.services.adapters.osm_overpass import OSMOverpassAdapter


def test_get_csv_adapter():
    adapter = get_adapter("csv")
    assert isinstance(adapter, CSVAdapter)


def test_get_excel_adapter():
    adapter = get_adapter("excel")
    assert isinstance(adapter, ExcelAdapter)


def test_get_osm_overpass_adapter():
    adapter = get_adapter("osm_overpass")
    assert isinstance(adapter, OSMOverpassAdapter)


def test_get_unknown_adapter_raises():
    with pytest.raises(ValueError, match="Unknown adapter"):
        get_adapter("nonexistent")
