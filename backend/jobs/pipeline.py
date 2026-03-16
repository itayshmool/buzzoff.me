import json
import logging
from datetime import datetime, timezone

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

    # Record the pipeline run in job_runs
    finished = datetime.now(timezone.utc)
    all_ok = all(v == "completed" for v in results.values())

    async with async_session_factory() as session:
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

    logger.info("Pipeline finished: %s", results)
    return results
