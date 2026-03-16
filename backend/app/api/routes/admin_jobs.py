import asyncio
import json
import logging
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_admin, get_db
from app.db.session import async_session_factory
from app.models.country import Country
from app.models.job_run import JobRun

logger = logging.getLogger(__name__)
router = APIRouter()


@router.get("/jobs")
async def list_jobs(
    job_type: str | None = Query(default=None),
    limit: int = Query(default=50, ge=1, le=200),
    _admin: str = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    query = select(JobRun).order_by(JobRun.started_at.desc()).limit(limit)
    if job_type is not None:
        query = query.where(JobRun.job_type == job_type)

    result = await db.execute(query)
    jobs = result.scalars().all()
    return [
        {
            "id": str(j.id),
            "job_type": j.job_type,
            "status": j.status,
            "started_at": j.started_at.isoformat() if j.started_at else None,
            "finished_at": j.finished_at.isoformat() if j.finished_at else None,
            "result_summary": j.result_summary,
            "items_processed": j.items_processed,
        }
        for j in jobs
    ]


@router.post("/jobs/run/{job_type}")
async def trigger_job(
    job_type: str,
    _admin: str = Depends(get_current_admin),
):
    allowed = {"fetch_sources", "merge_cameras", "generate_packs"}
    if job_type not in allowed:
        from fastapi import HTTPException, status
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"Unknown job type. Allowed: {allowed}")

    from jobs.fetch_sources import fetch_all_sources
    from jobs.merge_cameras import merge_all_countries
    from jobs.generate_packs import generate_all_packs

    runners = {
        "fetch_sources": fetch_all_sources,
        "merge_cameras": merge_all_countries,
        "generate_packs": generate_all_packs,
    }

    runner = runners[job_type]
    started = datetime.now(timezone.utc)
    try:
        await runner()
        finished = datetime.now(timezone.utc)
        async with async_session_factory() as session:
            job = JobRun(
                job_type=job_type,
                status="completed",
                started_at=started,
                finished_at=finished,
                result_summary=json.dumps({job_type: "completed"}),
                items_processed=1,
            )
            session.add(job)
            await session.commit()
        return {"status": "completed", "job_type": job_type}
    except Exception as e:
        logger.exception("Job %s failed", job_type)
        finished = datetime.now(timezone.utc)
        try:
            async with async_session_factory() as session:
                job = JobRun(
                    job_type=job_type,
                    status="failed",
                    started_at=started,
                    finished_at=finished,
                    result_summary=json.dumps({job_type: f"failed: {e}"}),
                    items_processed=0,
                )
                session.add(job)
                await session.commit()
        except Exception:
            logger.exception("Failed to log job_run for %s", job_type)
        return {"status": "failed", "job_type": job_type, "error": str(e)}


@router.post("/jobs/run/pipeline/{country_code}")
async def trigger_country_pipeline(
    country_code: str,
    _admin: str = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    code = country_code.upper()
    result = await db.execute(
        select(Country).where(Country.code == code, Country.enabled.is_(True))
    )
    country = result.scalar_one_or_none()
    if not country:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Country '{code}' not found or not enabled",
        )

    from jobs.fetch_sources import fetch_all_sources
    from jobs.merge_cameras import merge_all_countries
    from jobs.generate_packs import generate_all_packs

    steps = {}
    for name, runner in [
        ("fetch_sources", lambda: fetch_all_sources(country_code=code)),
        ("merge_cameras", lambda: merge_all_countries(country_code=code)),
        ("generate_packs", lambda: generate_all_packs(country_code=code)),
    ]:
        try:
            await runner()
            steps[name] = "completed"
        except Exception as e:
            logger.exception("Pipeline step %s failed for %s", name, code)
            steps[name] = f"failed: {e}"
            break

    return {"country_code": code, "steps": steps}
