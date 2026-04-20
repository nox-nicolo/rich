// lib/core/services/hive_service.dart

import 'package:hive_flutter/hive_flutter.dart';
import '../constants/hive_boxes.dart';

class HiveService {
  HiveService._();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    await Hive.initFlutter();

    // Register TypeAdapters here as features grow:
    // Hive.registerAdapter(MeditationSessionAdapter());
    // Hive.registerAdapter(NewsEventAdapter());
    // etc.

    await Future.wait([
      Hive.openBox<dynamic>(HiveBoxes.routines),
      Hive.openBox<dynamic>(HiveBoxes.streaks),
      Hive.openBox<dynamic>(HiveBoxes.lockStates),
      Hive.openBox<dynamic>(HiveBoxes.tradingNotes),
      Hive.openBox<dynamic>(HiveBoxes.bettingLogs),
      Hive.openBox<dynamic>(HiveBoxes.readingProgress),
      Hive.openBox<dynamic>(HiveBoxes.writingEntries),
      Hive.openBox<dynamic>(HiveBoxes.newsCache),
      Hive.openBox<dynamic>(HiveBoxes.dashboardSummary),
      Hive.openBox<dynamic>(HiveBoxes.overlayCaptures),
      Hive.openBox<dynamic>(HiveBoxes.rulesCache),
      Hive.openBox<dynamic>(HiveBoxes.workTasks),
      Hive.openBox<dynamic>(HiveBoxes.habits),
      Hive.openBox<dynamic>(HiveBoxes.highlights),
      Hive.openBox<dynamic>(HiveBoxes.knowledgeVault),
      Hive.openBox<dynamic>(HiveBoxes.userPreferences),
      Hive.openBox<dynamic>(HiveBoxes.financeLogs),
      Hive.openBox<dynamic>(HiveBoxes.security),
      Hive.openBox<dynamic>(HiveBoxes.dailyRecords),
      Hive.openBox<dynamic>(HiveBoxes.monthlyReports),
      Hive.openBox<dynamic>(HiveBoxes.milestones),
    ]);

    _initialized = true;
  }

  /// Get an open box by name
  static Box<dynamic> box(String name) {
    if (!Hive.isBoxOpen(name)) {
      throw HiveServiceException(
        'Box "$name" is not open. Make sure HiveService.init() was called.',
      );
    }
    return Hive.box(name);
  }

  /// Safe typed get — returns null if key not found
  static T? get<T>(String boxName, String key) {
    return box(boxName).get(key) as T?;
  }

  /// Safe put
  static Future<void> put(
      String boxName, String key, dynamic value) async {
    await box(boxName).put(key, value);
  }

  /// Safe delete
  static Future<void> delete(String boxName, String key) async {
    await box(boxName).delete(key);
  }

  /// Clear entire box
  static Future<void> clearBox(String boxName) async {
    await box(boxName).clear();
  }

  /// Close all boxes — call only on full app teardown
  static Future<void> closeAll() async {
    await Hive.close();
    _initialized = false;
  }

  static bool get isInitialized => _initialized;
}

class HiveServiceException implements Exception {
  final String message;
  HiveServiceException(this.message);

  @override
  String toString() => 'HiveServiceException: $message';
}
