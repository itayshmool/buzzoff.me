import uuid

from fastapi import APIRouter, Depends, HTTPException, Query, Response, status
from geoalchemy2.functions import ST_X, ST_Y
from sqlalchemy import func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_developer, get_db
from app.models.camera import Camera
from app.models.country import Country
from app.models.developer import DeveloperKey, DeveloperSubmission
from app.models.source import Source
from app.schemas.developer import (
    CameraSubmitRequest,
    CountryCreateRequest,
    CountryResponse,
    CountryUpdateRequest,
    DeveloperMeResponse,
    SourceCreateRequest,
    SourceResponse,
    SubmissionDetailResponse,
    SubmissionResponse,
)

router = APIRouter()


def _require_scope(dev: DeveloperKey, scope: str) -> None:
    if scope not in dev.scopes:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"API key missing required scope: {scope}",
        )


@router.get("/me", response_model=DeveloperMeResponse)
async def developer_me(
    dev: DeveloperKey = Depends(get_current_developer),
):
    return DeveloperMeResponse(
        id=dev.id,
        name=dev.name,
        email=dev.email,
        key_prefix=dev.key_prefix,
        scopes=dev.scopes,
        enabled=dev.enabled,
        last_used_at=dev.last_used_at,
        created_at=dev.created_at,
    )


@router.get("/countries")
async def list_countries(
    dev: DeveloperKey = Depends(get_current_developer),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Country).where(Country.enabled.is_(True)))
    countries = result.scalars().all()
    return [
        {"code": c.code, "name": c.name, "speed_unit": c.speed_unit}
        for c in countries
    ]


@router.post("/countries", response_model=CountryResponse, status_code=status.HTTP_201_CREATED)
async def create_country(
    body: CountryCreateRequest,
    dev: DeveloperKey = Depends(get_current_developer),
    db: AsyncSession = Depends(get_db),
):
    _require_scope(dev, "manage_countries")
    result = await db.execute(select(Country).where(Country.code == body.code))
    if result.scalar_one_or_none() is not None:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Country already exists")

    country = Country(
        code=body.code,
        name=body.name,
        name_local=body.name_local,
        speed_unit=body.speed_unit,
        enabled=True,
    )
    db.add(country)
    await db.commit()
    return CountryResponse(
        code=country.code, name=country.name, name_local=country.name_local,
        speed_unit=country.speed_unit, enabled=country.enabled,
    )


@router.get("/countries/{code}", response_model=CountryResponse)
async def get_country(
    code: str,
    dev: DeveloperKey = Depends(get_current_developer),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(select(Country).where(Country.code == code))
    country = result.scalar_one_or_none()
    if country is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Country not found")
    return CountryResponse(
        code=country.code, name=country.name, name_local=country.name_local,
        speed_unit=country.speed_unit, enabled=country.enabled,
    )


@router.put("/countries/{code}", response_model=CountryResponse)
async def update_country(
    code: str,
    body: CountryUpdateRequest,
    dev: DeveloperKey = Depends(get_current_developer),
    db: AsyncSession = Depends(get_db),
):
    _require_scope(dev, "manage_countries")
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

    await db.commit()
    return CountryResponse(
        code=country.code, name=country.name, name_local=country.name_local,
        speed_unit=country.speed_unit, enabled=country.enabled,
    )


@router.delete("/countries/{code}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_country(
    code: str,
    dev: DeveloperKey = Depends(get_current_developer),
    db: AsyncSession = Depends(get_db),
):
    _require_scope(dev, "manage_countries")
    result = await db.execute(select(Country).where(Country.code == code))
    country = result.scalar_one_or_none()
    if country is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Country not found")

    await db.delete(country)
    await db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


# --- Sources ---

@router.get("/countries/{code}/sources", response_model=list[SourceResponse])
async def list_sources(
    code: str,
    dev: DeveloperKey = Depends(get_current_developer),
    db: AsyncSession = Depends(get_db),
):
    _require_scope(dev, "manage_countries")
    result = await db.execute(select(Source).where(Source.country_code == code))
    sources = result.scalars().all()
    return [
        SourceResponse(
            id=s.id, country_code=s.country_code, name=s.name,
            adapter=s.adapter, confidence=s.confidence, enabled=s.enabled,
            last_fetched_at=s.last_fetched_at, created_at=s.created_at,
        )
        for s in sources
    ]


@router.post(
    "/countries/{code}/sources",
    response_model=SourceResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_source(
    code: str,
    body: SourceCreateRequest,
    dev: DeveloperKey = Depends(get_current_developer),
    db: AsyncSession = Depends(get_db),
):
    _require_scope(dev, "manage_countries")
    result = await db.execute(select(Country).where(Country.code == code))
    if result.scalar_one_or_none() is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Country not found")

    source = Source(
        country_code=code,
        name=body.name,
        adapter=body.adapter,
        config=body.config,
        confidence=body.confidence,
        enabled=True,
    )
    db.add(source)
    await db.commit()
    await db.refresh(source)
    return SourceResponse(
        id=source.id, country_code=source.country_code, name=source.name,
        adapter=source.adapter, confidence=source.confidence, enabled=source.enabled,
        last_fetched_at=source.last_fetched_at, created_at=source.created_at,
    )


@router.delete("/countries/{code}/sources/{source_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_source(
    code: str,
    source_id: uuid.UUID,
    dev: DeveloperKey = Depends(get_current_developer),
    db: AsyncSession = Depends(get_db),
):
    _require_scope(dev, "manage_countries")
    result = await db.execute(
        select(Source).where(Source.id == source_id, Source.country_code == code)
    )
    source = result.scalar_one_or_none()
    if source is None:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Source not found")

    await db.delete(source)
    await db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)


# --- Cameras ---

@router.post(
    "/countries/{code}/cameras",
    response_model=SubmissionResponse,
    status_code=status.HTTP_201_CREATED,
)
async def submit_cameras(
    code: str,
    body: CameraSubmitRequest,
    dev: DeveloperKey = Depends(get_current_developer),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(Country).where(Country.code == code, Country.enabled.is_(True))
    )
    if result.scalar_one_or_none() is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Country not found or not enabled",
        )

    cameras_data = [cam.model_dump() for cam in body.cameras]
    submission = DeveloperSubmission(
        developer_key_id=dev.id,
        country_code=code,
        camera_count=len(cameras_data),
        cameras_json=cameras_data,
    )
    db.add(submission)
    await db.commit()
    await db.refresh(submission)

    return SubmissionResponse(
        id=submission.id,
        country_code=submission.country_code,
        status=submission.status,
        camera_count=submission.camera_count,
        submitted_at=submission.submitted_at,
    )


@router.get("/countries/{code}/cameras")
async def query_cameras(
    code: str,
    limit: int = Query(default=50, ge=1, le=500),
    offset: int = Query(default=0, ge=0),
    type: str | None = Query(default=None),
    dev: DeveloperKey = Depends(get_current_developer),
    db: AsyncSession = Depends(get_db),
):
    base_query = select(
        Camera.id,
        ST_Y(Camera.location).label("lat"),
        ST_X(Camera.location).label("lon"),
        Camera.type,
        Camera.speed_limit,
        Camera.heading,
        Camera.road_name,
    ).where(Camera.country_code == code)

    if type:
        base_query = base_query.where(Camera.type == type)

    count_result = await db.execute(
        select(func.count()).select_from(Camera).where(Camera.country_code == code)
    )
    total = count_result.scalar()

    result = await db.execute(base_query.limit(limit).offset(offset))
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
            }
            for row in items
        ],
    }


@router.get("/submissions", response_model=list[SubmissionResponse])
async def list_submissions(
    status_filter: str | None = Query(default=None, alias="status"),
    limit: int = Query(default=50, ge=1, le=200),
    offset: int = Query(default=0, ge=0),
    dev: DeveloperKey = Depends(get_current_developer),
    db: AsyncSession = Depends(get_db),
):
    query = (
        select(DeveloperSubmission)
        .where(DeveloperSubmission.developer_key_id == dev.id)
        .order_by(DeveloperSubmission.submitted_at.desc())
        .limit(limit)
        .offset(offset)
    )
    if status_filter:
        query = query.where(DeveloperSubmission.status == status_filter)

    result = await db.execute(query)
    submissions = result.scalars().all()
    return [
        SubmissionResponse(
            id=s.id,
            country_code=s.country_code,
            status=s.status,
            camera_count=s.camera_count,
            submitted_at=s.submitted_at,
            reviewed_at=s.reviewed_at,
            review_note=s.review_note,
        )
        for s in submissions
    ]


@router.get("/submissions/{submission_id}", response_model=SubmissionDetailResponse)
async def get_submission(
    submission_id: uuid.UUID,
    dev: DeveloperKey = Depends(get_current_developer),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(DeveloperSubmission).where(
            DeveloperSubmission.id == submission_id,
            DeveloperSubmission.developer_key_id == dev.id,
        )
    )
    submission = result.scalar_one_or_none()
    if submission is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Submission not found"
        )

    return SubmissionDetailResponse(
        id=submission.id,
        country_code=submission.country_code,
        status=submission.status,
        camera_count=submission.camera_count,
        submitted_at=submission.submitted_at,
        reviewed_at=submission.reviewed_at,
        review_note=submission.review_note,
        cameras_json=submission.cameras_json,
    )
