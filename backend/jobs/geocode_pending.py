"""Cron job: Geocode raw camera records that have addresses but no coordinates."""

import asyncio
import logging

from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.db.session import async_session_factory
from app.models.raw_camera import RawCamera
from app.services.geocoding.db_cache import DbGeocodeCache
from app.services.geocoding.nominatim import NominatimGeocoder
from app.services.geocoding.service import GeocodingService

logger = logging.getLogger(__name__)


async def geocode_pending():
    async with async_session_factory() as session:
        result = await session.execute(
            select(RawCamera).where(
                RawCamera.geocoded.is_(False),
                RawCamera.geocode_failed.is_(False),
                RawCamera.address.isnot(None),
            )
        )
        pending = result.scalars().all()

        if not pending:
            logger.info("No records to geocode")
            return

        logger.info("Found %d records to geocode", len(pending))

        cache = DbGeocodeCache(session=session)
        nominatim = NominatimGeocoder(user_agent=settings.nominatim_user_agent)
        service = GeocodingService(cache=cache, nominatim=nominatim)

        success = 0
        failed = 0
        for record in pending:
            geo_result = await service.geocode(record.address)
            if geo_result:
                await session.execute(
                    update(RawCamera)
                    .where(RawCamera.id == record.id)
                    .values(lat=geo_result.lat, lon=geo_result.lon, geocoded=True)
                )
                success += 1
            else:
                await session.execute(
                    update(RawCamera)
                    .where(RawCamera.id == record.id)
                    .values(geocode_failed=True)
                )
                failed += 1

        await session.commit()
        logger.info("Geocoded %d records, %d failed", success, failed)


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    asyncio.run(geocode_pending())
