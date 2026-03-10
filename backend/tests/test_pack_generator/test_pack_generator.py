import os
import sqlite3
from pathlib import Path

import pytest

from app.services.pack_generator import PackGenerator, PackMeta, PackCamera


@pytest.fixture
def tmp_pack_dir(tmp_path):
    return tmp_path


@pytest.fixture
def generator(tmp_pack_dir):
    return PackGenerator(output_dir=str(tmp_pack_dir))


@pytest.fixture
def meta():
    return PackMeta(
        country_code="IL",
        country_name="Israel",
        version=1,
        speed_unit="kmh",
        bounds_north=33.3,
        bounds_south=29.5,
        bounds_east=35.9,
        bounds_west=34.2,
    )


@pytest.fixture
def cameras():
    return [
        PackCamera(
            lat=32.0853, lon=34.7818, type="fixed_speed",
            speed_limit=60, heading=90.0, road_name="Ayalon",
        ),
        PackCamera(
            lat=31.7683, lon=35.2137, type="red_light",
            speed_limit=50, heading=None, road_name="Jaffa Rd",
        ),
        PackCamera(
            lat=32.794, lon=34.9896, type="fixed_speed",
            speed_limit=80, heading=180.0, road_name=None,
        ),
    ]


def test_generate_creates_file(generator, meta, cameras):
    result = generator.generate(meta, cameras)
    assert Path(result.file_path).exists()


def test_generate_returns_checksum(generator, meta, cameras):
    result = generator.generate(meta, cameras)
    assert len(result.checksum_sha256) == 64


def test_generate_returns_file_size(generator, meta, cameras):
    result = generator.generate(meta, cameras)
    assert result.file_size_bytes > 0
    assert result.file_size_bytes == os.path.getsize(result.file_path)


def test_generate_returns_camera_count(generator, meta, cameras):
    result = generator.generate(meta, cameras)
    assert result.camera_count == 3


def test_sqlite_has_meta_table(generator, meta, cameras):
    result = generator.generate(meta, cameras)
    conn = sqlite3.connect(result.file_path)
    cursor = conn.execute("SELECT key, value FROM meta")
    rows = {k: v for k, v in cursor.fetchall()}
    conn.close()
    assert rows["country_code"] == "IL"
    assert rows["country_name"] == "Israel"
    assert rows["version"] == "1"
    assert rows["speed_unit"] == "kmh"


def test_sqlite_has_cameras_table(generator, meta, cameras):
    result = generator.generate(meta, cameras)
    conn = sqlite3.connect(result.file_path)
    cursor = conn.execute("SELECT COUNT(*) FROM cameras")
    count = cursor.fetchone()[0]
    conn.close()
    assert count == 3


def test_sqlite_camera_data(generator, meta, cameras):
    result = generator.generate(meta, cameras)
    conn = sqlite3.connect(result.file_path)
    cursor = conn.execute("SELECT lat, lon, type, speed_limit, heading, road_name FROM cameras ORDER BY lat")
    rows = cursor.fetchall()
    conn.close()
    # Sorted by lat ascending: 31.7683, 32.0853, 32.794
    assert rows[0] == (31.7683, 35.2137, "red_light", 50, None, "Jaffa Rd")
    assert rows[1] == (32.0853, 34.7818, "fixed_speed", 60, 90.0, "Ayalon")
    assert rows[2] == (32.794, 34.9896, "fixed_speed", 80, 180.0, None)


def test_sqlite_has_rtree_index(generator, meta, cameras):
    result = generator.generate(meta, cameras)
    conn = sqlite3.connect(result.file_path)
    # R-tree spatial query: find cameras in a bounding box around Tel Aviv
    cursor = conn.execute(
        "SELECT c.lat, c.lon FROM cameras c JOIN cameras_rtree r ON c.id = r.id "
        "WHERE r.min_lat <= 32.1 AND r.max_lat >= 32.0 "
        "AND r.min_lon <= 34.8 AND r.max_lon >= 34.7"
    )
    rows = cursor.fetchall()
    conn.close()
    assert len(rows) == 1
    assert rows[0][0] == pytest.approx(32.0853)


def test_generate_empty_cameras(generator, meta):
    result = generator.generate(meta, [])
    assert result.camera_count == 0
    conn = sqlite3.connect(result.file_path)
    cursor = conn.execute("SELECT COUNT(*) FROM cameras")
    assert cursor.fetchone()[0] == 0
    conn.close()


def test_checksum_changes_with_different_data(generator, meta, tmp_pack_dir):
    cam1 = [PackCamera(lat=32.0, lon=34.0, type="fixed_speed")]
    cam2 = [PackCamera(lat=31.0, lon=35.0, type="red_light")]
    g1 = PackGenerator(output_dir=str(tmp_pack_dir / "a"))
    g2 = PackGenerator(output_dir=str(tmp_pack_dir / "b"))
    os.makedirs(tmp_pack_dir / "a", exist_ok=True)
    os.makedirs(tmp_pack_dir / "b", exist_ok=True)
    meta2 = PackMeta(country_code="IL", country_name="Israel", version=2, speed_unit="kmh")
    r1 = g1.generate(meta, cam1)
    r2 = g2.generate(meta2, cam2)
    assert r1.checksum_sha256 != r2.checksum_sha256


def test_filename_format(generator, meta, cameras):
    result = generator.generate(meta, cameras)
    filename = Path(result.file_path).name
    assert filename == "pack_IL_v1.db"
