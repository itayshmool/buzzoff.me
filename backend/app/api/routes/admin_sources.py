import uuid
from pathlib import Path

from fastapi import APIRouter, Depends, HTTPException, Response, UploadFile, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_admin, get_db
from app.config import settings
from app.models.country import Country
from app.models.source import Source
from app.schemas.admin import AdminSourceResponse, SourceCreate, SourceUpdate

router = APIRouter()


@router.get("/countries/{code}/sources", response_model=list[AdminSourceResponse])
async def list_sources(
    code: str,
    _admin: str = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Source).where(Source.country_code == code))
    sources = result.scalars().all()
    return [
        AdminSourceResponse(
            id=s.id,
            country_code=s.country_code,
            name=s.name,
            adapter=s.adapter,
            config=s.config,
            schedule=s.schedule,
            confidence=s.confidence,
            enabled=s.enabled,
        )
        for s in sources
    ]


@router.post(
    "/countries/{code}/sources",
    response_model=AdminSourceResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_source(
    code: str,
    body: SourceCreate,
    _admin: str = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Country).where(Country.code == code))
    if result.scalar_one_or_none() is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Country not found")

    source_id = uuid.uuid4()
    source = Source(
        id=source_id,
        country_code=code,
        name=body.name,
        adapter=body.adapter,
        config=body.config,
        schedule=body.schedule,
        confidence=body.confidence,
        enabled=body.enabled,
    )
    db.add(source)
    await db.commit()
    return AdminSourceResponse(
        id=source_id,
        country_code=code,
        name=body.name,
        adapter=body.adapter,
        config=body.config,
        schedule=body.schedule,
        confidence=body.confidence,
        enabled=body.enabled,
    )


@router.put("/sources/{source_id}", response_model=AdminSourceResponse)
async def update_source(
    source_id: uuid.UUID,
    body: SourceUpdate,
    _admin: str = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Source).where(Source.id == source_id))
    source = result.scalar_one_or_none()
    if source is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Source not found")

    if body.name is not None:
        source.name = body.name
    if body.adapter is not None:
        source.adapter = body.adapter
    if body.config is not None:
        source.config = body.config
    if body.schedule is not None:
        source.schedule = body.schedule
    if body.confidence is not None:
        source.confidence = body.confidence
    if body.enabled is not None:
        source.enabled = body.enabled

    await db.commit()
    return AdminSourceResponse(
        id=source.id,
        country_code=source.country_code,
        name=source.name,
        adapter=source.adapter,
        config=source.config,
        schedule=source.schedule,
        confidence=source.confidence,
        enabled=source.enabled,
    )


@router.delete("/sources/{source_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_source(
    source_id: uuid.UUID,
    _admin: str = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Source).where(Source.id == source_id))
    source = result.scalar_one_or_none()
    if source is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Source not found")

    await db.delete(source)
    await db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


@router.post("/sources/{source_id}/upload", response_model=AdminSourceResponse)
async def upload_source_file(
    source_id: uuid.UUID,
    file: UploadFile,
    _admin: str = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Source).where(Source.id == source_id))
    source = result.scalar_one_or_none()
    if source is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Source not found")

    upload_dir = Path(settings.upload_storage_path) / str(source_id)
    upload_dir.mkdir(parents=True, exist_ok=True)

    file_path = upload_dir / file.filename
    content = await file.read()
    file_path.write_bytes(content)

    config = dict(source.config) if source.config else {}
    config["file_path"] = str(file_path)
    source.config = config

    await db.commit()
    return AdminSourceResponse(
        id=source.id,
        country_code=source.country_code,
        name=source.name,
        adapter=source.adapter,
        config=source.config,
        schedule=source.schedule,
        confidence=source.confidence,
        enabled=source.enabled,
    )
