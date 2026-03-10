from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_admin, get_db
from app.models.pack import Pack

router = APIRouter()


@router.get("/countries/{code}/packs")
async def list_packs(
    code: str,
    _admin: str = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Pack)
        .where(Pack.country_code == code)
        .order_by(Pack.version.desc())
    )
    packs = result.scalars().all()
    return [
        {
            "id": str(p.id),
            "country_code": p.country_code,
            "version": p.version,
            "camera_count": p.camera_count,
            "file_size_bytes": p.file_size_bytes,
            "checksum_sha256": p.checksum_sha256,
            "published_at": p.published_at.isoformat() if p.published_at else None,
        }
        for p in packs
    ]


@router.get("/countries/{code}/packs/{version}")
async def get_pack_detail(
    code: str,
    version: int,
    _admin: str = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Pack).where(Pack.country_code == code, Pack.version == version)
    )
    pack = result.scalar_one_or_none()
    if pack is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Pack not found")

    return {
        "id": str(pack.id),
        "country_code": pack.country_code,
        "version": pack.version,
        "camera_count": pack.camera_count,
        "file_size_bytes": pack.file_size_bytes,
        "file_path": pack.file_path,
        "checksum_sha256": pack.checksum_sha256,
        "published_at": pack.published_at.isoformat() if pack.published_at else None,
    }
