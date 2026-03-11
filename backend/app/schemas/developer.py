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
