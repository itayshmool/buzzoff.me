from __future__ import annotations

from pydantic import BaseModel


class DeveloperInfo(BaseModel):
    id: str
    name: str
    email: str
    key_prefix: str
    scopes: list[str]
    enabled: bool
    last_used_at: str | None = None
    created_at: str


class Country(BaseModel):
    code: str
    name: str
    name_local: str | None = None
    speed_unit: str = "kmh"
    enabled: bool = True


class Source(BaseModel):
    id: str
    country_code: str
    name: str
    adapter: str
    confidence: float
    enabled: bool
    last_fetched_at: str | None = None
    created_at: str


class Camera(BaseModel):
    id: str | None = None
    lat: float | None = None
    lon: float | None = None
    type: str = "fixed_speed"
    speed_limit: int | None = None
    heading: float | None = None
    road_name: str | None = None
    address: str | None = None


class CameraList(BaseModel):
    total: int
    items: list[Camera]


class Submission(BaseModel):
    id: str
    country_code: str
    status: str
    camera_count: int
    submitted_at: str
    reviewed_at: str | None = None
    review_note: str | None = None


class SubmissionDetail(Submission):
    cameras_json: list[dict]
