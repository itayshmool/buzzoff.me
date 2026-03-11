import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/model/camera.dart';
import '../../providers/driving_state_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/nearby_cameras_provider.dart';
import '../../services/foreground_task.dart';
import '../widgets/camera_marker.dart';
import '../widgets/status_bar.dart';
import '../widgets/zoom_controls.dart';
import 'settings_screen.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  double _zoom = 14.0;
  bool _serviceStarted = false;
  bool _hasInitialFix = false;

  // Default to Tel Aviv until GPS provides a position
  static const _defaultCenter = LatLng(32.0853, 34.7818);

  @override
  void initState() {
    super.initState();
    _startServices();
  }

  Future<void> _startServices() async {
    if (_serviceStarted) return;
    _serviceStarted = true;

    // Request location permission
    final locationService = ref.read(locationServiceProvider);
    await locationService.requestPermission();

    // Start foreground service (shows persistent notification)
    await ForegroundTaskService.start();

    // Start the orchestrator monitoring (auto-detects driving)
    final orchestrator = ref.read(orchestratorProvider);
    await orchestrator?.startMonitoring();
  }

  @override
  Widget build(BuildContext context) {
    final locationAsync = ref.watch(locationStreamProvider);
    final drivingState = ref.watch(drivingStateProvider);
    final cameras = ref.watch(nearbyCamerasProvider);

    final center = locationAsync.when(
      data: (loc) {
        final pos = LatLng(loc.latitude, loc.longitude);
        if (!_hasInitialFix) {
          _hasInitialFix = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _mapController.move(pos, _zoom);
            }
          });
        }
        return pos;
      },
      loading: () => _defaultCenter,
      error: (_, __) => _defaultCenter,
    );

    return WithForegroundTask(
      child: Scaffold(
        body: Stack(
          children: [
            // Map
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: _zoom,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.buzzoff.app',
                ),
                // Camera markers
                MarkerLayer(
                  markers: cameras.map(_buildCameraMarker).toList(),
                ),
                // User position marker
                MarkerLayer(
                  markers: [
                    Marker(
                      point: center,
                      width: 20,
                      height: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.shade600,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Status bar at top
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              left: 0,
              right: 0,
              child: Center(child: StatusBar(state: drivingState)),
            ),

            // Zoom + settings controls
            Positioned(
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 24,
              child: ZoomControls(
                onZoomIn: () {
                  _zoom = (_zoom + 1).clamp(3.0, 18.0);
                  _mapController.move(
                    _mapController.camera.center,
                    _zoom,
                  );
                },
                onZoomOut: () {
                  _zoom = (_zoom - 1).clamp(3.0, 18.0);
                  _mapController.move(
                    _mapController.camera.center,
                    _zoom,
                  );
                },
                onSettings: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Marker _buildCameraMarker(Camera camera) {
    return Marker(
      point: LatLng(camera.lat, camera.lon),
      width: 14,
      height: 14,
      child: CameraMarkerWidget(camera: camera),
    );
  }
}
