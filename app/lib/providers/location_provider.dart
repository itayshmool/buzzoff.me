import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/location_service.dart';
import '../services/simulated_location_service.dart';
import 'simulation_provider.dart';

final locationServiceProvider = Provider<LocationService>((ref) {
  final simEnabled = ref.watch(simulationEnabledProvider);
  final LocationService service =
      simEnabled ? SimulatedLocationService() : LocationService();
  ref.onDispose(() => service.dispose());
  return service;
});

final locationStreamProvider = StreamProvider<LocationData>((ref) {
  final service = ref.watch(locationServiceProvider);
  return service.locationStream;
});
