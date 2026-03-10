import pytest
from httpx import ASGITransport, AsyncClient

from app.main import app


@pytest.fixture
def client():
    return AsyncClient(transport=ASGITransport(app=app), base_url="http://test")


async def test_login_success(client):
    response = await client.post(
        "/admin/api/auth/login",
        json={"username": "admin", "password": "changeme"},
    )
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert data["token_type"] == "bearer"


async def test_login_wrong_password(client):
    response = await client.post(
        "/admin/api/auth/login",
        json={"username": "admin", "password": "wrong"},
    )
    assert response.status_code == 401
    assert response.json()["detail"] == "Invalid credentials"


async def test_login_wrong_username(client):
    response = await client.post(
        "/admin/api/auth/login",
        json={"username": "hacker", "password": "changeme"},
    )
    assert response.status_code == 401


async def test_protected_endpoint_without_token(client):
    response = await client.get("/admin/api/countries")
    assert response.status_code == 403  # HTTPBearer returns 403 when no credentials


async def test_protected_endpoint_with_invalid_token(client):
    response = await client.get(
        "/admin/api/countries",
        headers={"Authorization": "Bearer invalid-token"},
    )
    assert response.status_code == 401


async def test_protected_endpoint_with_valid_token(client):
    # Login first
    login_response = await client.post(
        "/admin/api/auth/login",
        json={"username": "admin", "password": "changeme"},
    )
    token = login_response.json()["access_token"]

    # Use token to access protected endpoint
    response = await client.get(
        "/admin/api/countries",
        headers={"Authorization": f"Bearer {token}"},
    )
    # Should not be 401 — may be 200 or other status depending on DB,
    # but auth should pass
    assert response.status_code != 401
