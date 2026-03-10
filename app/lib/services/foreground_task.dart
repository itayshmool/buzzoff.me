import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class ForegroundTaskService {
  static Future<void> init() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'buzzoff_location',
        channelName: 'BuzzOff Location',
        channelDescription: 'Active driving monitoring',
        channelImportance: NotificationChannelImportance.LOW,
        isSticky: true,
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

  static Future<bool> start() async {
    if (await FlutterForegroundTask.isRunningService) return true;

    return await FlutterForegroundTask.startService(
      notificationTitle: 'BuzzOff',
      notificationText: 'Monitoring active',
      callback: _startCallback,
    );
  }

  static Future<bool> stop() async {
    return await FlutterForegroundTask.stopService();
  }

  static Future<bool> get isRunning async {
    return await FlutterForegroundTask.isRunningService;
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
