import uuid
from datetime import datetime

from geoalchemy2 import Geometry
from sqlalchemy import DateTime, ForeignKey, Integer, Float, String, Text, func
from sqlalchemy.dialects.postgresql import ARRAY, UUID
from sqlalchemy.orm import Mapped, mapped_column

from app.db.base import Base


class Camera(Base):
    __tablename__ = "cameras"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True), primary_key=True, default=uuid.uuid4
    )
    country_code: Mapped[str] = mapped_column(
        String(2), ForeignKey("countries.code"), nullable=False, index=True
    )
    location = mapped_column(Geometry("POINT", srid=4326), nullable=False)
    type: Mapped[str] = mapped_column(String(50), nullable=False)
    speed_limit: Mapped[int | None] = mapped_column(Integer)
    heading: Mapped[float | None] = mapped_column(Float)
    road_name: Mapped[str | None] = mapped_column(Text)
    linked_camera_id: Mapped[uuid.UUID | None] = mapped_column(UUID(as_uuid=True))
    confidence: Mapped[float] = mapped_column(Float, nullable=False, default=0.5)
    source_ids: Mapped[list[uuid.UUID]] = mapped_column(
        ARRAY(UUID(as_uuid=True)), nullable=False
    )
    last_verified: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), nullable=False, server_default=func.now(), onupdate=func.now()
    )
