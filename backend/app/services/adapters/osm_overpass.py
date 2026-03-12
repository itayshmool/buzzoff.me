import asyncio
import logging

import httpx

from app.services.adapters.base import RawCameraRecord, SourceAdapter

logger = logging.getLogger(__name__)

OVERPASS_API_URL = "https://overpass-api.de/api/interpreter"
MAX_RETRIES = 3
RETRY_BASE_DELAY = 60  # seconds


class OSMOverpassAdapter(SourceAdapter):
    def __init__(self, http_client: httpx.AsyncClient | None = None):
        self._client = http_client

    async def fetch(self, config: dict) -> list[RawCameraRecord]:
        query = config["query"]
        type_mapping = config.get("type_mapping", {})

        response_data = await self._execute_query(query)
        elements = response_data.get("elements", [])

        records = []
        for element in elements:
            if element.get("type") != "node":
                continue
            tags = element.get("tags", {})
            records.append(self._parse_node(element, tags, type_mapping))

        return records

    async def _execute_query(self, query: str) -> dict:
        for attempt in range(MAX_RETRIES + 1):
            try:
                if self._client:
                    response = await self._client.post(
                        OVERPASS_API_URL, data={"data": query}
                    )
                    response.raise_for_status()
                    return response.json()

                async with httpx.AsyncClient(timeout=120) as client:
                    response = await client.post(OVERPASS_API_URL, data={"data": query})
                    response.raise_for_status()
                    return response.json()
            except httpx.HTTPStatusError as e:
                if e.response.status_code == 429 and attempt < MAX_RETRIES:
                    delay = RETRY_BASE_DELAY * (2 ** attempt)
                    logger.warning(
                        "Overpass 429 rate-limited (attempt %d/%d), retrying in %ds...",
                        attempt + 1, MAX_RETRIES + 1, delay,
                    )
                    await asyncio.sleep(delay)
                    continue
                raise

    def _parse_node(
        self, element: dict, tags: dict, type_mapping: dict
    ) -> RawCameraRecord:
        camera_type = self._resolve_type(tags, type_mapping)
        speed_limit = self._parse_int(tags.get("maxspeed"))
        heading = self._parse_float(tags.get("direction"))

        return RawCameraRecord(
            lat=element["lat"],
            lon=element["lon"],
            type=camera_type,
            speed_limit=speed_limit,
            heading=heading,
            external_id=f"osm:{element['id']}",
            raw_data=element,
        )

    def _resolve_type(self, tags: dict, type_mapping: dict) -> str:
        enforcement = tags.get("enforcement")
        if enforcement and enforcement in type_mapping:
            return type_mapping[enforcement]
        return "fixed_speed"

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
