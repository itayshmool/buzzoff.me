import math
from dataclasses import dataclass, field


@dataclass
class CameraInput:
    lat: float
    lon: float
    source_id: str
    confidence: float = 0.5
    type: str = "fixed_speed"
    speed_limit: int | None = None
    heading: float | None = None
    road_name: str | None = None


@dataclass
class MergedCamera:
    lat: float
    lon: float
    type: str
    confidence: float
    source_ids: list[str] = field(default_factory=list)
    speed_limit: int | None = None
    heading: float | None = None
    road_name: str | None = None


def merge_cameras(
    cameras: list[CameraInput], threshold_meters: float = 50.0
) -> list[MergedCamera]:
    if not cameras:
        return []

    clusters: list[list[CameraInput]] = []
    assigned = [False] * len(cameras)

    for i, cam in enumerate(cameras):
        if assigned[i]:
            continue
        cluster = [cam]
        assigned[i] = True
        for j in range(i + 1, len(cameras)):
            if assigned[j]:
                continue
            if _haversine_meters(cam.lat, cam.lon, cameras[j].lat, cameras[j].lon) <= threshold_meters:
                cluster.append(cameras[j])
                assigned[j] = True
        clusters.append(cluster)

    return [_merge_cluster(c) for c in clusters]


def _merge_cluster(cluster: list[CameraInput]) -> MergedCamera:
    avg_lat = sum(c.lat for c in cluster) / len(cluster)
    avg_lon = sum(c.lon for c in cluster) / len(cluster)

    # Sort by confidence descending to pick primary
    by_confidence = sorted(cluster, key=lambda c: c.confidence, reverse=True)
    primary = by_confidence[0]

    # For optional fields, take from highest confidence that has a value
    speed_limit = next((c.speed_limit for c in by_confidence if c.speed_limit is not None), None)
    heading = next((c.heading for c in by_confidence if c.heading is not None), None)
    road_name = next((c.road_name for c in by_confidence if c.road_name is not None), None)

    return MergedCamera(
        lat=avg_lat,
        lon=avg_lon,
        type=primary.type,
        confidence=primary.confidence,
        source_ids=[c.source_id for c in cluster],
        speed_limit=speed_limit,
        heading=heading,
        road_name=road_name,
    )


def _haversine_meters(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    R = 6_371_000  # Earth radius in meters
    phi1 = math.radians(lat1)
    phi2 = math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlam = math.radians(lon2 - lon1)
    a = math.sin(dphi / 2) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlam / 2) ** 2
    return 2 * R * math.atan2(math.sqrt(a), math.sqrt(1 - a))
