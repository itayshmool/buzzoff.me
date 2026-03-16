import asyncio
import logging
from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, status
from pydantic import BaseModel, Field
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_admin, get_db
from app.models.scheduler_settings import SchedulerSettings
from app.services.scheduler import get_current_step, is_pipeline_running, reschedule

logger = logging.getLogger(__name__)
router = APIRouter()

ALLOWED_INTERVALS = {1, 3, 6, 12, 24}


class SchedulerResponse(BaseModel):
    enabled: bool
    interval_hours: int
    last_run_at: str | None
    next_run_at: str | None
    status: str  # idle, running, disabled
    current_step: str | None = None  # fetch_sources, merge_cameras, generate_packs


class SchedulerUpdate(BaseModel):
    enabled: bool | None = None
    interval_hours: int | None = Field(default=None)


@router.get("/scheduler")
async def get_scheduler_settings(
    _admin: str = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
) -> SchedulerResponse:
    result = await db.execute(select(SchedulerSettings).limit(1))
    settings = result.scalar_one_or_none()
    if settings is None:
        return SchedulerResponse(
            enabled=False, interval_hours=6,
            last_run_at=None, next_run_at=None, status="disabled",
        )

    if is_pipeline_running():
        current_status = "running"
    elif not settings.enabled:
        current_status = "disabled"
    else:
        current_status = "idle"

    return SchedulerResponse(
        enabled=settings.enabled,
        interval_hours=settings.interval_hours,
        last_run_at=settings.last_run_at.isoformat() if settings.last_run_at else None,
        next_run_at=settings.next_run_at.isoformat() if settings.next_run_at else None,
        status=current_status,
        current_step=get_current_step() if is_pipeline_running() else None,
    )


@router.put("/scheduler")
async def update_scheduler_settings(
    body: SchedulerUpdate,
    _admin: str = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
) -> SchedulerResponse:
    if body.interval_hours is not None and body.interval_hours not in ALLOWED_INTERVALS:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"interval_hours must be one of {sorted(ALLOWED_INTERVALS)}",
        )

    result = await db.execute(select(SchedulerSettings).limit(1))
    settings = result.scalar_one_or_none()
    if settings is None:
        raise HTTPException(status_code=404, detail="Scheduler settings not found")

    if body.enabled is not None:
        settings.enabled = body.enabled
    if body.interval_hours is not None:
        settings.interval_hours = body.interval_hours

    # Update next_run_at based on new settings
    if settings.enabled:
        settings.next_run_at = datetime.now(timezone.utc) + timedelta(hours=settings.interval_hours)
    else:
        settings.next_run_at = None

    await db.commit()
    await db.refresh(settings)

    # Reschedule the APScheduler job
    await reschedule(settings.enabled, settings.interval_hours)

    if is_pipeline_running():
        current_status = "running"
    elif not settings.enabled:
        current_status = "disabled"
    else:
        current_status = "idle"

    return SchedulerResponse(
        enabled=settings.enabled,
        interval_hours=settings.interval_hours,
        last_run_at=settings.last_run_at.isoformat() if settings.last_run_at else None,
        next_run_at=settings.next_run_at.isoformat() if settings.next_run_at else None,
        status=current_status,
    )


@router.post("/scheduler/run")
async def run_pipeline_now(
    _admin: str = Depends(get_current_admin),
):
    if is_pipeline_running():
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Pipeline is already running",
        )

    from app.services.scheduler import set_current_step

    # Mark as running immediately so subsequent polls see it
    import app.services.scheduler as sched_mod
    sched_mod._running = True
    set_current_step("starting")

    async def _run_in_background():
        from app.db.session import async_session_factory
        from jobs.pipeline import run_full_pipeline

        try:
            # Update last_run_at
            async with async_session_factory() as session:
                result = await session.execute(select(SchedulerSettings).limit(1))
                settings = result.scalar_one_or_none()
                if settings:
                    settings.last_run_at = datetime.now(timezone.utc)
                    if settings.enabled:
                        settings.next_run_at = datetime.now(timezone.utc) + timedelta(hours=settings.interval_hours)
                    await session.commit()

            await run_full_pipeline()
        except Exception:
            logger.exception("Background pipeline run failed")
        finally:
            sched_mod._running = False
            set_current_step(None)

    asyncio.create_task(_run_in_background())
    return {"status": "started"}
