// lib/feature/overlay/service/foreground_task_service.dart
//
// Keeps the RICH overlay alive in the background using
// flutter_foreground_task. Without this the overlay dies
// when the user navigates away from the app.
//
// Required AndroidManifest.xml permissions:
//   <uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
//   <uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class ForegroundTaskService {
  ForegroundTaskService._();

  // ── Init ──────────────────────────────────────────────────────────────────

  static Future<void> init() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId:          'rich_overlay_channel',
        channelName:        'RICH Overlay',
        channelDescription: 'Keeps the RICH overlay active',
        channelImportance:  NotificationChannelImportance.LOW,
        priority:           NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound:        false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction:   ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: false,
        allowWifiLock: false,
      ),
    );
  }

  // ── Start ─────────────────────────────────────────────────────────────────

  static Future<void> start() async {
    if (await FlutterForegroundTask.isRunningService) return;

    await FlutterForegroundTask.startService(
      serviceId:         256,
      notificationTitle: 'RICH',
      notificationText:  'Overlay active',
      callback:          _taskCallback,
    );
  }

  // ── Stop ──────────────────────────────────────────────────────────────────

  static Future<void> stop() async {
    await FlutterForegroundTask.stopService();
  }

  // ── Status ────────────────────────────────────────────────────────────────

  static Future<bool> get isRunning =>
      FlutterForegroundTask.isRunningService;
}

// ── Task callback — runs in a separate isolate ────────────────────────────────

@pragma('vm:entry-point')
void _taskCallback() {
  FlutterForegroundTask.setTaskHandler(_RichForegroundHandler());
}

class _RichForegroundHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Overlay service started
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Heartbeat — keep overlay alive
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    // Overlay service stopped
  }
}
