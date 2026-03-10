from abc import ABC, abstractmethod
from dataclasses import dataclass


@dataclass
class RawCameraRecord:
    lat: float | None = None
    lon: float | None = None
    address: str | None = None
    type: str = "fixed_speed"
    speed_limit: int | None = None
    heading: float | None = None
    road_name: str | None = None
    external_id: str | None = None
    raw_data: dict | None = None


class SourceAdapter(ABC):
    @abstractmethod
    async def fetch(self, config: dict) -> list[RawCameraRecord]:
        pass
