import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/model/installed_pack.dart';

class PackStorage {
  static const _keyActiveCountry = 'active_country';
  static const _keyVersionPrefix = 'pack_version_';

  final String _baseDir;
  final SharedPreferences _prefs;

  PackStorage({required String baseDir, required SharedPreferences prefs})
      : _baseDir = baseDir,
        _prefs = prefs;

  String _packsDir() => '$_baseDir/packs';

  String _countryDir(String countryCode) => '${_packsDir()}/$countryCode';

  String _versionPath(String countryCode, int version) =>
      '${_countryDir(countryCode)}/v$version.db';

  String _currentPath(String countryCode) =>
      '${_countryDir(countryCode)}/current.db';

  Future<void> savePack(String countryCode, int version, Uint8List bytes) async {
    final dir = Directory(_countryDir(countryCode));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    final file = File(_versionPath(countryCode, version));
    await file.writeAsBytes(bytes);
  }

  Future<void> setActivePack(String countryCode, int version) async {
    final versionFile = File(_versionPath(countryCode, version));
    final currentFile = File(_currentPath(countryCode));
    await versionFile.copy(currentFile.path);
    await _prefs.setInt('$_keyVersionPrefix$countryCode', version);
  }

  String? getActivePackPath() {
    final country = getActiveCountry();
    if (country == null) return null;
    final path = _currentPath(country);
    if (File(path).existsSync()) return path;
    return null;
  }

  String? getActiveCountry() {
    return _prefs.getString(_keyActiveCountry);
  }

  Future<void> setActiveCountry(String countryCode) async {
    await _prefs.setString(_keyActiveCountry, countryCode);
  }

  int? getInstalledVersion(String countryCode) {
    return _prefs.getInt('$_keyVersionPrefix$countryCode');
  }

  List<InstalledPack> getInstalledPacks() {
    final packsDir = Directory(_packsDir());
    if (!packsDir.existsSync()) return [];

    final packs = <InstalledPack>[];
    for (final entity in packsDir.listSync()) {
      if (entity is! Directory) continue;
      final countryCode = entity.path.split('/').last;
      final currentFile = File(_currentPath(countryCode));
      if (!currentFile.existsSync()) continue;

      final version = getInstalledVersion(countryCode) ?? 0;
      packs.add(InstalledPack(
        countryCode: countryCode,
        version: version,
        filePath: currentFile.path,
        installedAt: currentFile.statSync().modified,
      ));
    }
    return packs;
  }

  Future<void> deletePack(String countryCode) async {
    final dir = Directory(_countryDir(countryCode));
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    await _prefs.remove('$_keyVersionPrefix$countryCode');
  }

  static bool verifyChecksum(Uint8List bytes, String expectedSha256) {
    final digest = sha256.convert(bytes);
    return digest.toString() == expectedSha256;
  }
}
