import asyncio
import logging

import httpx

from app.services.geocoding.service import GeocodingResult

logger = logging.getLogger(__name__)

NOMINATIM_URL = "https://nominatim.openstreetmap.org/search"


class NominatimGeocoder:
    def __init__(self, user_agent: str = "buzzoff-app"):
        self._user_agent = user_agent
        self._client: httpx.AsyncClient | None = None
        self._last_request_time: float = 0

    async def geocode(self, address: str) -> GeocodingResult | None:
        try:
            # Rate limit: max 1 req/sec per Nominatim policy
            now = asyncio.get_event_loop().time()
            elapsed = now - self._last_request_time
            if elapsed < 1.0:
                await asyncio.sleep(1.0 - elapsed)

            client = self._client or httpx.AsyncClient(timeout=30)
            try:
                response = await client.get(
                    NOMINATIM_URL,
                    params={"q": address, "format": "json", "limit": 1},
                    headers={"User-Agent": self._user_agent},
                )
                self._last_request_time = asyncio.get_event_loop().time()
                response.raise_for_status()
                data = response.json()
            finally:
                if not self._client:
                    await client.aclose()

            if not data:
                return None

            return GeocodingResult(
                lat=float(data[0]["lat"]),
                lon=float(data[0]["lon"]),
                provider="nominatim",
            )
        except Exception:
            logger.warning("Nominatim geocoding failed for: %s", address, exc_info=True)
            return None
