from __future__ import annotations

import httpx

from buzzoff.exceptions import (
    AuthenticationError,
    BuzzOffError,
    ConflictError,
    ForbiddenError,
    NotFoundError,
    RateLimitError,
    ServerError,
    ValidationError,
)
from buzzoff.models import Camera, CameraList, Country, DeveloperInfo, Source, Submission, SubmissionDetail

DEFAULT_BASE_URL = "https://buzzoff-api.onrender.com"
DEFAULT_TIMEOUT = 90.0  # Render cold starts can take a while


class BuzzOffClient:
    """Python client for the BuzzOff Developer API."""

    def __init__(
        self,
        api_key: str,
        base_url: str = DEFAULT_BASE_URL,
        timeout: float = DEFAULT_TIMEOUT,
    ):
        self._http = httpx.Client(
            base_url=f"{base_url.rstrip('/')}/api/v1/developer",
            headers={"X-API-Key": api_key},
            timeout=timeout,
        )

    def close(self) -> None:
        self._http.close()

    def __enter__(self) -> BuzzOffClient:
        return self

    def __exit__(self, *args) -> None:
        self.close()

    # ── Helpers ──────────────────────────────────────

    def _request(self, method: str, path: str, **kwargs) -> httpx.Response:
        resp = self._http.request(method, path, **kwargs)
        if resp.is_success:
            return resp
        self._raise_for_status(resp)

    def _raise_for_status(self, resp: httpx.Response) -> None:
        try:
            body = resp.json()
            detail = body.get("detail", resp.text)
        except Exception:
            detail = resp.text

        msg = f"HTTP {resp.status_code}: {detail}"
        error_map = {
            401: AuthenticationError,
            403: ForbiddenError,
            404: NotFoundError,
            409: ConflictError,
            422: ValidationError,
            429: RateLimitError,
        }
        exc_cls = error_map.get(resp.status_code)
        if exc_cls:
            raise exc_cls(msg, status_code=resp.status_code, detail=str(detail))
        if resp.status_code >= 500:
            raise ServerError(msg, status_code=resp.status_code, detail=str(detail))
        raise BuzzOffError(msg, status_code=resp.status_code, detail=str(detail))

    # ── Identity ─────────────────────────────────────

    def me(self) -> DeveloperInfo:
        """Get info about the authenticated developer key."""
        resp = self._request("GET", "/me")
        return DeveloperInfo.model_validate(resp.json())

    # ── Countries ────────────────────────────────────

    def list_countries(self) -> list[Country]:
        """List all enabled countries."""
        resp = self._request("GET", "/countries")
        return [Country.model_validate(c) for c in resp.json()]

    def get_country(self, code: str) -> Country:
        """Get a single country by code."""
        resp = self._request("GET", f"/countries/{code}")
        return Country.model_validate(resp.json())

    def create_country(
        self,
        code: str,
        name: str,
        name_local: str | None = None,
        speed_unit: str = "kmh",
    ) -> Country:
        """Create a new country. Requires `manage_countries` scope."""
        payload: dict = {"code": code, "name": name, "speed_unit": speed_unit}
        if name_local is not None:
            payload["name_local"] = name_local
        resp = self._request("POST", "/countries", json=payload)
        return Country.model_validate(resp.json())

    def update_country(
        self,
        code: str,
        name: str | None = None,
        name_local: str | None = None,
        speed_unit: str | None = None,
    ) -> Country:
        """Update a country. Requires `manage_countries` scope."""
        payload: dict = {}
        if name is not None:
            payload["name"] = name
        if name_local is not None:
            payload["name_local"] = name_local
        if speed_unit is not None:
            payload["speed_unit"] = speed_unit
        resp = self._request("PUT", f"/countries/{code}", json=payload)
        return Country.model_validate(resp.json())

    def delete_country(self, code: str) -> None:
        """Delete a country. Requires `manage_countries` scope."""
        self._request("DELETE", f"/countries/{code}")

    # ── Sources ──────────────────────────────────────

    def list_sources(self, country_code: str) -> list[Source]:
        """List data sources for a country. Requires `manage_countries` scope."""
        resp = self._request("GET", f"/countries/{country_code}/sources")
        return [Source.model_validate(s) for s in resp.json()]

    def create_source(
        self,
        country_code: str,
        name: str,
        adapter: str = "developer_api",
        config: dict | None = None,
        confidence: float = 0.5,
    ) -> Source:
        """Create a data source for a country. Requires `manage_countries` scope."""
        payload = {
            "name": name,
            "adapter": adapter,
            "config": config or {},
            "confidence": confidence,
        }
        resp = self._request("POST", f"/countries/{country_code}/sources", json=payload)
        return Source.model_validate(resp.json())

    def delete_source(self, country_code: str, source_id: str) -> None:
        """Delete a data source. Requires `manage_countries` scope."""
        self._request("DELETE", f"/countries/{country_code}/sources/{source_id}")

    # ── Cameras ──────────────────────────────────────

    def submit_cameras(
        self,
        country_code: str,
        cameras: list[dict | Camera],
    ) -> Submission:
        """Submit cameras for moderation. Max 1000 per request."""
        cam_dicts = [
            c.model_dump(exclude_none=True) if isinstance(c, Camera) else c
            for c in cameras
        ]
        resp = self._request(
            "POST",
            f"/countries/{country_code}/cameras",
            json={"cameras": cam_dicts},
        )
        return Submission.model_validate(resp.json())

    def list_cameras(
        self,
        country_code: str,
        type: str | None = None,
        limit: int = 50,
        offset: int = 0,
    ) -> CameraList:
        """Query existing cameras for a country."""
        params: dict = {"limit": limit, "offset": offset}
        if type is not None:
            params["type"] = type
        resp = self._request("GET", f"/countries/{country_code}/cameras", params=params)
        return CameraList.model_validate(resp.json())

    # ── Submissions ──────────────────────────────────

    def list_submissions(
        self,
        status: str | None = None,
        limit: int = 50,
        offset: int = 0,
    ) -> list[Submission]:
        """List your camera submissions."""
        params: dict = {"limit": limit, "offset": offset}
        if status is not None:
            params["status"] = status
        resp = self._request("GET", "/submissions", params=params)
        return [Submission.model_validate(s) for s in resp.json()]

    def get_submission(self, submission_id: str) -> SubmissionDetail:
        """Get details of a specific submission."""
        resp = self._request("GET", f"/submissions/{submission_id}")
        return SubmissionDetail.model_validate(resp.json())
