from pydantic import BaseModel


class CountryResponse(BaseModel):
    code: str
    name: str
    name_local: str | None = None
    speed_unit: str = "kmh"
    enabled: bool = False
    pack_version: int | None = None
    camera_count: int | None = None
