import uuid
from datetime import datetime

from pydantic import BaseModel, Field


class SubmittedCamera(BaseModel):
    lat: float | None = None
    lon: float | None = None
    type: str = "fixed_speed"
    speed_limit: int | None = None
    heading: float | None = None
    road_name: str | None = None
    address: str | None = None


# --- Country CRUD ---

class CountryCreateRequest(BaseModel):
    code: str = Field(..., min_length=2, max_length=2, pattern=r"^[A-Z]{2}$")
    name: str = Field(..., min_length=1, max_length=100)
    name_local: str | None = None
    speed_unit: str = Field(default="kmh", pattern=r"^(kmh|mph)$")


class CountryUpdateRequest(BaseModel):
    name: str | None = Field(default=None, max_length=100)
    name_local: str | None = None
    speed_unit: str | None = Field(default=None, pattern=r"^(kmh|mph)$")


class CountryResponse(BaseModel):
    code: str
    name: str
    name_local: str | None = None
    speed_unit: str
    enabled: bool


# --- Source Management ---

class SourceCreateRequest(BaseModel):
    name: str = Field(..., min_length=1, max_length=200)
    adapter: str = "developer_api"
    config: dict = Field(default_factory=dict)
    confidence: float = Field(default=0.5, ge=0.0, le=1.0)


class SourceResponse(BaseModel):
    id: uuid.UUID
    country_code: str
    name: str
    adapter: str
    confidence: float
    enabled: bool
    last_fetched_at: datetime | None = None
    created_at: datetime


# --- Developer API ---

class DeveloperMeResponse(BaseModel):
    id: uuid.UUID
    name: str
    email: str
    key_prefix: str
    scopes: list[str]
    enabled: bool
    last_used_at: datetime | None = None
    created_at: datetime


class CameraSubmitRequest(BaseModel):
    cameras: list[SubmittedCamera] = Field(..., min_length=1, max_length=1000)


class SubmissionResponse(BaseModel):
    id: uuid.UUID
    country_code: str
    status: str
    camera_count: int
    submitted_at: datetime
    reviewed_at: datetime | None = None
    review_note: str | None = None


class SubmissionDetailResponse(SubmissionResponse):
    cameras_json: list[dict]


# --- Admin Key Management ---

class DeveloperKeyCreateRequest(BaseModel):
    name: str
    email: str
    scopes: list[str] = Field(
        default_factory=lambda: ["submit_cameras", "read_cameras"]
    )


class DeveloperKeyCreateResponse(BaseModel):
    id: uuid.UUID
    name: str
    email: str
    key_prefix: str
    scopes: list[str]
    enabled: bool
    created_at: datetime
    raw_api_key: str


class DeveloperKeyResponse(BaseModel):
    id: uuid.UUID
    name: str
    email: str
    key_prefix: str
    scopes: list[str]
    enabled: bool
    last_used_at: datetime | None = None
    created_at: datetime


# --- Admin Moderation ---

class SubmissionRejectRequest(BaseModel):
    note: str = Field(..., min_length=1, max_length=1000)


class AdminSubmissionResponse(SubmissionResponse):
    developer_name: str
    developer_email: str


class AdminSubmissionDetailResponse(AdminSubmissionResponse):
    cameras_json: list[dict]
