import hashlib
from collections.abc import AsyncGenerator
from datetime import datetime, timezone

from fastapi import Depends, Header, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.config import settings
from app.db.session import async_session_factory
from app.models.developer import DeveloperKey

_bearer_scheme = HTTPBearer()

ALGORITHM = "HS256"


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with async_session_factory() as session:
        yield session


async def get_current_admin(
    credentials: HTTPAuthorizationCredentials = Depends(_bearer_scheme),
) -> str:
    token = credentials.credentials
    try:
        payload = jwt.decode(token, settings.jwt_secret, algorithms=[ALGORITHM])
        username: str | None = payload.get("sub")
        if username is None:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid token",
            )
        return username
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid token",
        )


async def get_current_developer(
    x_api_key: str = Header(...),
    db: AsyncSession = Depends(get_db),
) -> DeveloperKey:
    key_hash = hashlib.sha256(x_api_key.encode()).hexdigest()
    result = await db.execute(
        select(DeveloperKey).where(
            DeveloperKey.api_key_hash == key_hash,
            DeveloperKey.enabled.is_(True),
        )
    )
    dev_key = result.scalar_one_or_none()
    if dev_key is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or disabled API key",
        )
    dev_key.last_used_at = datetime.now(timezone.utc)
    await db.commit()
    return dev_key
