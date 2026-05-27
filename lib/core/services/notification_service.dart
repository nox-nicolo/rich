// lib/core/services/notification_service.dart

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _muted = false;
  GlobalKey<NavigatorState>? _navigatorKey;

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> init({GlobalKey<NavigatorState>? navigatorKey}) async {
    if (_initialized) return;
    _navigatorKey = navigatorKey;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const linux = LinuxInitializationSettings(defaultActionName: 'Open RICH');

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios, linux: linux),
      onDidReceiveNotificationResponse: _onTapped,
    );

    await _configureAndroidNotifications();
    await _requestPermissions();

    _initialized = true;
  }

  Future<void> _configureAndroidNotifications() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return;

    final alarmPattern = Int64List.fromList(const [0, 900, 250, 900]);
    await android.createNotificationChannel(
      AndroidNotificationChannel(
        NotificationChannel.taskAlarm.id,
        NotificationChannel.taskAlarm.name,
        description: NotificationChannel.taskAlarm.description,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        vibrationPattern: alarmPattern,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
    );
  }

  Future<void> _requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  void _onTapped(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null || _navigatorKey == null) return;
    final ctx = _navigatorKey!.currentContext;
    if (ctx == null) return;

    // Task focus deep-link: payload format "task:<taskId>"
    if (payload.startsWith('task:')) {
      final taskId = payload.substring(5);
      GoRouter.of(ctx).go('/work/focus/$taskId');
      return;
    }

    // Meeting deep-link: payload format "meeting:<meetingId>"
    if (payload.startsWith('meeting:')) {
      final meetingId = payload.substring(8);
      GoRouter.of(ctx).go('/work/meeting/$meetingId');
      return;
    }

    // Map payload → route
    final routes = <String, String>{
      'meditation': '/meditation',
      'trading': '/trading',
      'betting': '/betting',
      'reading': '/reading',
      'writing': '/writing',
      'work': '/work',
      'life': '/life',
      'dashboard': '/',
      'mentor': '/mentor',
    };

    final route = routes[payload];
    if (route != null) {
      Navigator.of(ctx, rootNavigator: true).pushNamed(route);
    }
  }

  // ── Mute Control ──────────────────────────────────────────────────────────

  void mute() => _muted = true;
  void unmute() => _muted = false;
  bool get isMuted => _muted;

  // ── Show Immediate ────────────────────────────────────────────────────────

  Future<void> show({
    required int id,
    required String title,
    required String body,
    NotificationChannel channel = NotificationChannel.general,
    String? payload,
  }) async {
    if (!_initialized) return;
    // Critical alerts always go through even when muted
    if (_muted && channel != NotificationChannel.critical) return;

    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: channel.importance,
          priority: channel.priority,
          playSound: channel != NotificationChannel.silent,
          enableVibration: channel != NotificationChannel.silent,
          category: channel.androidCategory,
          audioAttributesUsage: channel.audioAttributesUsage,
        ),
        linux: LinuxNotificationDetails(
          urgency: channel.linuxUrgency,
          suppressSound: channel == NotificationChannel.silent,
          defaultActionName: 'Open RICH',
        ),
      ),
      payload: payload,
    );
  }

  // ── Schedule ──────────────────────────────────────────────────────────────

  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    NotificationChannel channel = NotificationChannel.reminder,
    String? payload,
  }) async {
    if (!_initialized) return;
    if (defaultTargetPlatform == TargetPlatform.linux) return;

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.description,
        importance: channel.importance,
        priority: channel.priority,
        playSound: channel != NotificationChannel.silent,
        enableVibration: channel != NotificationChannel.silent,
        category: channel.androidCategory,
        audioAttributesUsage: channel.audioAttributesUsage,
      ),
      linux: LinuxNotificationDetails(
        urgency: channel.linuxUrgency,
        defaultActionName: 'Open RICH',
      ),
    );
    final zonedTime = tz.TZDateTime.from(scheduledTime, tz.local);

    Future<void> scheduleWith(AndroidScheduleMode mode) {
      return _plugin.zonedSchedule(
        id,
        title,
        body,
        zonedTime,
        details,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        androidScheduleMode: mode,
        payload: payload,
      );
    }

    try {
      await scheduleWith(AndroidScheduleMode.exactAllowWhileIdle);
    } on PlatformException catch (e) {
      if (e.code != 'exact_alarms_not_permitted') rethrow;
      await scheduleWith(AndroidScheduleMode.inexactAllowWhileIdle);
    }
  }

  // ── Cancel ────────────────────────────────────────────────────────────────

  Future<void> cancel(int id) async => _plugin.cancel(id);
  Future<void> cancelAll() async => _plugin.cancelAll();
}

// ── Notification Channels ─────────────────────────────────────────────────────

enum NotificationChannel {
  general,
  reminder,
  taskAlarm,
  trading,
  critical,
  silent,
}

extension NotificationChannelX on NotificationChannel {
  String get id {
    switch (this) {
      case NotificationChannel.general:
        return 'rich_general';
      case NotificationChannel.reminder:
        return 'rich_reminder';
      case NotificationChannel.taskAlarm:
        return 'rich_task_alarm_v2';
      case NotificationChannel.trading:
        return 'rich_trading';
      case NotificationChannel.critical:
        return 'rich_critical';
      case NotificationChannel.silent:
        return 'rich_silent';
    }
  }

  String get name {
    switch (this) {
      case NotificationChannel.general:
        return 'General';
      case NotificationChannel.reminder:
        return 'Reminders';
      case NotificationChannel.taskAlarm:
        return 'Task Alarms';
      case NotificationChannel.trading:
        return 'Trading Alerts';
      case NotificationChannel.critical:
        return 'Critical Alerts';
      case NotificationChannel.silent:
        return 'Silent';
    }
  }

  String get description {
    switch (this) {
      case NotificationChannel.general:
        return 'General RICH notifications';
      case NotificationChannel.reminder:
        return 'Routine and habit reminders';
      case NotificationChannel.taskAlarm:
        return 'Scheduled task start alarms';
      case NotificationChannel.trading:
        return 'High-impact market events';
      case NotificationChannel.critical:
        return 'Critical discipline locks and warnings';
      case NotificationChannel.silent:
        return 'Silent background updates';
    }
  }

  Importance get importance {
    switch (this) {
      case NotificationChannel.taskAlarm:
        return Importance.max;
      case NotificationChannel.critical:
        return Importance.max;
      case NotificationChannel.trading:
        return Importance.high;
      case NotificationChannel.reminder:
        return Importance.defaultImportance;
      case NotificationChannel.general:
        return Importance.defaultImportance;
      case NotificationChannel.silent:
        return Importance.min;
    }
  }

  Priority get priority {
    switch (this) {
      case NotificationChannel.taskAlarm:
        return Priority.max;
      case NotificationChannel.critical:
        return Priority.max;
      case NotificationChannel.trading:
        return Priority.high;
      default:
        return Priority.defaultPriority;
    }
  }

  AndroidNotificationCategory? get androidCategory {
    switch (this) {
      case NotificationChannel.taskAlarm:
      case NotificationChannel.critical:
        return AndroidNotificationCategory.alarm;
      default:
        return null;
    }
  }

  AudioAttributesUsage get audioAttributesUsage {
    switch (this) {
      case NotificationChannel.taskAlarm:
      case NotificationChannel.critical:
        return AudioAttributesUsage.alarm;
      default:
        return AudioAttributesUsage.notification;
    }
  }

  LinuxNotificationUrgency get linuxUrgency {
    switch (this) {
      case NotificationChannel.taskAlarm:
      case NotificationChannel.critical:
        return LinuxNotificationUrgency.critical;
      case NotificationChannel.trading:
        return LinuxNotificationUrgency.normal;
      case NotificationChannel.silent:
        return LinuxNotificationUrgency.low;
      case NotificationChannel.general:
      case NotificationChannel.reminder:
        return LinuxNotificationUrgency.normal;
    }
  }
}
