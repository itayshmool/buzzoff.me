from fastapi import APIRouter, Depends
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_admin, get_db
from app.models.camera import Camera
from app.models.country import Country
from app.models.pack import Pack
from app.models.source import Source

router = APIRouter()


@router.get("/dashboard/stats")
async def dashboard_stats(
    _admin: str = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    countries_count = (await db.execute(select(func.count()).select_from(Country))).scalar()
    sources_count = (await db.execute(select(func.count()).select_from(Source))).scalar()
    cameras_count = (await db.execute(select(func.count()).select_from(Camera))).scalar()
    packs_count = (await db.execute(select(func.count()).select_from(Pack))).scalar()

    return {
        "countries": countries_count,
        "sources": sources_count,
        "cameras": cameras_count,
        "packs": packs_count,
    }
