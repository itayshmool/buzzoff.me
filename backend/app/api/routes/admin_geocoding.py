import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_admin, get_db
from app.models.raw_camera import RawCamera

router = APIRouter()


class ResolveRequest(BaseModel):
    lat: float
    lon: float


@router.get("/geocoding/queue")
async def geocoding_queue(
    limit: int = Query(default=100, ge=1, le=1000),
    _admin: str = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(RawCamera)
        .where(
            RawCamera.lat.is_(None),
            RawCamera.address.isnot(None),
            RawCamera.geocode_failed.is_(False),
        )
        .limit(limit)
    )
    cameras = result.scalars().all()
    return [
        {
            "id": str(c.id),
            "address": c.address,
            "country_code": c.country_code,
            "type": c.type,
        }
        for c in cameras
    ]


@router.get("/geocoding/failed")
async def geocoding_failed(
    limit: int = Query(default=100, ge=1, le=1000),
    _admin: str = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(RawCamera)
        .where(RawCamera.geocode_failed.is_(True))
        .limit(limit)
    )
    cameras = result.scalars().all()
    return [
        {
            "id": str(c.id),
            "address": c.address,
            "country_code": c.country_code,
            "type": c.type,
        }
        for c in cameras
    ]


@router.put("/geocoding/{camera_id}/resolve")
async def resolve_geocoding(
    camera_id: uuid.UUID,
    body: ResolveRequest,
    _admin: str = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(RawCamera).where(RawCamera.id == camera_id))
    camera = result.scalar_one_or_none()
    if camera is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Raw camera not found")

    camera.lat = body.lat
    camera.lon = body.lon
    camera.geocoded = True
    camera.geocode_failed = False
    await db.commit()
    return {"id": str(camera.id), "lat": camera.lat, "lon": camera.lon, "status": "resolved"}
