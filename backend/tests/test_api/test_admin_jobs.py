import uuid
from datetime import datetime, timezone
from unittest.mock import AsyncMock, MagicMock

import pytest
from httpx import ASGITransport, AsyncClient

from app.api.deps import get_db
from app.main import app


@pytest.fixture
def client():
    return AsyncClient(transport=ASGITransport(app=app), base_url="http://test")


@pytest.fixture
async def auth_header(client):
    response = await client.post(
        "/admin/api/auth/login",
        json={"username": "admin", "password": "changeme"},
    )
    token = response.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


def _mock_job_run(
    job_type="fetch_sources",
    status="completed",
    items_processed=3,
    result_summary="Fetched 3 sources",
):
    j = MagicMock()
    j.id = uuid.uuid4()
    j.job_type = job_type
    j.status = status
    j.started_at = datetime.now(timezone.utc)
    j.finished_at = datetime.now(timezone.utc)
    j.result_summary = result_summary
    j.items_processed = items_processed
    return j


async def test_list_jobs(client, auth_header):
    jobs = [_mock_job_run(), _mock_job_run(job_type="merge_cameras")]

    mock_session = AsyncMock()
    mock_result = MagicMock()
    mock_result.scalars.return_value.all.return_value = jobs
    mock_session.execute = AsyncMock(return_value=mock_result)

    async def fake_db():
        yield mock_session

    app.dependency_overrides[get_db] = fake_db
    response = await client.get("/admin/api/jobs", headers=auth_header)
    app.dependency_overrides.clear()

    assert response.status_code == 200
    data = response.json()
    assert len(data) == 2


async def test_list_jobs_filter_by_type(client, auth_header):
    jobs = [_mock_job_run(job_type="fetch_sources")]

    mock_session = AsyncMock()
    mock_result = MagicMock()
    mock_result.scalars.return_value.all.return_value = jobs
    mock_session.execute = AsyncMock(return_value=mock_result)

    async def fake_db():
        yield mock_session

    app.dependency_overrides[get_db] = fake_db
    response = await client.get(
        "/admin/api/jobs?job_type=fetch_sources", headers=auth_header
    )
    app.dependency_overrides.clear()

    assert response.status_code == 200
    data = response.json()
    assert len(data) == 1
    assert data[0]["job_type"] == "fetch_sources"
