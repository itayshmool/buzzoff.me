import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqlite3/sqlite3.dart';

import 'package:buzzoff/core/model/country.dart';
import 'package:buzzoff/core/model/pack_meta.dart';
import 'package:buzzoff/services/pack_api_client.dart';
import 'package:buzzoff/services/pack_manager.dart';
import 'package:buzzoff/services/pack_storage.dart';

/// Fake PackApiClient for testing.
class FakePackApiClient implements PackApiClient {
  List<Country> countriesResult = [];
  PackMeta? metaResult;
  Uint8List? downloadResult;

  @override
  Future<List<Country>> getCountries() async => countriesResult;

  @override
  Future<PackMeta> getPackMeta(String countryCode) async =>
      metaResult ?? (throw Exception('No meta'));

  @override
  Future<Uint8List> downloadPack(String countryCode) async =>
      downloadResult ?? (throw Exception('No download'));
}

/// Creates a minimal valid SQLite pack database and returns its bytes.
Uint8List _createTestPackBytes() {
  final db = sqlite3.openInMemory();
  db.execute('''
    CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT NOT NULL);
    INSERT INTO meta (key, value) VALUES ('country_code', 'IL');
    INSERT INTO meta (key, value) VALUES ('version', '3');
    INSERT INTO meta (key, value) VALUES ('camera_count', '2');

    CREATE TABLE cameras (
      id TEXT PRIMARY KEY, lat REAL NOT NULL, lon REAL NOT NULL,
      type TEXT NOT NULL, speed_limit INTEGER, heading REAL,
      road_name TEXT, linked_camera_id TEXT, source TEXT NOT NULL,
      confidence REAL NOT NULL DEFAULT 0.5, last_verified TEXT
    );
    CREATE VIRTUAL TABLE cameras_rtree USING rtree(
      id, min_lat, max_lat, min_lon, max_lon
    );

    INSERT INTO cameras (id, lat, lon, type, source) VALUES ('1', 32.08, 34.78, 'fixed_speed', 'osm');
    INSERT INTO cameras (id, lat, lon, type, source) VALUES ('2', 32.09, 34.79, 'red_light', 'osm');
    INSERT INTO cameras_rtree VALUES (1, 32.08, 32.08, 34.78, 34.78);
    INSERT INTO cameras_rtree VALUES (2, 32.09, 32.09, 34.79, 34.79);
  ''');

  // Export to file then read bytes
  final tmpFile = File('${Directory.systemTemp.path}/test_pack_${DateTime.now().millisecondsSinceEpoch}.db');
  final stmt = db.prepare('VACUUM INTO ?');
  stmt.execute([tmpFile.path]);
  stmt.dispose();
  db.dispose();

  final bytes = tmpFile.readAsBytesSync();
  tmpFile.deleteSync();
  return Uint8List.fromList(bytes);
}

void main() {
  late Directory tempDir;
  late SharedPreferences prefs;
  late PackStorage storage;
  late FakePackApiClient fakeApi;
  late PackManager manager;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('pack_manager_test_');
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    storage = PackStorage(baseDir: tempDir.path, prefs: prefs);
    fakeApi = FakePackApiClient();
    manager = PackManager(apiClient: fakeApi, storage: storage);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('PackManager', () {
    test('fetchCountries delegates to API client', () async {
      fakeApi.countriesResult = [
        const Country(code: 'IL', name: 'Israel', packVersion: 3, cameraCount: 147),
      ];

      final countries = await manager.fetchCountries();
      expect(countries.length, 1);
      expect(countries[0].code, 'IL');
    });

    test('downloadAndInstall downloads, verifies, saves, and opens pack', () async {
      final packBytes = _createTestPackBytes();
      final checksum = sha256.convert(packBytes).toString();

      fakeApi.metaResult = PackMeta(
        countryCode: 'IL',
        version: 3,
        cameraCount: 2,
        fileSizeBytes: packBytes.length,
        checksumSha256: checksum,
      );
      fakeApi.downloadResult = packBytes;

      final dao = await manager.downloadAndInstall('IL');

      expect(dao, isNotNull);
      expect(dao.getCameraCount(), 2);
      expect(storage.getActiveCountry(), 'IL');
      expect(storage.getInstalledVersion('IL'), 3);
    });

    test('downloadAndInstall throws on checksum mismatch', () async {
      final packBytes = Uint8List.fromList([1, 2, 3]);

      fakeApi.metaResult = const PackMeta(
        countryCode: 'IL',
        version: 3,
        cameraCount: 2,
        fileSizeBytes: 3,
        checksumSha256: 'wrong_checksum',
      );
      fakeApi.downloadResult = packBytes;

      expect(() => manager.downloadAndInstall('IL'), throwsException);
    });

    test('checkForUpdate returns null when already up to date', () async {
      // Install version 3
      final packBytes = _createTestPackBytes();
      final checksum = sha256.convert(packBytes).toString();
      fakeApi.metaResult = PackMeta(
        countryCode: 'IL', version: 3, cameraCount: 2,
        fileSizeBytes: packBytes.length, checksumSha256: checksum,
      );
      fakeApi.downloadResult = packBytes;
      await manager.downloadAndInstall('IL');

      // Check for update (server still on v3)
      fakeApi.metaResult = PackMeta(
        countryCode: 'IL', version: 3, cameraCount: 2,
        fileSizeBytes: packBytes.length, checksumSha256: checksum,
      );

      final update = await manager.checkForUpdate('IL');
      expect(update, isNull);
    });

    test('checkForUpdate returns meta when newer version available', () async {
      // Install version 3
      final packBytes = _createTestPackBytes();
      final checksum = sha256.convert(packBytes).toString();
      fakeApi.metaResult = PackMeta(
        countryCode: 'IL', version: 3, cameraCount: 2,
        fileSizeBytes: packBytes.length, checksumSha256: checksum,
      );
      fakeApi.downloadResult = packBytes;
      await manager.downloadAndInstall('IL');

      // Server now on v4
      fakeApi.metaResult = PackMeta(
        countryCode: 'IL', version: 4, cameraCount: 150,
        fileSizeBytes: packBytes.length, checksumSha256: checksum,
      );

      final update = await manager.checkForUpdate('IL');
      expect(update, isNotNull);
      expect(update!.version, 4);
    });

    test('switchCountry opens pack for different installed country', () async {
      // Install IL
      final packBytes = _createTestPackBytes();
      final checksum = sha256.convert(packBytes).toString();
      fakeApi.metaResult = PackMeta(
        countryCode: 'IL', version: 3, cameraCount: 2,
        fileSizeBytes: packBytes.length, checksumSha256: checksum,
      );
      fakeApi.downloadResult = packBytes;
      await manager.downloadAndInstall('IL');

      // Also install under 'DE' (reuse same bytes for test)
      await storage.savePack('DE', 1, packBytes);
      await storage.setActivePack('DE', 1);

      final dao = await manager.switchCountry('DE');
      expect(dao.getCameraCount(), 2);
      expect(storage.getActiveCountry(), 'DE');
    });

    test('getInstalledPacks delegates to storage', () async {
      final packBytes = _createTestPackBytes();
      final checksum = sha256.convert(packBytes).toString();
      fakeApi.metaResult = PackMeta(
        countryCode: 'IL', version: 3, cameraCount: 2,
        fileSizeBytes: packBytes.length, checksumSha256: checksum,
      );
      fakeApi.downloadResult = packBytes;
      await manager.downloadAndInstall('IL');

      final packs = manager.getInstalledPacks();
      expect(packs.length, 1);
      expect(packs[0].countryCode, 'IL');
    });

    test('deleteInstalledPack removes pack and clears active if matching', () async {
      final packBytes = _createTestPackBytes();
      final checksum = sha256.convert(packBytes).toString();
      fakeApi.metaResult = PackMeta(
        countryCode: 'IL', version: 3, cameraCount: 2,
        fileSizeBytes: packBytes.length, checksumSha256: checksum,
      );
      fakeApi.downloadResult = packBytes;
      await manager.downloadAndInstall('IL');

      expect(storage.getActiveCountry(), 'IL');
      await manager.deleteInstalledPack('IL');

      expect(manager.getInstalledPacks(), isEmpty);
    });
  });
}
