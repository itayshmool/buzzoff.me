import '../core/model/country.dart';
import '../core/model/installed_pack.dart';
import '../core/model/pack_meta.dart';
import '../data/database/camera_dao.dart';
import '../data/database/pack_loader.dart';
import 'pack_api_client.dart';
import 'pack_storage.dart';

class PackManager {
  final PackApiClient _apiClient;
  final PackStorage _storage;

  PackManager({required PackApiClient apiClient, required PackStorage storage})
      : _apiClient = apiClient,
        _storage = storage;

  Future<List<Country>> fetchCountries() => _apiClient.getCountries();

  Future<CameraDao> downloadAndInstall(String countryCode) async {
    final meta = await _apiClient.getPackMeta(countryCode);
    final bytes = await _apiClient.downloadPack(countryCode);

    if (!PackStorage.verifyChecksum(bytes, meta.checksumSha256)) {
      throw Exception(
          'Checksum mismatch for pack $countryCode v${meta.version}');
    }

    await _storage.savePack(countryCode, meta.version, bytes);
    await _storage.setActivePack(countryCode, meta.version);
    await _storage.setActiveCountry(countryCode);

    final path = _storage.getActivePackPath()!;
    return PackLoader.openPack(path);
  }

  Future<CameraDao> switchCountry(String countryCode) async {
    await _storage.setActiveCountry(countryCode);
    final path = _storage.getActivePackPath();
    if (path == null) {
      throw Exception('No installed pack for $countryCode');
    }
    return PackLoader.openPack(path);
  }

  Future<PackMeta?> checkForUpdate(String countryCode) async {
    final localVersion = _storage.getInstalledVersion(countryCode);
    if (localVersion == null) return null;

    final remoteMeta = await _apiClient.getPackMeta(countryCode);
    if (remoteMeta.version > localVersion) {
      return remoteMeta;
    }
    return null;
  }

  Future<CameraDao> updatePack(String countryCode) async {
    return downloadAndInstall(countryCode);
  }

  List<InstalledPack> getInstalledPacks() => _storage.getInstalledPacks();

  String? getActiveCountry() => _storage.getActiveCountry();

  Future<void> deleteInstalledPack(String countryCode) async {
    await _storage.deletePack(countryCode);
    if (_storage.getActiveCountry() == countryCode) {
      await _storage.setActiveCountry('');
    }
  }
}
