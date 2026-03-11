import logging

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.routes import countries, health, packs
from app.api.routes.admin_cameras import router as admin_cameras_router
from app.config import settings
from app.api.routes.admin_countries import router as admin_countries_router
from app.api.routes.admin_dashboard import router as admin_dashboard_router
from app.api.routes.admin_geocoding import router as admin_geocoding_router
from app.api.routes.admin_jobs import router as admin_jobs_router
from app.api.routes.admin_packs import router as admin_packs_router
from app.api.routes.admin_sources import router as admin_sources_router
from app.api.routes.auth import router as auth_router

app = FastAPI(title="BuzzOff API", version="0.1.0")
logger = logging.getLogger(__name__)


@app.on_event("startup")
def _log_admin_auth_config() -> None:
    if settings.admin_password == "changeme":
        logger.warning(
            "Admin auth: using default password. Set ADMIN_PASSWORD in production."
        )
    else:
        logger.info("Admin auth: custom password configured.")


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

# Admin API
app.include_router(auth_router, prefix="/admin/api", tags=["auth"])
app.include_router(admin_countries_router, prefix="/admin/api", tags=["admin-countries"])
app.include_router(admin_sources_router, prefix="/admin/api", tags=["admin-sources"])
app.include_router(admin_cameras_router, prefix="/admin/api", tags=["admin-cameras"])
app.include_router(admin_geocoding_router, prefix="/admin/api", tags=["admin-geocoding"])
app.include_router(admin_packs_router, prefix="/admin/api", tags=["admin-packs"])
app.include_router(admin_jobs_router, prefix="/admin/api", tags=["admin-jobs"])
app.include_router(admin_dashboard_router, prefix="/admin/api", tags=["admin-dashboard"])
