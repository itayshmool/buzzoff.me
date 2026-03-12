import asyncio
import logging
from datetime import datetime, timedelta, timezone

from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.interval import IntervalTrigger
from sqlalchemy import select

from app.db.session import async_session_factory
from app.models.scheduler_settings import SchedulerSettings

logger = logging.getLogger(__name__)

PIPELINE_JOB_ID = "auto_pipeline"

_scheduler: AsyncIOScheduler | None = None
_running = False


def get_scheduler() -> AsyncIOScheduler | None:
    return _scheduler


def is_pipeline_running() -> bool:
    return _running


async def _run_pipeline_wrapper() -> None:
    """Wrapper that updates scheduler_settings timestamps and prevents overlap."""
    global _running
    if _running:
        logger.warning("Pipeline already running, skipping this trigger")
        return

    _running = True
    try:
        from jobs.pipeline import run_full_pipeline

        # Update last_run_at
        async with async_session_factory() as session:
            result = await session.execute(select(SchedulerSettings).limit(1))
            settings = result.scalar_one_or_none()
            if settings:
                settings.last_run_at = datetime.now(timezone.utc)
                await session.commit()

        await run_full_pipeline()

        # Update next_run_at after successful run
        async with async_session_factory() as session:
            result = await session.execute(select(SchedulerSettings).limit(1))
            settings = result.scalar_one_or_none()
            if settings:
                settings.next_run_at = datetime.now(timezone.utc) + timedelta(hours=settings.interval_hours)
                await session.commit()

    except Exception:
        logger.exception("Pipeline wrapper failed")
    finally:
        _running = False


async def start_scheduler() -> None:
    """Initialize and start the scheduler from DB settings."""
    global _scheduler

    _scheduler = AsyncIOScheduler()

    async with async_session_factory() as session:
        result = await session.execute(select(SchedulerSettings).limit(1))
        settings = result.scalar_one_or_none()

    if settings is None:
        logger.warning("No scheduler_settings row found, scheduler disabled")
        _scheduler.start()
        return

    _scheduler.start()

    if settings.enabled:
        _add_pipeline_job(settings.interval_hours)
        logger.info("Scheduler started: pipeline every %dh", settings.interval_hours)
    else:
        logger.info("Scheduler started but pipeline is disabled")


def _add_pipeline_job(interval_hours: int) -> None:
    """Add or replace the pipeline job."""
    if _scheduler is None:
        return

    # Remove existing job if present
    try:
        _scheduler.remove_job(PIPELINE_JOB_ID)
    except Exception:
        pass

    _scheduler.add_job(
        _run_pipeline_wrapper,
        trigger=IntervalTrigger(hours=interval_hours),
        id=PIPELINE_JOB_ID,
        name="Auto Pipeline (fetch → merge → generate)",
        max_instances=1,
        replace_existing=True,
    )


async def reschedule(enabled: bool, interval_hours: int) -> None:
    """Update scheduler with new settings."""
    if _scheduler is None:
        return

    if not enabled:
        try:
            _scheduler.remove_job(PIPELINE_JOB_ID)
        except Exception:
            pass
        logger.info("Scheduler: pipeline disabled")
        return

    _add_pipeline_job(interval_hours)

    # Update next_run_at in DB
    async with async_session_factory() as session:
        result = await session.execute(select(SchedulerSettings).limit(1))
        settings = result.scalar_one_or_none()
        if settings:
            settings.next_run_at = datetime.now(timezone.utc) + timedelta(hours=interval_hours)
            await session.commit()

    logger.info("Scheduler: pipeline rescheduled to every %dh", interval_hours)


async def stop_scheduler() -> None:
    """Shut down the scheduler gracefully."""
    global _scheduler
    if _scheduler is not None:
        _scheduler.shutdown(wait=False)
        _scheduler = None
        logger.info("Scheduler stopped")
