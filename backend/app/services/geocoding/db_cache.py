from sqlalchemy import select
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.geocode_cache import GeocodeCache
from app.services.geocoding.service import GeocodingResult, GeocodingService


class DbGeocodeCache:
    def __init__(self, session: AsyncSession):
        self._session = session

    async def get(self, address: str) -> GeocodingResult | None:
        address_hash = GeocodingService.address_hash(address)
        stmt = select(GeocodeCache).where(GeocodeCache.address_hash == address_hash)
        result = await self._session.execute(stmt)
        row = result.scalar_one_or_none()
        if row is None:
            return None
        return GeocodingResult(lat=row.lat, lon=row.lon, provider=row.provider)

    async def put(self, address: str, result: GeocodingResult) -> None:
        address_hash = GeocodingService.address_hash(address)
        stmt = insert(GeocodeCache).values(
            address_hash=address_hash,
            address=address,
            lat=result.lat,
            lon=result.lon,
            provider=result.provider,
        ).on_conflict_do_nothing(index_elements=["address_hash"])
        await self._session.execute(stmt)
        await self._session.commit()
