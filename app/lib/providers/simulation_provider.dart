import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings_provider.dart';

const _key = 'simulation_enabled';

final simulationEnabledProvider =
    StateNotifierProvider<SimulationNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SimulationNotifier(prefs);
});

class SimulationNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;

  SimulationNotifier(this._prefs) : super(_prefs.getBool(_key) ?? false);

  void toggle() {
    state = !state;
    _prefs.setBool(_key, state);
  }
}
