# Feature: BuzzOff Camera SDK (Python)

## Status: IN PROGRESS

## Overview
A Python client SDK (`buzzoff-sdk`) that wraps the BuzzOff Developer API, enabling programmatic management of countries, data sources, and camera submissions. Used by AI agents (Codex, Claude) and developers to onboard new countries and submit camera data without the admin dashboard.

## Problem
Currently:
- Country management requires the admin dashboard or raw HTTP calls
- Camera submission requires manually crafting API requests
- No programmatic way to do the full flow: create country → add source → submit cameras → check status
- The SDK reference PDF exists but there's no installable client library

## Solution
Python package `buzzoff-sdk` with:
- Full Developer API coverage (auth, countries, sources, cameras, submissions)
- Type-safe request/response models (Pydantic)
- CLI tool for quick operations
- Ready for AI agent integration (Claude, Codex)

---

## API Coverage

### Existing Endpoints (already in production)
| Method | Endpoint | SDK Method |
|--------|----------|------------|
| `GET` | `/me` | `client.me()` |
| `GET` | `/countries` | `client.list_countries()` |
| `GET` | `/countries/{code}/cameras` | `client.list_cameras(code)` |
| `POST` | `/countries/{code}/cameras` | `client.submit_cameras(code, cameras)` |
| `GET` | `/submissions` | `client.list_submissions()` |
| `GET` | `/submissions/{id}` | `client.get_submission(id)` |

### New Endpoints (added in this feature)
| Method | Endpoint | SDK Method | Scope |
|--------|----------|------------|-------|
| `POST` | `/countries` | `client.create_country(code, name, ...)` | `manage_countries` |
| `GET` | `/countries/{code}` | `client.get_country(code)` | any |
| `PUT` | `/countries/{code}` | `client.update_country(code, ...)` | `manage_countries` |
| `DELETE` | `/countries/{code}` | `client.delete_country(code)` | `manage_countries` |
| `GET` | `/countries/{code}/sources` | `client.list_sources(code)` | `manage_countries` |
| `POST` | `/countries/{code}/sources` | `client.create_source(code, ...)` | `manage_countries` |
| `DELETE` | `/countries/{code}/sources/{id}` | `client.delete_source(code, id)` | `manage_countries` |

---

## Package Structure

```
sdk/
├── pyproject.toml          # Package config (pip installable)
├── README.md               # Usage docs + examples
├── buzzoff/
│   ├── __init__.py         # Exports BuzzOffClient
│   ├── client.py           # Main client class (httpx-based)
│   ├── models.py           # Pydantic models for all request/response types
│   └── exceptions.py       # Custom exceptions (AuthError, NotFound, etc.)
└── examples/
    ├── onboard_country.py  # Full country onboarding example
    └── submit_cameras.py   # Camera submission example
```

## SDK Design

### Client Class
```python
from buzzoff import BuzzOffClient

client = BuzzOffClient(
    api_key="bzk_...",
    base_url="https://buzzoff-api.onrender.com",  # default
)

# Identity
me = client.me()

# Country CRUD
countries = client.list_countries()
de = client.create_country(code="DE", name="Germany", name_local="Deutschland")
client.update_country("DE", name_local="Deutschland")
country = client.get_country("DE")
client.delete_country("DE")

# Sources
sources = client.list_sources("DE")
source = client.create_source("DE", name="OSM Overpass", adapter="developer_api")
client.delete_source("DE", source.id)

# Cameras
submission = client.submit_cameras("DE", cameras=[
    {"lat": 52.52, "lon": 13.405, "type": "fixed_speed", "speed_limit": 50},
])

# Submissions
subs = client.list_submissions(status="pending")
detail = client.get_submission(sub_id)

# Camera query
cams = client.list_cameras("DE", type="fixed_speed", limit=100)
```

### Models (Pydantic)
```python
class Country:
    code: str
    name: str
    name_local: str | None
    speed_unit: str
    enabled: bool

class Source:
    id: str
    country_code: str
    name: str
    adapter: str
    confidence: float
    enabled: bool

class Camera:
    lat: float | None
    lon: float | None
    type: str
    speed_limit: int | None
    heading: float | None
    road_name: str | None
    address: str | None

class Submission:
    id: str
    country_code: str
    status: str
    camera_count: int
    submitted_at: str

class DeveloperInfo:
    id: str
    name: str
    email: str
    scopes: list[str]
```

### Exceptions
```python
class BuzzOffError(Exception): ...
class AuthenticationError(BuzzOffError): ...     # 401
class ForbiddenError(BuzzOffError): ...          # 403 (missing scope)
class NotFoundError(BuzzOffError): ...           # 404
class ConflictError(BuzzOffError): ...           # 409 (country exists)
class ValidationError(BuzzOffError): ...         # 422
class RateLimitError(BuzzOffError): ...          # 429
class ServerError(BuzzOffError): ...             # 5xx
```

---

## Files to Create

| File | Purpose |
|------|---------|
| `sdk/pyproject.toml` | Package metadata, dependencies (httpx, pydantic) |
| `sdk/README.md` | Usage documentation |
| `sdk/buzzoff/__init__.py` | Package exports |
| `sdk/buzzoff/client.py` | BuzzOffClient with all API methods |
| `sdk/buzzoff/models.py` | Pydantic request/response models |
| `sdk/buzzoff/exceptions.py` | Custom exception hierarchy |
| `sdk/examples/onboard_country.py` | Full onboarding flow example |
| `sdk/examples/submit_cameras.py` | Camera submission example |

## Files Already Modified (backend)

| File | Change |
|------|--------|
| `backend/app/api/routes/developer.py` | Added country CRUD + source endpoints + scope check |
| `backend/app/schemas/developer.py` | Added Country/Source request/response schemas |

---

## Dependencies

```toml
[project]
dependencies = [
    "httpx>=0.27",
    "pydantic>=2.0",
]
```

---

## Verification

1. `cd sdk && pip install -e .` — installs in development mode
2. `python -c "from buzzoff import BuzzOffClient"` — import works
3. Run examples against production API with a valid key
4. All methods return typed Pydantic models
5. Errors raise appropriate exceptions

---

## Scopes

| Scope | Grants Access To |
|-------|-----------------|
| `read_cameras` | `GET /countries`, `GET /countries/{code}`, `GET /countries/{code}/cameras` |
| `submit_cameras` | `POST /countries/{code}/cameras`, `GET /submissions` |
| `manage_countries` | Country CRUD, Source CRUD |

Default scopes for new keys: `["submit_cameras", "read_cameras"]`
Full access: `["submit_cameras", "read_cameras", "manage_countries"]`
