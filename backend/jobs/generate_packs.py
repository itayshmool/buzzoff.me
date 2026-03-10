"""Cron job: Generate SQLite pack files for each enabled country."""

import asyncio
import logging

from geoalchemy2.functions import ST_X, ST_Y
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.db.session import async_session_factory
from app.models.camera import Camera
from app.models.country import Country
from app.models.pack import Pack
from app.services.pack_generator import PackCamera, PackGenerator, PackMeta

logger = logging.getLogger(__name__)


async def generate_all_packs():
    async with async_session_factory() as session:
        result = await session.execute(
            select(Country).where(Country.enabled.is_(True))
        )
        countries = result.scalars().all()

        generator = PackGenerator(output_dir=settings.pack_storage_path)

        for country in countries:
            try:
                await _generate_pack(session, country, generator)
            except Exception:
                logger.exception("Failed to generate pack for %s", country.code)


async def _generate_pack(session: AsyncSession, country: Country, generator: PackGenerator):
    # Get all cameras for this country with lat/lon extracted via PostGIS
    result = await session.execute(
        select(
            Camera,
            ST_Y(Camera.location).label("lat"),
            ST_X(Camera.location).label("lon"),
        ).where(Camera.country_code == country.code)
    )
    rows = result.all()

    if not rows:
        logger.info("No cameras for %s, skipping pack generation", country.code)
        return

    # Get next version number
    version_result = await session.execute(
        select(func.coalesce(func.max(Pack.version), 0))
        .where(Pack.country_code == country.code)
    )
    current_version = version_result.scalar_one()
    next_version = current_version + 1

    meta = PackMeta(
        country_code=country.code,
        country_name=country.name,
        version=next_version,
        speed_unit=country.speed_unit,
    )

    pack_cameras = [
        PackCamera(
            lat=lat,
            lon=lon,
            type=cam.type,
            speed_limit=cam.speed_limit,
            heading=cam.heading,
            road_name=cam.road_name,
        )
        for cam, lat, lon in rows
    ]

    pack_result = generator.generate(meta, pack_cameras)

    pack = Pack(
        country_code=country.code,
        version=next_version,
        camera_count=pack_result.camera_count,
        file_size_bytes=pack_result.file_size_bytes,
        file_path=pack_result.file_path,
        checksum_sha256=pack_result.checksum_sha256,
    )
    session.add(pack)
    await session.commit()

    logger.info(
        "Generated pack v%d for %s: %d cameras, %d bytes",
        next_version, country.code, pack_result.camera_count, pack_result.file_size_bytes,
    )


if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    asyncio.run(generate_all_packs())
