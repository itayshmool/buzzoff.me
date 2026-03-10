import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:buzzoff/services/pack_storage.dart';

void main() {
  late Directory tempDir;
  late SharedPreferences prefs;
  late PackStorage storage;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('pack_storage_test_');
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    storage = PackStorage(baseDir: tempDir.path, prefs: prefs);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('PackStorage', () {
    test('savePack writes file to correct path', () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      await storage.savePack('IL', 3, bytes);

      final file = File('${tempDir.path}/packs/IL/v3.db');
      expect(await file.exists(), isTrue);
      expect(await file.readAsBytes(), bytes);
    });

    test('setActivePack copies versioned file to current.db', () async {
      final bytes = Uint8List.fromList([10, 20, 30]);
      await storage.savePack('IL', 3, bytes);
      await storage.setActivePack('IL', 3);

      final currentFile = File('${tempDir.path}/packs/IL/current.db');
      expect(await currentFile.exists(), isTrue);
      expect(await currentFile.readAsBytes(), bytes);
    });

    test('getActivePackPath returns path when active country set', () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      await storage.savePack('IL', 3, bytes);
      await storage.setActivePack('IL', 3);
      await storage.setActiveCountry('IL');

      final path = storage.getActivePackPath();
      expect(path, isNotNull);
      expect(path, endsWith('/packs/IL/current.db'));
    });

    test('getActivePackPath returns null when no active country', () {
      final path = storage.getActivePackPath();
      expect(path, isNull);
    });

    test('getActiveCountry and setActiveCountry persist via SharedPreferences', () async {
      expect(storage.getActiveCountry(), isNull);

      await storage.setActiveCountry('IL');
      expect(storage.getActiveCountry(), 'IL');

      await storage.setActiveCountry('DE');
      expect(storage.getActiveCountry(), 'DE');
    });

    test('getInstalledPacks returns list of installed packs', () async {
      await storage.savePack('IL', 3, Uint8List.fromList([1, 2, 3]));
      await storage.setActivePack('IL', 3);
      await storage.savePack('DE', 1, Uint8List.fromList([4, 5, 6]));
      await storage.setActivePack('DE', 1);

      final packs = storage.getInstalledPacks();
      expect(packs.length, 2);

      final codes = packs.map((p) => p.countryCode).toSet();
      expect(codes, containsAll(['IL', 'DE']));
    });

    test('deletePack removes country directory', () async {
      await storage.savePack('IL', 3, Uint8List.fromList([1, 2, 3]));
      await storage.setActivePack('IL', 3);

      final dir = Directory('${tempDir.path}/packs/IL');
      expect(await dir.exists(), isTrue);

      await storage.deletePack('IL');
      expect(await dir.exists(), isFalse);
    });

    test('verifyChecksum returns true for matching SHA-256', () {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      final expectedHash = sha256.convert(bytes).toString();

      expect(PackStorage.verifyChecksum(bytes, expectedHash), isTrue);
    });

    test('verifyChecksum returns false for mismatched SHA-256', () {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5]);
      expect(PackStorage.verifyChecksum(bytes, 'wrong_hash'), isFalse);
    });

    test('getInstalledVersion returns version from current pack', () async {
      await storage.savePack('IL', 3, Uint8List.fromList([1, 2, 3]));
      await storage.setActivePack('IL', 3);

      expect(storage.getInstalledVersion('IL'), 3);
    });

    test('getInstalledVersion returns null for non-installed country', () {
      expect(storage.getInstalledVersion('XX'), isNull);
    });
  });
}
