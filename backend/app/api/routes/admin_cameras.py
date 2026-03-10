from fastapi import APIRouter, Depends, Query
from geoalchemy2.functions import ST_X, ST_Y
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_admin, get_db
from app.models.camera import Camera

router = APIRouter()


@router.get("/countries/{code}/cameras")
async def list_cameras(
    code: str,
    limit: int = Query(default=50, ge=1, le=500),
    offset: int = Query(default=0, ge=0),
    _admin: str = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    count_result = await db.execute(
        select(func.count()).select_from(Camera).where(Camera.country_code == code)
    )
    total = count_result.scalar()

    query = (
        select(
            Camera.id,
            Camera.country_code,
            ST_Y(Camera.location).label("lat"),
            ST_X(Camera.location).label("lon"),
            Camera.type,
            Camera.speed_limit,
            Camera.heading,
            Camera.road_name,
            Camera.confidence,
        )
        .where(Camera.country_code == code)
        .limit(limit)
        .offset(offset)
    )
    result = await db.execute(query)
    items = result.all()

    return {
        "total": total,
        "items": [
            {
                "id": str(row.id),
                "lat": row.lat,
                "lon": row.lon,
                "type": row.type,
                "speed_limit": row.speed_limit,
                "heading": row.heading,
                "road_name": row.road_name,
                "confidence": row.confidence,
            }
            for row in items
        ],
    }


@router.get("/countries/{code}/cameras/stats")
async def cameras_stats(
    code: str,
    _admin: str = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Camera.type, func.count().label("count"))
        .where(Camera.country_code == code)
        .group_by(Camera.type)
    )
    rows = result.all()
    by_type = {row.type: row.count for row in rows}
    return {
        "total": sum(by_type.values()),
        "by_type": by_type,
    }
