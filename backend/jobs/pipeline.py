import json
import logging
from datetime import datetime, timezone

from sqlalchemy import select

from app.db.session import async_session_factory
from app.models.job_run import JobRun
from app.services.scheduler import set_current_step

logger = logging.getLogger(__name__)


async def run_full_pipeline() -> dict[str, str]:
    """Run fetch → merge → generate in sequence. Log to JobRun table."""
    from jobs.fetch_sources import fetch_all_sources
    from jobs.merge_cameras import merge_all_countries
    from jobs.generate_packs import generate_all_packs

    steps = [
        ("fetch_sources", fetch_all_sources),
        ("merge_cameras", merge_all_countries),
        ("generate_packs", generate_all_packs),
    ]

    results: dict[str, str] = {}
    started = datetime.now(timezone.utc)

    # Create job_run record immediately as "running" so it always appears in logs
    job_id = None
    try:
        async with async_session_factory() as session:
            job = JobRun(
                job_type="auto_pipeline",
                status="running",
                started_at=started,
                result_summary=json.dumps({}),
                items_processed=0,
            )
            session.add(job)
            await session.commit()
            await session.refresh(job)
            job_id = job.id
    except Exception:
        logger.exception("Failed to create initial job_run record")

    for step_name, runner in steps:
        set_current_step(step_name)
        logger.info("Pipeline step: %s — starting", step_name)
        try:
            await runner()
            results[step_name] = "completed"
            logger.info("Pipeline step: %s — completed", step_name)
        except Exception as e:
            results[step_name] = f"failed: {e}"
            logger.exception("Pipeline step: %s — failed", step_name)

    set_current_step(None)

    # Update the job_run record with final results
    finished = datetime.now(timezone.utc)
    all_ok = all(v == "completed" for v in results.values())

    try:
        async with async_session_factory() as session:
            if job_id:
                result = await session.execute(
                    select(JobRun).where(JobRun.id == job_id)
                )
                job = result.scalar_one_or_none()
                if job:
                    job.status = "completed" if all_ok else "failed"
                    job.finished_at = finished
                    job.result_summary = json.dumps(results)
                    job.items_processed = sum(1 for v in results.values() if v == "completed")
                    await session.commit()
            else:
                # Fallback: create a new record if initial one failed
                job = JobRun(
                    job_type="auto_pipeline",
                    status="completed" if all_ok else "failed",
                    started_at=started,
                    finished_at=finished,
                    result_summary=json.dumps(results),
                    items_processed=sum(1 for v in results.values() if v == "completed"),
                )
                session.add(job)
                await session.commit()
    except Exception:
        logger.exception("Failed to update job_run record")

    logger.info("Pipeline finished: %s", results)
    return results
