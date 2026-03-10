import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/model/camera.dart';
import 'database_provider.dart';
import 'location_provider.dart';

final nearbyCamerasProvider = Provider<List<Camera>>((ref) {
  final dao = ref.watch(cameraDaoProvider);
  final locationAsync = ref.watch(locationStreamProvider);

  return locationAsync.when(
    data: (loc) {
      if (dao == null) return [];
      return dao.getCamerasInBounds(
        loc.latitude - 0.018,
        loc.latitude + 0.018,
        loc.longitude - 0.025,
        loc.longitude + 0.025,
      );
    },
    loading: () => [],
    error: (_, __) => [],
  );
});
