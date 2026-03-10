import hashlib
import os
import sqlite3
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path


@dataclass
class PackMeta:
    country_code: str
    country_name: str
    version: int
    speed_unit: str = "kmh"
    bounds_north: float = 0.0
    bounds_south: float = 0.0
    bounds_east: float = 0.0
    bounds_west: float = 0.0


@dataclass
class PackCamera:
    lat: float
    lon: float
    type: str = "fixed_speed"
    speed_limit: int | None = None
    heading: float | None = None
    road_name: str | None = None


@dataclass
class PackResult:
    file_path: str
    camera_count: int
    file_size_bytes: int
    checksum_sha256: str


class PackGenerator:
    def __init__(self, output_dir: str):
        self._output_dir = output_dir

    def generate(self, meta: PackMeta, cameras: list[PackCamera]) -> PackResult:
        os.makedirs(self._output_dir, exist_ok=True)
        filename = f"pack_{meta.country_code}_v{meta.version}.db"
        file_path = os.path.join(self._output_dir, filename)

        # Remove existing file to start fresh
        if os.path.exists(file_path):
            os.remove(file_path)

        conn = sqlite3.connect(file_path)
        try:
            self._create_schema(conn)
            self._write_meta(conn, meta)
            self._write_cameras(conn, cameras)
            conn.commit()
        finally:
            conn.close()

        file_size = os.path.getsize(file_path)
        checksum = self._sha256(file_path)

        return PackResult(
            file_path=file_path,
            camera_count=len(cameras),
            file_size_bytes=file_size,
            checksum_sha256=checksum,
        )

    def _create_schema(self, conn: sqlite3.Connection):
        conn.executescript("""
            CREATE TABLE meta (
                key   TEXT PRIMARY KEY,
                value TEXT NOT NULL
            );

            CREATE TABLE cameras (
                id          INTEGER PRIMARY KEY AUTOINCREMENT,
                lat         REAL NOT NULL,
                lon         REAL NOT NULL,
                type        TEXT NOT NULL,
                speed_limit INTEGER,
                heading     REAL,
                road_name   TEXT
            );

            CREATE VIRTUAL TABLE cameras_rtree USING rtree(
                id,
                min_lat, max_lat,
                min_lon, max_lon
            );
        """)

    def _write_meta(self, conn: sqlite3.Connection, meta: PackMeta):
        generated_at = datetime.now(timezone.utc).isoformat()
        entries = [
            ("country_code", meta.country_code),
            ("country_name", meta.country_name),
            ("version", str(meta.version)),
            ("speed_unit", meta.speed_unit),
            ("bounds_north", str(meta.bounds_north)),
            ("bounds_south", str(meta.bounds_south)),
            ("bounds_east", str(meta.bounds_east)),
            ("bounds_west", str(meta.bounds_west)),
            ("generated_at", generated_at),
        ]
        conn.executemany("INSERT INTO meta (key, value) VALUES (?, ?)", entries)

    def _write_cameras(self, conn: sqlite3.Connection, cameras: list[PackCamera]):
        for cam in cameras:
            cursor = conn.execute(
                "INSERT INTO cameras (lat, lon, type, speed_limit, heading, road_name) "
                "VALUES (?, ?, ?, ?, ?, ?)",
                (cam.lat, cam.lon, cam.type, cam.speed_limit, cam.heading, cam.road_name),
            )
            row_id = cursor.lastrowid
            conn.execute(
                "INSERT INTO cameras_rtree (id, min_lat, max_lat, min_lon, max_lon) "
                "VALUES (?, ?, ?, ?, ?)",
                (row_id, cam.lat, cam.lat, cam.lon, cam.lon),
            )

    @staticmethod
    def _sha256(file_path: str) -> str:
        h = hashlib.sha256()
        with open(file_path, "rb") as f:
            for chunk in iter(lambda: f.read(8192), b""):
                h.update(chunk)
        return h.hexdigest()
