from app.services.adapters.base import SourceAdapter
from app.services.adapters.csv_adapter import CSVAdapter
from app.services.adapters.excel_adapter import ExcelAdapter
from app.services.adapters.osm_overpass import OSMOverpassAdapter

ADAPTERS: dict[str, type[SourceAdapter]] = {
    "csv": CSVAdapter,
    "excel": ExcelAdapter,
    "osm_overpass": OSMOverpassAdapter,
}


def get_adapter(name: str) -> SourceAdapter:
    cls = ADAPTERS.get(name)
    if cls is None:
        raise ValueError(f"Unknown adapter: {name}")
    return cls()
