import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_admin, get_db
from app.models.developer import DeveloperKey, DeveloperSubmission
from app.models.raw_camera import RawCamera
from app.models.source import Source
from app.schemas.developer import (
    AdminSubmissionDetailResponse,
    AdminSubmissionResponse,
    SubmissionRejectRequest,
)

router = APIRouter()

DEVELOPER_SOURCE_ADAPTER = "developer_api"
DEVELOPER_SOURCE_CONFIDENCE = 0.4


@router.get("/submissions", response_model=list[AdminSubmissionResponse])
async def list_submissions(
    status_filter: str | None = Query(default="pending", alias="status"),
    limit: int = Query(default=50, ge=1, le=200),
    _admin: str = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    query = (
        select(DeveloperSubmission, DeveloperKey.name, DeveloperKey.email)
        .join(DeveloperKey, DeveloperSubmission.developer_key_id == DeveloperKey.id)
        .order_by(DeveloperSubmission.submitted_at.desc())
        .limit(limit)
    )
    if status_filter:
        query = query.where(DeveloperSubmission.status == status_filter)

    result = await db.execute(query)
    rows = result.all()

    return [
        AdminSubmissionResponse(
            id=s.id,
            country_code=s.country_code,
            status=s.status,
            camera_count=s.camera_count,
            submitted_at=s.submitted_at,
            reviewed_at=s.reviewed_at,
            review_note=s.review_note,
            developer_name=dev_name,
            developer_email=dev_email,
        )
        for s, dev_name, dev_email in rows
    ]


@router.get(
    "/submissions/{submission_id}",
    response_model=AdminSubmissionDetailResponse,
)
async def get_submission_detail(
    submission_id: uuid.UUID,
    _admin: str = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(DeveloperSubmission, DeveloperKey.name, DeveloperKey.email)
        .join(DeveloperKey, DeveloperSubmission.developer_key_id == DeveloperKey.id)
        .where(DeveloperSubmission.id == submission_id)
    )
    row = result.one_or_none()
    if row is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Submission not found"
        )

    s, dev_name, dev_email = row
    return AdminSubmissionDetailResponse(
        id=s.id,
        country_code=s.country_code,
        status=s.status,
        camera_count=s.camera_count,
        submitted_at=s.submitted_at,
        reviewed_at=s.reviewed_at,
        review_note=s.review_note,
        developer_name=dev_name,
        developer_email=dev_email,
        cameras_json=s.cameras_json,
    )


@router.post("/submissions/{submission_id}/approve")
async def approve_submission(
    submission_id: uuid.UUID,
    _admin: str = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(DeveloperSubmission).where(
            DeveloperSubmission.id == submission_id
        )
    )
    submission = result.scalar_one_or_none()
    if submission is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Submission not found"
        )
    if submission.status != "pending":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Submission is not pending",
        )

    # Find or create synthetic source for developer_api
    source_result = await db.execute(
        select(Source).where(
            Source.country_code == submission.country_code,
            Source.adapter == DEVELOPER_SOURCE_ADAPTER,
        )
    )
    source = source_result.scalar_one_or_none()
    if source is None:
        source = Source(
            country_code=submission.country_code,
            name=f"Developer API ({submission.country_code})",
            adapter=DEVELOPER_SOURCE_ADAPTER,
            config={"type": "developer_submissions"},
            confidence=DEVELOPER_SOURCE_CONFIDENCE,
            enabled=True,
        )
        db.add(source)
        await db.flush()

    # Insert cameras into raw_cameras
    for cam in submission.cameras_json:
        has_coords = cam.get("lat") is not None and cam.get("lon") is not None
        raw = RawCamera(
            source_id=source.id,
            country_code=submission.country_code,
            lat=cam.get("lat"),
            lon=cam.get("lon"),
            address=cam.get("address"),
            type=cam.get("type", "fixed_speed"),
            speed_limit=cam.get("speed_limit"),
            heading=cam.get("heading"),
            road_name=cam.get("road_name"),
            raw_data={"submission_id": str(submission.id)},
            geocoded=has_coords,
        )
        db.add(raw)

    submission.status = "approved"
    submission.reviewed_at = datetime.now(timezone.utc)
    submission.reviewer = _admin
    await db.commit()

    return {
        "id": str(submission.id),
        "status": "approved",
        "cameras_inserted": len(submission.cameras_json),
    }


@router.post("/submissions/{submission_id}/reject")
async def reject_submission(
    submission_id: uuid.UUID,
    body: SubmissionRejectRequest,
    _admin: str = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(DeveloperSubmission).where(
            DeveloperSubmission.id == submission_id
        )
    )
    submission = result.scalar_one_or_none()
    if submission is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Submission not found"
        )
    if submission.status != "pending":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Submission is not pending",
        )

    submission.status = "rejected"
    submission.reviewed_at = datetime.now(timezone.utc)
    submission.reviewer = _admin
    submission.review_note = body.note
    await db.commit()

    return {"id": str(submission.id), "status": "rejected"}
