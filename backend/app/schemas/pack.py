from pydantic import BaseModel


class PackMetaResponse(BaseModel):
    country_code: str
    version: int
    camera_count: int
    file_size_bytes: int
    checksum_sha256: str
