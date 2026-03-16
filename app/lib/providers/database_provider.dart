import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/proximity/proximity_engine.dart';

final cameraDaoProvider = StateProvider<CameraQueryPort?>((ref) => null);

final cameraCountProvider = Provider<int>((ref) {
  final dao = ref.watch(cameraDaoProvider);
  return dao?.getCameraCount() ?? 0;
});
