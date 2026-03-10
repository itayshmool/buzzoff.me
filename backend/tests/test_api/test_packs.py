import os
import sqlite3
from unittest.mock import AsyncMock, MagicMock

import pytest
from httpx import ASGITransport, AsyncClient

from app.main import app


def _mock_pack(version=3, camera_count=148, file_size_bytes=45000,
               checksum_sha256="abc123", file_path="/tmp/test.db", country_code="IL"):
    p = MagicMock()
    p.country_code = country_code
    p.version = version
    p.camera_count = camera_count
    p.file_size_bytes = file_size_bytes
    p.checksum_sha256 = checksum_sha256
    p.file_path = file_path
    return p


@pytest.fixture
def client():
    return AsyncClient(transport=ASGITransport(app=app), base_url="http://test")


async def test_pack_meta_returns_latest(client):
    pack = _mock_pack()

    mock_session = AsyncMock()
    mock_result = MagicMock()
    mock_result.scalar_one_or_none.return_value = pack
    mock_session.execute = AsyncMock(return_value=mock_result)

    async def fake_db():
        yield mock_session

    from app.api.deps import get_db
    app.dependency_overrides[get_db] = fake_db

    response = await client.get("/api/v1/packs/IL/meta")
    app.dependency_overrides.clear()

    assert response.status_code == 200
    data = response.json()
    assert data["version"] == 3
    assert data["camera_count"] == 148
    assert data["checksum_sha256"] == "abc123"


async def test_pack_meta_404_when_no_pack(client):
    mock_session = AsyncMock()
    mock_result = MagicMock()
    mock_result.scalar_one_or_none.return_value = None
    mock_session.execute = AsyncMock(return_value=mock_result)

    async def fake_db():
        yield mock_session

    from app.api.deps import get_db
    app.dependency_overrides[get_db] = fake_db

    response = await client.get("/api/v1/packs/XX/meta")
    app.dependency_overrides.clear()

    assert response.status_code == 404


async def test_pack_download(client, tmp_path):
    # Create a real small SQLite file
    db_path = str(tmp_path / "test.db")
    conn = sqlite3.connect(db_path)
    conn.execute("CREATE TABLE t (id INTEGER)")
    conn.commit()
    conn.close()

    pack = _mock_pack(file_path=db_path)

    mock_session = AsyncMock()
    mock_result = MagicMock()
    mock_result.scalar_one_or_none.return_value = pack
    mock_session.execute = AsyncMock(return_value=mock_result)

    async def fake_db():
        yield mock_session

    from app.api.deps import get_db
    app.dependency_overrides[get_db] = fake_db

    response = await client.get("/api/v1/packs/IL/data")
    app.dependency_overrides.clear()

    assert response.status_code == 200
    assert response.headers["content-type"] == "application/octet-stream"
    assert len(response.content) > 0


async def test_pack_download_404_when_no_pack(client):
    mock_session = AsyncMock()
    mock_result = MagicMock()
    mock_result.scalar_one_or_none.return_value = None
    mock_session.execute = AsyncMock(return_value=mock_result)

    async def fake_db():
        yield mock_session

    from app.api.deps import get_db
    app.dependency_overrides[get_db] = fake_db

    response = await client.get("/api/v1/packs/XX/data")
    app.dependency_overrides.clear()

    assert response.status_code == 404
