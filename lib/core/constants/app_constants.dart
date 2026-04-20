// lib/core/constants/app_constants.dart

class AppConstants {
  AppConstants._();

  static const String appName    = 'RICH';
  static const String appVersion = '1.0.0';

  // ── Rule Engine ───────────────────────────────────────────────────────────
  static const int maxConsecutiveLosses  = 3;
  static const int bettingCooldownHours  = 2;
  static const int maxNewsCache          = 100;
  static const int maxJournalEntries     = 200;
  static const int maxSessionHistory     = 90;

  // ── Meditation Timer Defaults (seconds) ───────────────────────────────────
  static const int defaultPrayerDuration        = 300;  // 5 min
  static const int defaultBreathingDuration     = 240;  // 4 min
  static const int defaultStillnessDuration     = 600;  // 10 min
  static const int defaultVisualizationDuration = 300;  // 5 min
  static const int defaultReflectionDuration    = 420;  // 7 min
  static const int defaultResetDuration         = 180;  // 3 min

  // ── Discipline Score Thresholds ───────────────────────────────────────────
  static const int scoreHigh   = 80;
  static const int scoreMedium = 50;

  // ── Reading ───────────────────────────────────────────────────────────────
  static const int defaultDailyPageGoal = 20;

  // ── Writing ───────────────────────────────────────────────────────────────
  static const int defaultDailyWordGoal = 300;

  // ── Betting ───────────────────────────────────────────────────────────────
  static const double defaultMaxStakePct  = 0.02; // 2% of bankroll
  static const double defaultDailyStopPct = 0.05; // 5% of bankroll

  // ── WebSocket ─────────────────────────────────────────────────────────────
  static const int wsReconnectDelaySeconds = 5;
  static const int wsMaxRetries            = 5;

  // ── Overlay ───────────────────────────────────────────────────────────────
  static const double overlayDefaultX = 20.0;
  static const double overlayDefaultY = 200.0;
}
