"""Cron job: Merge/dedup raw cameras into verified camera records."""

import asyncio
import logging

from sqlalchemy import delete, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import async_session_factory
from app.models.camera import Camera
from app.models.country import Country
from app.models.raw_camera import RawCamera
from app.models.source import Source
from app.services.merger import CameraInput, merge_cameras

logger = logging.getLogger(__name__)


async def merge_all_countries(country_code: str | None = None):
    async with async_session_factory() as session:
        query = select(Country).where(Country.enabled.is_(True))
        if country_code:
            query = query.where(Country.code == country_code)
        result = await session.execute(query)
        countries = result.scalars().all()

        for country in countries:
            try:
                await _merge_country(session, country.code)
            except Exception:
                logger.exception("Failed to merge cameras for %s", country.code)


async def _merge_country(session: AsyncSession, country_code: str):
    # Get all geocoded raw cameras for this country
    result = await session.execute(
        select(RawCamera, Source.confidence)
        .join(Source, RawCamera.source_id == Source.id)
        .where(
            RawCamera.country_code == country_code,
            RawCamera.geocoded.is_(True),
            RawCamera.lat.isnot(None),
            RawCamera.lon.isnot(None),
        )
    )
    rows = result.all()

    if not rows:
        logger.info("No geocoded cameras for %s", country_code)
        return

    inputs = [
        CameraInput(
            lat=raw.lat,
            lon=raw.lon,
            source_id=str(raw.source_id),
            confidence=confidence,
            type=raw.type,
            speed_limit=raw.speed_limit,
            heading=raw.heading,
            road_name=raw.road_name,
        )
        for raw, confidence in rows
    ]

    merged = merge_cameras(inputs)
    logger.info("Merged %d raw records into %d cameras for %s", len(inputs), len(merged), country_code)

    # Clear existing cameras for this country and insert fresh
    await session.execute(delete(Camera).where(Camera.country_code == country_code))

    for cam in merged:
        location_wkt = f"POINT({cam.lon} {cam.lat})"
        camera = Camera(
            country_code=country_code,
            location=location_wkt,
            type=cam.type,
            speed_limit=cam.speed_limit,
            heading=cam.heading,
            road_name=cam.road_name,
            confidence=cam.confidence,
            source_ids=cam.source_ids,
        )
        session.add(camera)

    await session.commit()
    logger.info("Saved %d merged cameras for %s", len(merged), country_code)


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    asyncio.run(merge_all_countries())
