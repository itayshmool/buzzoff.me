import csv
from pathlib import Path

from app.services.adapters.base import RawCameraRecord, SourceAdapter


class CSVAdapter(SourceAdapter):
    async def fetch(self, config: dict) -> list[RawCameraRecord]:
        file_path = Path(config["file_path"])
        if not file_path.exists():
            raise FileNotFoundError(f"CSV file not found: {file_path}")

        column_mapping = config.get("column_mapping", {})

        with open(file_path, newline="", encoding="utf-8") as f:
            reader = csv.DictReader(f)
            return [self._parse_row(row, column_mapping) for row in reader]

    def _parse_row(self, row: dict, mapping: dict) -> RawCameraRecord:
        lat = self._parse_float(self._get_mapped(row, mapping, "lat"))
        lon = self._parse_float(self._get_mapped(row, mapping, "lon"))
        camera_type = self._get_mapped(row, mapping, "type") or "fixed_speed"
        speed_limit = self._parse_int(self._get_mapped(row, mapping, "speed_limit"))
        heading = self._parse_float(self._get_mapped(row, mapping, "heading"))
        address = self._get_mapped(row, mapping, "address") or None
        external_id = self._get_mapped(row, mapping, "external_id") or None

        return RawCameraRecord(
            lat=lat,
            lon=lon,
            type=camera_type,
            speed_limit=speed_limit,
            heading=heading,
            address=address,
            external_id=external_id,
            raw_data=dict(row),
        )

    def _get_mapped(self, row: dict, mapping: dict, field: str) -> str | None:
        column_name = mapping.get(field, field)
        value = row.get(column_name, "").strip()
        return value if value else None

    def _parse_int(self, value: str | None) -> int | None:
        if value is None:
            return None
        try:
            return int(value)
        except (ValueError, TypeError):
            return None

    def _parse_float(self, value: str | None) -> float | None:
        if value is None:
            return None
        try:
            return float(value)
        except (ValueError, TypeError):
            return None
