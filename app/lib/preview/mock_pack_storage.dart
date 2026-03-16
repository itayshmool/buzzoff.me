import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/model/installed_pack.dart';
import '../services/pack_storage.dart';

/// Stub PackStorage for web preview. No filesystem access needed.
class MockPackStorage extends PackStorage {
  MockPackStorage(SharedPreferences prefs)
      : super(baseDir: '/mock', prefs: prefs);

  @override
  String? getActiveCountry() => 'IL';

  @override
  String? getActivePackPath() => null;

  @override
  int? getInstalledVersion(String countryCode) => 1;

  @override
  List<InstalledPack> getInstalledPacks() => [
        InstalledPack(
          countryCode: 'IL',
          version: 1,
          filePath: '/mock/IL/current.db',
          installedAt: DateTime.now(),
        ),
      ];

  @override
  Future<void> savePack(String countryCode, int version, Uint8List bytes) async {}

  @override
  Future<void> setActivePack(String countryCode, int version) async {}

  @override
  Future<void> setActiveCountry(String countryCode) async {}

  @override
  Future<void> deletePack(String countryCode) async {}
}
