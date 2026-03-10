"""One-time seed script: Add Israel + OSM source to the database."""

import asyncio
import logging

from sqlalchemy import select

from app.db.session import async_session_factory
from app.models.country import Country
from app.models.source import Source

logger = logging.getLogger(__name__)


async def seed():
    async with async_session_factory() as session:
        # Insert Israel if not exists
        result = await session.execute(select(Country).where(Country.code == "IL"))
        if result.scalar_one_or_none():
            print("Israel already exists")
        else:
            session.add(Country(
                code="IL",
                name="Israel",
                name_local="ישראל",
                speed_unit="kmh",
                enabled=True,
            ))
            await session.flush()
            print("Inserted Israel")

        # Insert OSM source if not exists
        result = await session.execute(
            select(Source).where(Source.name == "OSM Israel Speed Cameras")
        )
        existing = result.scalar_one_or_none()
        if existing:
            print(f"OSM source already exists: {existing.id}")
        else:
            session.add(Source(
                country_code="IL",
                name="OSM Israel Speed Cameras",
                adapter="osm_overpass",
                config={
                    "query": '[out:json][timeout:60];area["name:en"="Israel"]->.a;(node["highway"="speed_camera"](area.a););out body;',
                    "type_mapping": {
                        "traffic_signals": "red_light",
                        "average_speed": "avg_speed_start",
                    },
                },
                confidence=0.7,
                enabled=True,
            ))
            print("Inserted OSM source")

        await session.commit()

        # Verify
        result = await session.execute(select(Country))
        for c in result.scalars().all():
            print(f"  Country: {c.code} - {c.name} (enabled={c.enabled})")

        result = await session.execute(select(Source))
        for s in result.scalars().all():
            print(f"  Source: {s.id} - {s.name} ({s.adapter})")


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    asyncio.run(seed())
