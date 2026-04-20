// lib/features/rules_engine/repository/rules_repository.dart

import '../../../core/services/hive_service.dart';
import '../../../core/constants/hive_boxes.dart';
import '../model/rich_feature.dart';

class RulesRepository {
  static const _lockedFeaturesKey  = 'locked_features';
  static const _mutedKey           = 'notifications_muted';
  static const _cooldownsKey       = 'betting_cooldowns';
  static const _meditationDoneKey  = 'meditation_done_today';
  static const _meditationDateKey  = 'meditation_done_date';

  // ── Locked Features ───────────────────────────────────────────────────────

  Future<void> saveLockedFeatures(
      Set<RichFeature> features) async {
    final indices = features.map((f) => f.index).toList();
    await HiveService.put(
        HiveBoxes.lockStates, _lockedFeaturesKey, indices);
  }

  Set<RichFeature> loadLockedFeatures() {
    final raw = HiveService.get<List>(
        HiveBoxes.lockStates, _lockedFeaturesKey);
    if (raw == null) {
      // Trading locked by default until meditation done
      return {RichFeature.trading};
    }
    return raw
        .map((i) => RichFeature.values[i as int])
        .toSet();
  }

  // ── Notifications Muted ───────────────────────────────────────────────────

  Future<void> saveMuted(bool muted) async {
    await HiveService.put(
        HiveBoxes.lockStates, _mutedKey, muted);
  }

  bool loadMuted() {
    return HiveService.get<bool>(
            HiveBoxes.lockStates, _mutedKey) ??
        false;
  }

  // ── Betting Cooldown ──────────────────────────────────────────────────────

  Future<void> saveCooldownExpiry(DateTime expiry) async {
    await HiveService.put(
      HiveBoxes.lockStates,
      _cooldownsKey,
      expiry.toIso8601String(),
    );
  }

  DateTime? loadCooldownExpiry() {
    final raw = HiveService.get<String>(
        HiveBoxes.lockStates, _cooldownsKey);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  bool get isCooldownActive {
    final expiry = loadCooldownExpiry();
    if (expiry == null) return false;
    return DateTime.now().isBefore(expiry);
  }

  Duration? get remainingCooldown {
    final expiry = loadCooldownExpiry();
    if (expiry == null) return null;
    final remaining = expiry.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  Future<void> clearCooldown() async {
    await HiveService.delete(
        HiveBoxes.lockStates, _cooldownsKey);
  }

  // ── Meditation Completed Today ────────────────────────────────────────────

  Future<void> saveMeditationCompleted() async {
    await HiveService.put(
        HiveBoxes.lockStates, _meditationDoneKey, true);
    await HiveService.put(
      HiveBoxes.lockStates,
      _meditationDateKey,
      DateTime.now().toIso8601String(),
    );
  }

  bool loadMeditationCompletedToday() {
    final dateStr = HiveService.get<String>(
        HiveBoxes.lockStates, _meditationDateKey);
    if (dateStr == null) return false;
    final saved = DateTime.tryParse(dateStr);
    if (saved == null) return false;
    final now = DateTime.now();
    return saved.year  == now.year  &&
           saved.month == now.month &&
           saved.day   == now.day;
  }

  Future<void> resetForNewDay() async {
    await HiveService.put(
        HiveBoxes.lockStates, _meditationDoneKey, false);
    await HiveService.delete(
        HiveBoxes.lockStates, _meditationDateKey);
    await saveLockedFeatures({RichFeature.trading});
    await saveMuted(false);
  }
}
