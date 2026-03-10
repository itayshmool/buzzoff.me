from fastapi import APIRouter, Depends, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_admin, get_db
from app.models.job_run import JobRun

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
