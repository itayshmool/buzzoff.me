import hashlib
import re
from dataclasses import dataclass
from typing import Protocol


@dataclass
class GeocodingResult:
    lat: float
    lon: float
    provider: str


class GeocodeCache(Protocol):
    async def get(self, address: str) -> GeocodingResult | None: ...
    async def put(self, address: str, result: GeocodingResult) -> None: ...


class Geocoder(Protocol):
    async def geocode(self, address: str) -> GeocodingResult | None: ...


class GeocodingService:
    def __init__(self, cache: GeocodeCache, nominatim: Geocoder):
        self._cache = cache
        self._nominatim = nominatim

    async def geocode(self, address: str) -> GeocodingResult | None:
        address = self._normalize(address)

        cached = await self._cache.get(address)
        if cached is not None:
            return cached

        result = await self._nominatim.geocode(address)
        if result is not None:
            await self._cache.put(address, result)
            return result

        return None

    async def batch_geocode(self, addresses: list[str]) -> list[GeocodingResult | None]:
        return [await self.geocode(addr) for addr in addresses]

    @staticmethod
    def _normalize(address: str) -> str:
        return re.sub(r"\s+", " ", address.strip())

    @staticmethod
    def address_hash(address: str) -> str:
        normalized = re.sub(r"\s+", " ", address.strip()).lower()
        return hashlib.sha256(normalized.encode("utf-8")).hexdigest()
