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


def _mock_pack(
    country_code="IL",
    version=3,
    camera_count=148,
    file_size_bytes=48000,
    checksum_sha256="abc123",
):
    p = MagicMock()
    p.id = uuid.uuid4()
    p.country_code = country_code
    p.version = version
    p.camera_count = camera_count
    p.file_size_bytes = file_size_bytes
    p.file_path = f"packs/{country_code}_v{version}.db"
    p.checksum_sha256 = checksum_sha256
    p.published_at = datetime.now(timezone.utc)
    return p


async def test_list_packs(client, auth_header):
    packs = [_mock_pack(version=1), _mock_pack(version=2), _mock_pack(version=3)]

    mock_session = AsyncMock()
    mock_result = MagicMock()
    mock_result.scalars.return_value.all.return_value = packs
    mock_session.execute = AsyncMock(return_value=mock_result)

    async def fake_db():
        yield mock_session

    app.dependency_overrides[get_db] = fake_db
    response = await client.get("/admin/api/countries/IL/packs", headers=auth_header)
    app.dependency_overrides.clear()

    assert response.status_code == 200
    data = response.json()
    assert len(data) == 3


async def test_get_pack_detail(client, auth_header):
    pack = _mock_pack(version=3)

    mock_session = AsyncMock()
    mock_result = MagicMock()
    mock_result.scalar_one_or_none.return_value = pack
    mock_session.execute = AsyncMock(return_value=mock_result)

    async def fake_db():
        yield mock_session

    app.dependency_overrides[get_db] = fake_db
    response = await client.get("/admin/api/countries/IL/packs/3", headers=auth_header)
    app.dependency_overrides.clear()

    assert response.status_code == 200
    data = response.json()
    assert data["version"] == 3
    assert data["camera_count"] == 148


async def test_get_pack_detail_not_found(client, auth_header):
    mock_session = AsyncMock()
    mock_result = MagicMock()
    mock_result.scalar_one_or_none.return_value = None
    mock_session.execute = AsyncMock(return_value=mock_result)

    async def fake_db():
        yield mock_session

    app.dependency_overrides[get_db] = fake_db
    response = await client.get("/admin/api/countries/IL/packs/99", headers=auth_header)
    app.dependency_overrides.clear()

    assert response.status_code == 404
