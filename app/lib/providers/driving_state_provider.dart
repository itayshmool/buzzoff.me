import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/orchestrator.dart';

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
