// lib/features/overlay/repository/overlay_repository.dart

import '../../../core/services/hive_service.dart';
import '../../../core/constants/hive_boxes.dart';
import '../model/overlay_state_model.dart';

class OverlayRepository {
  static const _capturesKey  = 'overlay_captures_list';
  static const _positionXKey = 'overlay_position_x';
  static const _positionYKey = 'overlay_position_y';

  // ── Captures ──────────────────────────────────────────────────────────────

  Future<void> saveCapture(OverlayCapture capture) async {
    final List<dynamic> existing = List.from(
      HiveService.box(HiveBoxes.overlayCaptures)
          .get(_capturesKey, defaultValue: []) as List,
    );

    existing.add(capture.toMap());

    // Keep last 200 captures
    if (existing.length > 200) existing.removeAt(0);

    await HiveService.box(HiveBoxes.overlayCaptures)
        .put(_capturesKey, existing);
  }

  Future<void> updateCapture(OverlayCapture updated) async {
    final List<dynamic> existing = List.from(
      HiveService.box(HiveBoxes.overlayCaptures)
          .get(_capturesKey, defaultValue: []) as List,
    );

    final index =
        existing.indexWhere((e) => e['id'] == updated.id);
    if (index != -1) {
      existing[index] = updated.toMap();
      await HiveService.box(HiveBoxes.overlayCaptures)
          .put(_capturesKey, existing);
    }
  }

  Future<void> deleteCapture(String id) async {
    final List<dynamic> existing = List.from(
      HiveService.box(HiveBoxes.overlayCaptures)
          .get(_capturesKey, defaultValue: []) as List,
    );

    existing.removeWhere((e) => e['id'] == id);

    await HiveService.box(HiveBoxes.overlayCaptures)
        .put(_capturesKey, existing);
  }

  List<OverlayCapture> loadAllCaptures() {
    final List<dynamic> raw = List.from(
      HiveService.box(HiveBoxes.overlayCaptures)
          .get(_capturesKey, defaultValue: []) as List,
    );

    return raw
        .map((e) =>
            OverlayCapture.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  List<OverlayCapture> loadTodayCaptures() {
    final all   = loadAllCaptures();
    final today = DateTime.now();
    return all.where((c) =>
      c.capturedAt.year  == today.year  &&
      c.capturedAt.month == today.month &&
      c.capturedAt.day   == today.day,
    ).toList();
  }

  Future<void> clearAll() async {
    await HiveService.box(HiveBoxes.overlayCaptures)
        .put(_capturesKey, []);
  }

  // ── Position ──────────────────────────────────────────────────────────────

  Future<void> savePosition(double x, double y) async {
    await HiveService.box(HiveBoxes.overlayCaptures)
        .put(_positionXKey, x);
    await HiveService.box(HiveBoxes.overlayCaptures)
        .put(_positionYKey, y);
  }

  double loadPositionX() {
    return HiveService.box(HiveBoxes.overlayCaptures)
        .get(_positionXKey, defaultValue: 20.0) as double;
  }

  double loadPositionY() {
    return HiveService.box(HiveBoxes.overlayCaptures)
        .get(_positionYKey, defaultValue: 200.0) as double;
  }
}
