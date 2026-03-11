import hashlib
import secrets
import uuid

from fastapi import APIRouter, Depends, HTTPException, Response, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.api.deps import get_current_admin, get_db
from app.models.developer import DeveloperKey
from app.schemas.developer import (
    DeveloperKeyCreateRequest,
    DeveloperKeyCreateResponse,
    DeveloperKeyResponse,
)

router = APIRouter()


@router.get("/developer-keys", response_model=list[DeveloperKeyResponse])
async def list_developer_keys(
    _admin: str = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(DeveloperKey).order_by(DeveloperKey.created_at.desc())
    )
    keys = result.scalars().all()
    return [
        DeveloperKeyResponse(
            id=k.id,
            name=k.name,
            email=k.email,
            key_prefix=k.key_prefix,
            scopes=k.scopes,
            enabled=k.enabled,
            last_used_at=k.last_used_at,
            created_at=k.created_at,
        )
        for k in keys
    ]


@router.post(
    "/developer-keys",
    response_model=DeveloperKeyCreateResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_developer_key(
    body: DeveloperKeyCreateRequest,
    _admin: str = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    raw_key = f"bzk_{secrets.token_urlsafe(32)}"
    key_hash = hashlib.sha256(raw_key.encode()).hexdigest()
    key_prefix = raw_key[:8]

    dev_key = DeveloperKey(
        name=body.name,
        email=body.email,
        api_key_hash=key_hash,
        key_prefix=key_prefix,
        scopes=body.scopes,
    )
    db.add(dev_key)
    await db.commit()
    await db.refresh(dev_key)

    return DeveloperKeyCreateResponse(
        id=dev_key.id,
        name=dev_key.name,
        email=dev_key.email,
        key_prefix=key_prefix,
        scopes=dev_key.scopes,
        enabled=dev_key.enabled,
        created_at=dev_key.created_at,
        raw_api_key=raw_key,
    )


@router.delete(
    "/developer-keys/{key_id}", status_code=status.HTTP_204_NO_CONTENT
)
async def revoke_developer_key(
    key_id: uuid.UUID,
    _admin: str = Depends(get_current_admin),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(DeveloperKey).where(DeveloperKey.id == key_id)
    )
    key = result.scalar_one_or_none()
    if key is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Key not found"
        )

    key.enabled = False
    await db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
