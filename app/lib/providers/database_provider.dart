import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/camera_dao.dart';

final cameraDaoProvider = StateProvider<CameraDao?>((ref) => null);

final cameraCountProvider = Provider<int>((ref) {
  final dao = ref.watch(cameraDaoProvider);
  return dao?.getCameraCount() ?? 0;
});
