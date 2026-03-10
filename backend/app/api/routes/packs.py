from pathlib import Path

from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import FileResponse
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_db
from app.models.pack import Pack
from app.schemas.pack import PackMetaResponse

router = APIRouter()


async def _get_latest_pack(country_code: str, db: AsyncSession) -> Pack | None:
    result = await db.execute(
        select(Pack)
        .where(Pack.country_code == country_code)
        .order_by(Pack.version.desc())
        .limit(1)
    )
    return result.scalar_one_or_none()


@router.get("/packs/{country_code}/meta", response_model=PackMetaResponse)
async def pack_meta(country_code: str, db: AsyncSession = Depends(get_db)):
    pack = await _get_latest_pack(country_code, db)
    if pack is None:
        raise HTTPException(status_code=404, detail="No pack found for this country")

    return PackMetaResponse(
        country_code=pack.country_code,
        version=pack.version,
        camera_count=pack.camera_count,
        file_size_bytes=pack.file_size_bytes,
        checksum_sha256=pack.checksum_sha256,
    )


@router.get("/packs/{country_code}/data")
async def pack_download(country_code: str, db: AsyncSession = Depends(get_db)):
    pack = await _get_latest_pack(country_code, db)
    if pack is None:
        raise HTTPException(status_code=404, detail="No pack found for this country")

    file_path = Path(pack.file_path)
    if not file_path.exists():
        raise HTTPException(status_code=404, detail="Pack file not found on disk")

    return FileResponse(
        path=str(file_path),
        media_type="application/octet-stream",
        filename=file_path.name,
    )
