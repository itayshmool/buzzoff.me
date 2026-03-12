"""Cron job: Fetch camera data from all enabled sources."""

import asyncio
import logging
from datetime import datetime, timezone

from sqlalchemy import select, update
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import async_session_factory
from app.models.source import Source
from app.models.raw_camera import RawCamera
from app.services.adapters.registry import get_adapter

logger = logging.getLogger(__name__)


async def fetch_all_sources():
    async with async_session_factory() as session:
        result = await session.execute(
            select(Source).where(Source.enabled.is_(True))
        )
        sources = result.scalars().all()

        logger.info("Found %d enabled sources", len(sources))

        overpass_count = 0
        for source in sources:
            try:
                # Overpass API rate-limits aggressively — wait 30s between queries
                if source.adapter == "osm_overpass" and overpass_count > 0:
                    logger.info("Waiting 30s before next Overpass query...")
                    await asyncio.sleep(30)
                await _fetch_source(session, source)
                if source.adapter == "osm_overpass":
                    overpass_count += 1
            except Exception:
                logger.exception("Failed to fetch source %s (%s)", source.name, source.id)
                if source.adapter == "osm_overpass":
                    overpass_count += 1


async def _fetch_source(session: AsyncSession, source: Source):
    adapter = get_adapter(source.adapter)
    records = await adapter.fetch(source.config)
    logger.info("Fetched %d records from %s", len(records), source.name)

    for record in records:
        raw = RawCamera(
            source_id=source.id,
            country_code=source.country_code,
            external_id=record.external_id,
            lat=record.lat,
            lon=record.lon,
            address=record.address,
            type=record.type,
            speed_limit=record.speed_limit,
            heading=record.heading,
            road_name=record.road_name,
            raw_data=record.raw_data,
            geocoded=record.lat is not None and record.lon is not None,
        )
        session.add(raw)

    await session.execute(
        update(Source)
        .where(Source.id == source.id)
        .values(last_fetched_at=datetime.now(timezone.utc))
    )
    await session.commit()
    logger.info("Saved %d raw records for source %s", len(records), source.name)


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    asyncio.run(fetch_all_sources())
