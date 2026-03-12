import logging

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.routes import countries, health, packs
from app.api.routes.admin_cameras import router as admin_cameras_router
from app.api.routes.admin_countries import router as admin_countries_router
from app.api.routes.admin_dashboard import router as admin_dashboard_router
from app.api.routes.admin_developers import router as admin_developers_router
from app.api.routes.admin_geocoding import router as admin_geocoding_router
from app.api.routes.admin_jobs import router as admin_jobs_router
from app.api.routes.admin_packs import router as admin_packs_router
from app.api.routes.admin_scheduler import router as admin_scheduler_router
from app.api.routes.admin_sources import router as admin_sources_router
from app.api.routes.admin_submissions import router as admin_submissions_router
from app.api.routes.auth import router as auth_router
from app.api.routes.developer import router as developer_router
from app.config import settings

app = FastAPI(title="BuzzOff API", version="0.1.0")
logger = logging.getLogger(__name__)


@app.on_event("startup")
async def _startup() -> None:
    if settings.admin_password == "changeme":
        logger.warning(
            "Admin auth: using default password. Set ADMIN_PASSWORD in production."
        )
    else:
        logger.info("Admin auth: custom password configured.")

    from app.services.scheduler import start_scheduler
    await start_scheduler()

    # Regenerate pack files if missing from disk (e.g. after Render redeploy)
    await _ensure_packs_on_disk()


async def _ensure_packs_on_disk() -> None:
    from pathlib import Path
    from sqlalchemy import select, func
    from app.db.session import async_session_factory
    from app.models.pack import Pack

    try:
        async with async_session_factory() as session:
            # Get the latest pack per country
            subq = (
                select(
                    Pack.country_code,
                    func.max(Pack.version).label("max_version"),
                )
                .group_by(Pack.country_code)
                .subquery()
            )
            result = await session.execute(
                select(Pack).join(
                    subq,
                    (Pack.country_code == subq.c.country_code)
                    & (Pack.version == subq.c.max_version),
                )
            )
            packs = result.scalars().all()

            missing = [p for p in packs if not Path(p.file_path).exists()]

            if not missing:
                logger.info("All %d pack files present on disk.", len(packs))
                return

            logger.warning(
                "%d/%d pack files missing on disk, regenerating...",
                len(missing), len(packs),
            )

        from jobs.generate_packs import generate_all_packs
        await generate_all_packs()
        logger.info("Pack regeneration complete.")
    except Exception:
        logger.exception("Failed to check/regenerate packs on startup")


@app.on_event("shutdown")
async def _shutdown() -> None:
    from app.services.scheduler import stop_scheduler
    await stop_scheduler()


app.add_middleware(
    CORSMiddleware,
    allow_origins=[o.strip() for o in settings.admin_cors_origins.split(",")],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Public API
app.include_router(health.router, prefix="/api/v1", tags=["health"])
app.include_router(countries.router, prefix="/api/v1", tags=["countries"])
app.include_router(packs.router, prefix="/api/v1", tags=["packs"])

# Developer API
app.include_router(developer_router, prefix="/api/v1/developer", tags=["developer"])

# Admin API
app.include_router(auth_router, prefix="/admin/api", tags=["auth"])
app.include_router(admin_countries_router, prefix="/admin/api", tags=["admin-countries"])
app.include_router(admin_sources_router, prefix="/admin/api", tags=["admin-sources"])
app.include_router(admin_cameras_router, prefix="/admin/api", tags=["admin-cameras"])
app.include_router(admin_geocoding_router, prefix="/admin/api", tags=["admin-geocoding"])
app.include_router(admin_packs_router, prefix="/admin/api", tags=["admin-packs"])
app.include_router(admin_jobs_router, prefix="/admin/api", tags=["admin-jobs"])
app.include_router(admin_developers_router, prefix="/admin/api", tags=["admin-developers"])
app.include_router(admin_submissions_router, prefix="/admin/api", tags=["admin-submissions"])
app.include_router(admin_dashboard_router, prefix="/admin/api", tags=["admin-dashboard"])
app.include_router(admin_scheduler_router, prefix="/admin/api", tags=["admin-scheduler"])
