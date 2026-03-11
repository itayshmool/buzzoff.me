import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/proximity/proximity_engine.dart';
import '../services/alert_service.dart';
import '../services/orchestrator.dart';
import 'database_provider.dart';
import 'location_provider.dart';
import 'settings_provider.dart';

final drivingStateProvider =
    StateNotifierProvider<DrivingStateNotifier, DrivingState>((ref) {
  return DrivingStateNotifier();
});

class DrivingStateNotifier extends StateNotifier<DrivingState> {
  DrivingStateNotifier() : super(DrivingState.idle);

  void update(DrivingState newState) {
    state = newState;
  }
}

final alertServiceProvider = Provider<AlertService>((ref) {
  return AlertService();
});

final orchestratorProvider = Provider<Orchestrator?>((ref) {
  final dao = ref.watch(cameraDaoProvider);
  if (dao == null) return null;

  final locationService = ref.watch(locationServiceProvider);
  final alertService = ref.watch(alertServiceProvider);
  final settings = ref.watch(settingsProvider);
  final drivingNotifier = ref.read(drivingStateProvider.notifier);

  final engine = ProximityEngine(dao);

  final orchestrator = Orchestrator(
    proximityEngine: engine,
    locationService: locationService,
    alertService: alertService,
    minSpeedKmh: settings.activateAtSpeedKmh,
    sleepAfterMinutes: settings.sleepAfterMinutes,
    onStateChange: (state) => drivingNotifier.update(state),
  );

  ref.onDispose(() => orchestrator.dispose());
  return orchestrator;
});
