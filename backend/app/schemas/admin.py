import uuid

from pydantic import BaseModel


class CountryCreate(BaseModel):
    code: str
    name: str
    name_local: str | None = None
    speed_unit: str = "kmh"
    enabled: bool = False


class CountryUpdate(BaseModel):
    name: str | None = None
    name_local: str | None = None
    speed_unit: str | None = None
    enabled: bool | None = None


class AdminCountryResponse(BaseModel):
    code: str
    name: str
    name_local: str | None = None
    speed_unit: str
    enabled: bool


class SourceCreate(BaseModel):
    name: str
    adapter: str
    config: dict
    schedule: str | None = None
    confidence: float = 0.5
    enabled: bool = True


class SourceUpdate(BaseModel):
    name: str | None = None
    adapter: str | None = None
    config: dict | None = None
    schedule: str | None = None
    confidence: float | None = None
    enabled: bool | None = None


class AdminSourceResponse(BaseModel):
    id: uuid.UUID
    country_code: str
    name: str
    adapter: str
    config: dict
    schedule: str | None = None
    confidence: float
    enabled: bool


class CameraCreate(BaseModel):
    lat: float
    lon: float
    type: str
    speed_limit: int | None = None
    heading: float | None = None
    road_name: str | None = None


class AdminCameraResponse(BaseModel):
    id: uuid.UUID
    lat: float
    lon: float
    type: str
    speed_limit: int | None = None
    heading: float | None = None
    road_name: str | None = None
    confidence: float
