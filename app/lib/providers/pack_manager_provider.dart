import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/model/country.dart';
import '../services/pack_api_client.dart';
import '../services/pack_manager.dart';
import 'pack_provider.dart';

final packApiClientProvider = Provider<PackApiClient>((ref) {
  return PackApiClient();
});

final packManagerProvider = Provider<PackManager>((ref) {
  final apiClient = ref.watch(packApiClientProvider);
  final storage = ref.watch(packStorageProvider);
  return PackManager(apiClient: apiClient, storage: storage);
});

final countriesProvider = FutureProvider<List<Country>>((ref) async {
  final manager = ref.watch(packManagerProvider);
  return manager.fetchCountries();
});
