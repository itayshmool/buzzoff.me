import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'orchestrator.dart';

class ForegroundTaskService {
  static Future<void> init() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'buzzoff_location',
        channelName: 'BuzzOff Location',
        channelDescription: 'Active driving monitoring',
        channelImportance: NotificationChannelImportance.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        autoRunOnBoot: true,
        autoRunOnMyPackageReplaced: true,
        allowWakeLock: true,
        eventAction: ForegroundTaskEventAction.repeat(3000),
      ),
    );
  }

  static const _iconIdle = NotificationIcon(metaDataName: 'com.buzzoff.ICON_IDLE');
  static const _iconActive = NotificationIcon(metaDataName: 'com.buzzoff.ICON_ACTIVE');
  static const _iconAlert = NotificationIcon(metaDataName: 'com.buzzoff.ICON_ALERT');

  static Future<ServiceRequestResult> start() async {
    if (await FlutterForegroundTask.isRunningService) {
      return const ServiceRequestSuccess();
    }

    return await FlutterForegroundTask.startService(
      notificationTitle: 'BuzzOff',
      notificationText: 'Monitoring — waiting for driving',
      notificationIcon: _iconIdle,
      callback: _startCallback,
    );
  }

  static Future<ServiceRequestResult> stop() async {
    return await FlutterForegroundTask.stopService();
  }

  static Future<bool> get isRunning async {
    return await FlutterForegroundTask.isRunningService;
  }

  /// Update notification text and icon based on driving state.
  static Future<void> updateForState(DrivingState state) async {
    if (!await FlutterForegroundTask.isRunningService) return;

    final (title, text, icon) = switch (state) {
      DrivingState.driving => (
          'BuzzOff — Active',
          'Monitoring cameras ahead',
          _iconActive,
        ),
      DrivingState.stopping => (
          'BuzzOff — Stopping',
          'Speed dropped, pausing soon...',
          _iconActive,
        ),
      DrivingState.idle => (
          'BuzzOff',
          'Monitoring — waiting for driving',
          _iconIdle,
        ),
    };

    await FlutterForegroundTask.updateService(
      notificationTitle: title,
      notificationText: text,
      notificationIcon: icon,
    );
  }

  /// Flash an alert notification briefly, then revert to state notification.
  static Future<void> showCameraAlert(
      String message, DrivingState currentState) async {
    if (!await FlutterForegroundTask.isRunningService) return;

    await FlutterForegroundTask.updateService(
      notificationTitle: 'Camera Alert',
      notificationText: message,
      notificationIcon: _iconAlert,
    );

    // Revert after 5 seconds
    await Future.delayed(const Duration(seconds: 5));
    await updateForState(currentState);
  }
}

@pragma('vm:entry-point')
void _startCallback() {
  FlutterForegroundTask.setTaskHandler(_BuzzOffTaskHandler());
}

class _BuzzOffTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Proximity checks happen via location stream, not here.
    // This keeps the foreground service alive.
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {}
}
