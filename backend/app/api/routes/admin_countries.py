from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_admin, get_db
from app.models.country import Country
from app.models.pack import Pack
from app.schemas.admin import AdminCountryResponse, CountryCreate, CountryUpdate

router = APIRouter()


@router.get("/countries", response_model=list[AdminCountryResponse])
async def list_countries(
    _admin: str = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Country))
    countries = result.scalars().all()

    # Count packs per country
    pack_stmt = select(
        Pack.country_code, func.count().label("cnt")
    ).group_by(Pack.country_code)
    pack_result = await db.execute(pack_stmt)
    pack_counts = {row.country_code: row.cnt for row in pack_result.all()}

    return [
        AdminCountryResponse(
            code=c.code,
            name=c.name,
            name_local=c.name_local,
            speed_unit=c.speed_unit,
            enabled=c.enabled,
            pack_count=pack_counts.get(c.code, 0),
        )
        for c in countries
    ]


@router.post("/countries", response_model=AdminCountryResponse, status_code=status.HTTP_201_CREATED)
async def create_country(
    body: CountryCreate,
    _admin: str = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Country).where(Country.code == body.code))
    if result.scalar_one_or_none() is not None:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Country already exists")

    country = Country(
        code=body.code,
        name=body.name,
        name_local=body.name_local,
        speed_unit=body.speed_unit,
        enabled=body.enabled,
    )
    db.add(country)
    await db.commit()
    return AdminCountryResponse(
        code=body.code,
        name=body.name,
        name_local=body.name_local,
        speed_unit=body.speed_unit,
        enabled=body.enabled,
    )


@router.put("/countries/{code}", response_model=AdminCountryResponse)
async def update_country(
    code: str,
    body: CountryUpdate,
    _admin: str = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Country).where(Country.code == code))
    country = result.scalar_one_or_none()
    if country is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Country not found")

    if body.name is not None:
        country.name = body.name
    if body.name_local is not None:
        country.name_local = body.name_local
    if body.speed_unit is not None:
        country.speed_unit = body.speed_unit
    if body.enabled is not None:
        country.enabled = body.enabled

    await db.commit()
    return AdminCountryResponse(
        code=country.code,
        name=country.name,
        name_local=country.name_local,
        speed_unit=country.speed_unit,
        enabled=country.enabled,
    )


@router.delete("/countries/{code}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_country(
    code: str,
    _admin: str = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Country).where(Country.code == code))
    country = result.scalar_one_or_none()
    if country is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Country not found")

    await db.delete(country)
    await db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
