import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../core/model/camera.dart';
import '../providers/database_provider.dart';
import '../providers/driving_state_provider.dart';
import '../providers/simulation_provider.dart';
import '../services/orchestrator.dart';
import '../providers/location_provider.dart';
import '../ui/theme/racing_colors.dart';
import '../ui/widgets/camera_filter_bar.dart';
import '../ui/widgets/camera_marker.dart';
import '../ui/widgets/power_button.dart';
import '../ui/widgets/status_bar.dart';
import '../ui/widgets/speedometer.dart';
import '../ui/widgets/zoom_controls.dart';

/// Preview-only map screen. Same layout as MapScreen but without
/// ForegroundTaskService, location permission, or SettingsScreen navigation
/// (settings are accessible via the bottom tab in preview).
class PreviewMapScreen extends ConsumerStatefulWidget {
  final VoidCallback? onOpenSettings;

  const PreviewMapScreen({super.key, this.onOpenSettings});

  @override
  ConsumerState<PreviewMapScreen> createState() => _PreviewMapScreenState();
}

class _PreviewMapScreenState extends ConsumerState<PreviewMapScreen> {
  final MapController _mapController = MapController();
  double _zoom = 14.0;
  bool _hasInitialFix = false;
  bool _followMode = true;

  List<Camera> _mapCameras = [];
  Timer? _debounce;

  final Set<CameraType> _visibleTypes = {
    CameraType.fixedSpeed,
    CameraType.redLight,
    CameraType.avgSpeedStart,
    CameraType.avgSpeedEnd,
    CameraType.mobileZone,
  };

  static const _defaultCenter = LatLng(32.0853, 34.7818);

  @override
  void initState() {
    super.initState();
    _startServices();
  }

  Future<void> _startServices() async {
    final orchestrator = ref.read(orchestratorProvider);
    await orchestrator?.startMonitoring();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _refreshCamerasForBounds() {
    final dao = ref.read(cameraDaoProvider);
    if (dao == null) return;

    final bounds = _mapController.camera.visibleBounds;
    final cameras = dao.getCamerasInBounds(
      bounds.south,
      bounds.north,
      bounds.west,
      bounds.east,
    );
    setState(() {
      _mapCameras = cameras;
    });
  }

  void _toggleFilter(CameraFilter filter) {
    setState(() {
      for (final type in filter.types) {
        if (_visibleTypes.contains(type)) {
          _visibleTypes.remove(type);
        } else {
          _visibleTypes.add(type);
        }
      }
    });
  }

  void _showCameraDetail(Camera camera) {
    final typeLabel = switch (camera.type) {
      CameraType.fixedSpeed => 'Speed Camera',
      CameraType.redLight => 'Red Light Camera',
      CameraType.avgSpeedStart => 'Avg Speed Zone Start',
      CameraType.avgSpeedEnd => 'Avg Speed Zone End',
      CameraType.mobileZone => 'Mobile Camera Zone',
    };

    final color = CameraMarkerWidget.colorForType(camera.type);

    showModalBottomSheet(
      context: context,
      backgroundColor: RacingColors.trackSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Icon(
                    CameraMarkerWidget.iconForType(camera.type),
                    size: 18,
                    color: color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    typeLabel,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (camera.speedLimit != null)
              _detailRow(Icons.speed, 'Speed Limit', '${camera.speedLimit} km/h'),
            if (camera.roadName != null)
              _detailRow(Icons.route, 'Road', camera.roadName!),
            _detailRow(Icons.location_on, 'Location',
                '${camera.lat.toStringAsFixed(5)}, ${camera.lon.toStringAsFixed(5)}'),
            if (camera.heading != null)
              _detailRow(Icons.compass_calibration, 'Heading',
                  '${camera.heading!.round()}°'),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.white54),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: const TextStyle(
                color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locationAsync = ref.watch(locationStreamProvider);
    final drivingState = ref.watch(drivingStateProvider);

    final filteredCameras =
        _mapCameras.where((c) => _visibleTypes.contains(c.type)).toList();

    final center = locationAsync.when(
      data: (loc) {
        final pos = LatLng(loc.latitude, loc.longitude);
        if (!_hasInitialFix || _followMode) {
          final isFirst = !_hasInitialFix;
          _hasInitialFix = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _mapController.move(pos, _zoom);
              if (isFirst) _refreshCamerasForBounds();
            }
          });
        }
        return pos;
      },
      loading: () => _defaultCenter,
      error: (_, __) => _defaultCenter,
    );

    return Scaffold(
      body: Stack(
        children: [
          // Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: _zoom,
              onMapReady: _refreshCamerasForBounds,
              onPositionChanged: (camera, hasGesture) {
                if (hasGesture) _followMode = false;
                _debounce?.cancel();
                _debounce = Timer(
                  const Duration(milliseconds: 150),
                  _refreshCamerasForBounds,
                );
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'me.buzzoff.app',
              ),
              MarkerLayer(
                markers: filteredCameras.map(_buildCameraMarker).toList(),
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: center,
                    width: 28,
                    height: 28,
                    child: Container(
                      decoration: BoxDecoration(
                        color: RacingColors.racingRed,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: RacingColors.racingRed.withValues(alpha: 0.5),
                            blurRadius: 10,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.directions_car,
                        size: 16,
                        color: Colors.white,
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
            child: Center(
              child: StatusBar(
                state: drivingState,
                isSimulating: ref.watch(simulationEnabledProvider),
              ),
            ),
          ),

          // Camera filter bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 52,
            left: 12,
            right: 12,
            child: CameraFilterBar(
              activeTypes: _visibleTypes,
              cameras: _mapCameras,
              onToggle: _toggleFilter,
            ),
          ),

          // Speedometer (bottom-center)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 24,
            left: 0,
            right: 0,
            child: Center(
              child: Speedometer(
                speedKmh: locationAsync.whenOrNull(
                      data: (loc) => loc.speedKmh,
                    ) ??
                    0,
              ),
            ),
          ),

          // Power on/off toggle
          Positioned(
            left: 16,
            bottom: MediaQuery.of(context).padding.bottom + 24,
            child: PowerButton(
              state: drivingState,
              onToggle: () {
                final orchestrator = ref.read(orchestratorProvider);
                if (drivingState == DrivingState.idle) {
                  orchestrator?.startDriving();
                } else {
                  orchestrator?.stopDriving();
                }
              },
            ),
          ),

          // Zoom + settings controls
          Positioned(
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 24,
            child: ZoomControls(
              followMode: _followMode,
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
              onMyLocation: () {
                _followMode = true;
                _mapController.move(center, _zoom);
              },
              onSettings: widget.onOpenSettings ?? () {},
            ),
          ),
        ],
      ),
    );
  }

  Marker _buildCameraMarker(Camera camera) {
    return Marker(
      point: LatLng(camera.lat, camera.lon),
      width: 28,
      height: 28,
      child: GestureDetector(
        onTap: () => _showCameraDetail(camera),
        child: CameraMarkerWidget(camera: camera),
      ),
    );
  }
}
