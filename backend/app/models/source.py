import uuid
from datetime import datetime

from sqlalchemy import Boolean, DateTime, ForeignKey, Float, String, func
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class Source(Base):
    __tablename__ = "sources"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    country_code: Mapped[str] = mapped_column(
        String(2), ForeignKey("countries.code"), nullable=False
    )
    name: Mapped[str] = mapped_column(String(200), nullable=False)
    adapter: Mapped[str] = mapped_column(String(50), nullable=False)
    config: Mapped[dict] = mapped_column(JSONB, nullable=False)
    schedule: Mapped[str | None] = mapped_column(String(50))
    confidence: Mapped[float] = mapped_column(Float, nullable=False, default=0.5)
    enabled: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)
    last_fetched_at: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(), onupdate=func.now()
    )
