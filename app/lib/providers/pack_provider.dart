import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/model/installed_pack.dart';
import '../services/pack_storage.dart';

final packStorageProvider = Provider<PackStorage>((ref) {
  throw UnimplementedError('Must be overridden with actual base dir and prefs');
});

final activeCountryProvider =
    StateNotifierProvider<ActiveCountryNotifier, String?>((ref) {
  final storage = ref.watch(packStorageProvider);
  return ActiveCountryNotifier(storage);
});

class ActiveCountryNotifier extends StateNotifier<String?> {
  final PackStorage _storage;

  ActiveCountryNotifier(this._storage) : super(_storage.getActiveCountry()) {
    final active = _storage.getActiveCountry();
    // Treat empty string as null
    state = (active != null && active.isNotEmpty) ? active : null;
  }

  Future<void> setCountry(String countryCode) async {
    await _storage.setActiveCountry(countryCode);
    state = countryCode;
  }

  Future<void> clear() async {
    await _storage.setActiveCountry('');
    state = null;
  }
}

final installedPacksProvider = Provider<List<InstalledPack>>((ref) {
  final storage = ref.watch(packStorageProvider);
  // Re-read when active country changes (forces refresh after install/delete)
  ref.watch(activeCountryProvider);
  return storage.getInstalledPacks();
});
