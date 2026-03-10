from fastapi import FastAPI

from app.api.routes import countries, health, packs

app = FastAPI(title="BuzzOff API", version="0.1.0")

app.include_router(health.router, prefix="/api/v1", tags=["health"])
app.include_router(countries.router, prefix="/api/v1", tags=["countries"])
app.include_router(packs.router, prefix="/api/v1", tags=["packs"])
