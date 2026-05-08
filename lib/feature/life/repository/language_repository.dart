// lib/features/life/repository/language_repository.dart

import '../../../core/services/hive_service.dart';
import '../../../core/constants/hive_boxes.dart';
import '../model/language_model.dart';
import '../model/language_curriculum.dart';

class LanguageRepository {
  static const String _progressKey = 'language_progress_list';

  // ── Save ──────────────────────────────────────────────────────────────────

  Future<void> saveProgress(LanguageProgress progress) async {
    final box = HiveService.box(HiveBoxes.habits);
    final List<dynamic> existing =
        List.from(box.get(_progressKey, defaultValue: []) as List);
    final index =
        existing.indexWhere((e) => (e as Map)['id'] == progress.id);
    if (index >= 0) {
      existing[index] = progress.toMap();
    } else {
      existing.add(progress.toMap());
    }
    await box.put(_progressKey, existing);
  }

  Future<void> deleteProgress(String id) async {
    final box = HiveService.box(HiveBoxes.habits);
    final List<dynamic> existing =
        List.from(box.get(_progressKey, defaultValue: []) as List);
    existing.removeWhere((e) => (e as Map)['id'] == id);
    await box.put(_progressKey, existing);
  }

  // ── Load ──────────────────────────────────────────────────────────────────

  List<LanguageProgress> loadAllProgress() {
    final box = HiveService.box(HiveBoxes.habits);
    final List<dynamic> raw =
        List.from(box.get(_progressKey, defaultValue: []) as List);
    return raw
        .map((e) => LanguageProgress.fromMap(
            Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  LanguageProgress? loadActiveProgress() {
    final all = loadAllProgress();
    final active = all.where((p) => p.isActive).toList();
    return active.isNotEmpty ? active.first : null;
  }

  // ── Create a fresh language enrollment ────────────────────────────────────

  LanguageProgress createFreshProgress({
    required String id,
    required SupportedLanguage language,
  }) =>
      LanguageProgress(
        id:         id,
        language:   language,
        topics:     LanguageCurriculum.topicsFor(language),
        vocabulary: LanguageCurriculum.vocabularyFor(language),
        startedAt:  DateTime.now(),
        isActive:   true,
      );
}
