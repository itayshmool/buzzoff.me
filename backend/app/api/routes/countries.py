from fastapi import APIRouter, Depends
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db
from app.models.country import Country
from app.models.pack import Pack
from app.schemas.country import CountryResponse

router = APIRouter()


@router.get("/countries", response_model=list[CountryResponse])
async def list_countries(db: AsyncSession = Depends(get_db)):
    result = await db.execute(select(Country).where(Country.enabled.is_(True)))
    countries = result.scalars().all()

    # Get latest pack info per country
    latest_pack_stmt = select(
        Pack.country_code,
        func.max(Pack.version).label("version"),
        func.max(Pack.camera_count).label("camera_count"),
    ).group_by(Pack.country_code)
    pack_result = await db.execute(latest_pack_stmt)
    pack_map = {row.country_code: row for row in pack_result.all()}

    return [
        CountryResponse(
            code=c.code,
            name=c.name,
            name_local=c.name_local,
            speed_unit=c.speed_unit,
            enabled=c.enabled,
            pack_version=pack_map[c.code].version if c.code in pack_map else None,
            camera_count=pack_map[c.code].camera_count if c.code in pack_map else None,
        )
        for c in countries
    ]
