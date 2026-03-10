import uuid

import pytest

from app.services.merger import CameraInput, MergedCamera, merge_cameras


def _camera(
    lat: float,
    lon: float,
    source_id: str | None = None,
    confidence: float = 0.5,
    camera_type: str = "fixed_speed",
    speed_limit: int | None = None,
    heading: float | None = None,
    road_name: str | None = None,
) -> CameraInput:
    return CameraInput(
        lat=lat,
        lon=lon,
        source_id=source_id or str(uuid.uuid4()),
        confidence=confidence,
        type=camera_type,
        speed_limit=speed_limit,
        heading=heading,
        road_name=road_name,
    )


def test_single_camera_passes_through():
    cameras = [_camera(32.0, 34.0, source_id="s1")]
    result = merge_cameras(cameras)
    assert len(result) == 1
    assert result[0].lat == 32.0
    assert result[0].lon == 34.0
    assert result[0].source_ids == ["s1"]


def test_distant_cameras_not_merged():
    # ~100km apart — definitely not the same camera
    cameras = [
        _camera(32.0, 34.0, source_id="s1"),
        _camera(33.0, 35.0, source_id="s2"),
    ]
    result = merge_cameras(cameras)
    assert len(result) == 2


def test_nearby_cameras_merged():
    # Two cameras within 50m of each other (same location, tiny offset)
    cameras = [
        _camera(32.0000, 34.0000, source_id="s1", confidence=0.8),
        _camera(32.0001, 34.0001, source_id="s2", confidence=0.6),
    ]
    result = merge_cameras(cameras)
    assert len(result) == 1
    assert set(result[0].source_ids) == {"s1", "s2"}


def test_merged_camera_averages_position():
    cameras = [
        _camera(32.0000, 34.0000, source_id="s1"),
        _camera(32.0002, 34.0002, source_id="s2"),
    ]
    result = merge_cameras(cameras)
    assert len(result) == 1
    assert result[0].lat == pytest.approx(32.0001, abs=1e-6)
    assert result[0].lon == pytest.approx(34.0001, abs=1e-6)


def test_merged_camera_takes_max_confidence():
    cameras = [
        _camera(32.0000, 34.0000, source_id="s1", confidence=0.3),
        _camera(32.0001, 34.0001, source_id="s2", confidence=0.9),
    ]
    result = merge_cameras(cameras)
    assert result[0].confidence == 0.9


def test_merged_camera_takes_type_from_highest_confidence():
    cameras = [
        _camera(32.0000, 34.0000, source_id="s1", confidence=0.3, camera_type="fixed_speed"),
        _camera(32.0001, 34.0001, source_id="s2", confidence=0.9, camera_type="red_light"),
    ]
    result = merge_cameras(cameras)
    assert result[0].type == "red_light"


def test_merged_camera_takes_speed_limit_from_highest_confidence():
    cameras = [
        _camera(32.0000, 34.0000, source_id="s1", confidence=0.3, speed_limit=60),
        _camera(32.0001, 34.0001, source_id="s2", confidence=0.9, speed_limit=80),
    ]
    result = merge_cameras(cameras)
    assert result[0].speed_limit == 80


def test_merged_camera_fills_speed_limit_from_lower_confidence_if_missing():
    cameras = [
        _camera(32.0000, 34.0000, source_id="s1", confidence=0.3, speed_limit=60),
        _camera(32.0001, 34.0001, source_id="s2", confidence=0.9, speed_limit=None),
    ]
    result = merge_cameras(cameras)
    assert result[0].speed_limit == 60


def test_three_way_merge():
    cameras = [
        _camera(32.00000, 34.00000, source_id="s1", confidence=0.3),
        _camera(32.00010, 34.00010, source_id="s2", confidence=0.5),
        _camera(32.00020, 34.00020, source_id="s3", confidence=0.9),
    ]
    result = merge_cameras(cameras)
    assert len(result) == 1
    assert len(result[0].source_ids) == 3


def test_empty_input():
    result = merge_cameras([])
    assert result == []


def test_three_clusters():
    # Three cameras far apart — each its own cluster
    cameras = [
        _camera(32.0, 34.0, source_id="s1"),
        _camera(31.0, 35.0, source_id="s2"),
        _camera(30.0, 36.0, source_id="s3"),
    ]
    result = merge_cameras(cameras)
    assert len(result) == 3


def test_custom_threshold():
    # Two cameras ~15m apart — default 50m merges them, 10m doesn't
    cameras = [
        _camera(32.00000, 34.00000, source_id="s1"),
        _camera(32.00015, 34.00000, source_id="s2"),
    ]
    merged = merge_cameras(cameras, threshold_meters=50)
    assert len(merged) == 1

    separate = merge_cameras(cameras, threshold_meters=10)
    assert len(separate) == 2
