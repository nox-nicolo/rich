// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tzl;
import 'core/services/hive_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/daily_reset_service.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/tracking/tracking_service.dart';
import 'core/tracking/tracking_salvage.dart';
import 'feature/meditation/viewmodel/meditation_viewmodel.dart';
import 'feature/security/view/lock_screen.dart';
import 'feature/security/viewmodel/app_lock_viewmodel.dart';

// Global navigator key — used by NotificationService to route on tap
final navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // google_fonts tries to fetch TTFs from fonts.gstatic.com the first time
  // a face is used. On devices without internet (or where DNS is blocked)
  // every launch throws unhandled exceptions and stalls frames. Disable
  // runtime fetching — cached faces (from a previous online launch) still
  // work, and otherwise the theme falls back to the system font.
  GoogleFonts.config.allowRuntimeFetching = false;

  // Timezone MUST be initialised before any notification scheduling
  tz.initializeTimeZones();
  tzl.setLocalLocation(tzl.getLocation('Africa/Dar_es_Salaam'));

  // Only the truly blocking bits run before runApp: Hive (needed by providers
  // at first build) and notification plugin init (cheap). Scheduling the 17
  // daily reminders is deferred so it doesn't keep the main thread busy long
  // enough for Android's ANR watchdog to fire SIGQUIT at startup.
  await HiveService.init();
  // New calendar day = clean slate. Routines, gate, locks, mind, discipline
  // all reset to zero before any provider builds and reads stale values.
  await DailyResetService.runIfNewDay();
  await NotificationService.instance.init(navigatorKey: navigatorKey);

  runApp(
    const ProviderScope(
      child: RichApp(),
    ),
  );

  // Fire-and-forget — runs on the event loop after the first frame is up.
  // Wrapped so any platform-channel failure never crashes the app.
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    try {
      await _scheduleDailyReminders();
    } catch (_) {}
    try {
      await TrackingSalvage.runIfNeeded();
    } catch (_) {}
    try {
      await TrackingService.runRetention();
    } catch (_) {}
  });
}

/// Daily schedule:
///   03:00  Wake
///   03:00–08:00  Morning ritual block — prayer, meditation, breathwork,
///                                       reading, intention, rules review
///   08:00  Leave for / arrive at work
///   08:00–13:00  Work first half
///   13:00  Lunch break
///   13:30–17:00  Work second half
///   17:00  Leave work
///   18:00  Arrive home (1h travel)
///   18:00–23:00  Personal block — trading, betting, reading, writing, life
///   23:00  Sleep
///
/// Safe to call on every launch —
/// flutter_local_notifications deduplicates by notification ID.
Future<void> _scheduleDailyReminders() async {
  final svc = NotificationService.instance;
  final now = DateTime.now();

  Future<void> remind(int id, int hour, int minute, String title, String body,
      {NotificationChannel channel = NotificationChannel.reminder}) async {
    final time = DateTime(now.year, now.month, now.day, hour, minute);
    await svc.schedule(
      id:            id,
      title:         title,
      body:          body,
      scheduledTime: time.isBefore(now) ? time.add(const Duration(days: 1)) : time,
      channel:       channel,
    );
  }

  // ── Morning ritual block (03:00 – 08:00) ──────────────────────────────────

  // 03:00 — Wake up
  await remind(1, 3, 0,
    'Wake Up — Begin Your Morning',
    'Rise. Prayer, breathing, and meditation come first. Open the gate.');

  // 03:20 — Meditation
  await remind(2, 3, 20,
    'Meditation',
    'Complete your meditation session. The gate must be open before trading.');

  // 04:00 — Intention + rules review
  await remind(3, 4, 0,
    'Set Your Intention',
    'Write today\'s intention. Review your trading rules before the day starts.');

  // 05:00 — Reading block
  await remind(4, 5, 0,
    'Reading Block',
    'Use this quiet hour to read. Log your pages in RICH.');

  // 06:30 — Prepare for work
  await remind(5, 6, 30,
    'Prepare for Work',
    'Plan your tasks for today. What must get done before 17:00?');

  // 07:45 — Leave reminder
  await remind(6, 7, 45,
    'Leave for Work',
    'Head out. Stay disciplined at work — focus and no wasted hours.');

  // ── Work block (08:00 – 17:00) ────────────────────────────────────────────

  // 10:00 — Mid-morning work check
  await remind(7, 10, 0,
    'Mid-Morning Check',
    'Two hours in. Are your tasks on track? Stay locked in.');

  // 13:00 — Lunch
  await remind(8, 13, 0,
    'Lunch Break',
    'Take your break. Rest your mind — afternoon block starts at 13:30.');

  // 13:30 — Afternoon work resumes
  await remind(9, 13, 30,
    'Back to Work',
    'Afternoon block begins. 3.5 hours left — finish strong.');

  // 16:30 — End-of-work wrap-up
  await remind(10, 16, 30,
    'Wrap Up Work',
    'Finalize tasks. Log what you completed and what carries to tomorrow.');

  // 17:00 — Leave work
  await remind(11, 17, 0,
    'Leave Work',
    'Head home. Use the 1h travel to decompress and mentally prepare.');

  // ── Personal block (18:00 – 23:00) ────────────────────────────────────────

  // 18:00 — Home: personal block opens
  await remind(12, 18, 0,
    'Home — Personal Block',
    '5 hours for trading, betting, reading, writing, and life. Use them well.',
    channel: NotificationChannel.trading);

  // 18:15 — Review trading rules before any session
  await remind(13, 18, 15,
    'Trading Rules Review',
    'Before you open any chart — review your rules. Is the gate open?',
    channel: NotificationChannel.trading);

  // 20:00 — Reading / writing reminder
  await remind(14, 20, 0,
    'Reading & Writing',
    'Have you read today? Log your pages. Write before the day closes.');

  // 21:30 — Evening reflection
  await remind(15, 21, 30,
    'Evening Reflection',
    'Log your trading and betting sessions. What did today teach you?');

  // 22:30 — Journal + wind-down
  await remind(16, 22, 30,
    'Journal & Wind Down',
    'Write your final entry. Capture lessons. 30 minutes to sleep.');

  // 22:55 — Sleep reminder
  await remind(17, 22, 55,
    'Sleep — 23:00',
    'Close everything. Rest is part of the system. You start again at 03:00.');
}

class RichApp extends ConsumerWidget {
  const RichApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Eagerly init meditation so it can unlock trading/betting on cold start
    ref.watch(meditationViewModelProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title:                    'Rich',
      debugShowCheckedModeBanner: false,
      theme:                    AppTheme.dark,
      routerConfig:             router,
      builder: (context, child) {
        return _AppLockGate(child: child ?? const SizedBox.shrink());
      },
    );
  }
}

class _AppLockGate extends ConsumerWidget {
  const _AppLockGate({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lockState = ref.watch(appLockViewModelProvider);

    if (lockState.isLoading) return child;

    if (!lockState.shouldShowLockScreen) return child;

    return Stack(
      children: [
        child,
        const Positioned.fill(child: LockScreen()),
      ],
    );
  }
}
