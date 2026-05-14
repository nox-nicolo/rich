// lib/core/router/app_router.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'route_names.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../widgets/rich_card.dart';
import '../../providers/providers.dart';

// Screens
import 'package:rich/feature/dashboard/view/dashboard_screen.dart';
import 'package:rich/feature/meditation/view/meditation_screen.dart';
import 'package:rich/feature/trading/view/trading_screen.dart';
import 'package:rich/feature/work/view/work_screen.dart';
import 'package:rich/feature/work/view/task_focus_screen.dart';
import 'package:rich/feature/work/view/meeting_active_screen.dart';
import 'package:rich/feature/life/view/life_screen.dart';
import 'package:rich/feature/betting/view/betting_screen.dart';
import 'package:rich/feature/reading/view/reading_screen.dart';
import 'package:rich/feature/writing/view/writing_screen.dart';
import 'package:rich/feature/settings/view/settings_screen.dart';
import 'package:rich/feature/finance/view/finance_page.dart';
import 'package:rich/feature/reports/view/reports_screen.dart';
import 'package:rich/feature/milestones/view/milestones_screen.dart';
import 'package:rich/feature/mentor/view/mentor_screen.dart';

// ── Router Provider ───────────────────────────────────────────────────────────

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RouteNames.dashboard,
    debugLogDiagnostics: false,
    routes: [
      // Full-screen task focus (no bottom nav)
      GoRoute(
        path: '/work/focus/:taskId',
        builder: (_, state) =>
            TaskFocusScreen(taskId: state.pathParameters['taskId']!),
      ),

      // Full-screen meeting (no bottom nav)
      GoRoute(
        path: '/work/meeting/:meetingId',
        builder: (_, state) =>
            MeetingActiveScreen(meetingId: state.pathParameters['meetingId']!),
      ),

      ShellRoute(
        builder: (context, state, child) => RichShell(child: child),
        routes: [
          GoRoute(
            path: RouteNames.dashboard,
            builder: (_, __) => const DashboardScreen(),
          ),

          GoRoute(
            path: RouteNames.meditation,
            builder: (_, __) => const MeditationScreen(),
          ),

          GoRoute(
            path: RouteNames.work,
            builder: (_, __) => const WorkScreen(),
          ),

          GoRoute(
            path: RouteNames.life,
            builder: (_, __) => const LifeScreen(),
          ),

          GoRoute(
            path: RouteNames.trading,
            redirect: (context, state) {
              final isLocked = ref.read(
                isFeatureLockedProvider(RichFeature.trading),
              );
              if (isLocked) {
                return '${RouteNames.locked}?feature=trading';
              }
              return null;
            },
            builder: (_, __) => const TradingScreen(),
          ),

          GoRoute(
            path: RouteNames.betting,
            redirect: (context, state) {
              final isLocked = ref.read(
                isFeatureLockedProvider(RichFeature.betting),
              );
              if (isLocked) {
                return '${RouteNames.locked}?feature=betting';
              }
              return null;
            },
            builder: (_, __) => const BettingScreen(),
          ),

          GoRoute(
            path: RouteNames.reading,
            builder: (_, __) => const ReadingScreen(),
          ),

          GoRoute(
            path: RouteNames.writing,
            builder: (_, __) => const WritingScreen(),
          ),

          GoRoute(
            path: RouteNames.locked,
            builder: (context, state) {
              final feature = state.uri.queryParameters['feature'] ?? '';
              return LockedScreen(featureName: feature);
            },
          ),

          GoRoute(
            path: RouteNames.settings,
            builder: (_, __) => const SettingsScreen(),
          ),

          GoRoute(
            path: RouteNames.finance,
            builder: (_, __) => const FinancePage(),
          ),

          GoRoute(
            path: RouteNames.reports,
            builder: (_, __) => const ReportsScreen(),
          ),

          GoRoute(
            path: RouteNames.milestones,
            builder: (_, __) => const MilestonesScreen(),
          ),

          GoRoute(
            path: RouteNames.mentor,
            builder: (_, __) => const MentorScreen(),
          ),
        ],
      ),
    ],
  );
});

// ── Shell — wraps all screens with bottom nav ─────────────────────────────────

class RichShell extends ConsumerWidget {
  final Widget child;
  const RichShell({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lockedFeatures = ref.watch(lockedFeaturesProvider);
    final location = GoRouterState.of(context).uri.toString();

    final items = [
      _NavItem(RouteNames.dashboard, Icons.space_dashboard_outlined, 'Command'),
      _NavItem(
        RouteNames.meditation,
        Icons.self_improvement_outlined,
        'Meditate',
      ),
      _NavItem(
        RouteNames.trading,
        Icons.show_chart_outlined,
        'Trading',
        locked: lockedFeatures.contains(RichFeature.trading),
      ),
      _NavItem(
        RouteNames.betting,
        Icons.sports_soccer_outlined,
        'Betting',
        locked: lockedFeatures.contains(RichFeature.betting),
      ),
      _NavItem(RouteNames.mentor, Icons.psychology_alt_outlined, 'Mentor'),
      _NavItem(RouteNames.writing, Icons.edit_note_outlined, 'Write'),
    ];

    int currentIndex = items.indexWhere((i) => location.startsWith(i.route));
    if (currentIndex < 0) currentIndex = 0;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (idx) => context.go(items[idx].route),
        destinations: items
            .map(
              (item) => NavigationDestination(
                icon: item.locked
                    ? const Icon(Icons.lock_outline, size: AppSpacing.iconSm)
                    : Icon(item.icon),
                label: item.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _NavItem {
  final String route;
  final IconData icon;
  final String label;
  final bool locked;

  const _NavItem(this.route, this.icon, this.label, {this.locked = false});
}

// ── Locked Screen ─────────────────────────────────────────────────────────────

class LockedScreen extends ConsumerWidget {
  final String featureName;
  const LockedScreen({required this.featureName, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engine = ref.read(ruleEngineServiceProvider);
    final ruleCtx = ref.read(ruleContextProvider);

    RichFeature? feature;
    try {
      feature = RichFeature.values.firstWhere((f) => f.name == featureName);
    } catch (_) {}

    final reason = feature != null
        ? engine.lockReason(feature, ruleCtx)
        : 'This feature is currently locked.';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: AppSpacing.iconSm),
          onPressed: () => context.go(RouteNames.dashboard),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Lock icon
            const Icon(Icons.lock_outline, color: AppColors.warning, size: 36),

            const SizedBox(height: AppSpacing.xxl),

            // Feature label
            Text(
              '${featureName.toUpperCase()} LOCKED',
              style: AppTypography.label.copyWith(color: AppColors.warning),
            ),

            const SizedBox(height: AppSpacing.md),

            // Reason
            Text(reason, style: AppTypography.h2),

            const SizedBox(height: AppSpacing.x3l),

            // Info card
            RichCard(
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: AppSpacing.iconSm,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Complete the required action to unlock access.',
                      style: AppTypography.body,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Go to meditation shortcut
            RichCard(
              onTap: () => context.go(RouteNames.meditation),
              backgroundColor: AppColors.surfaceVar,
              child: Row(
                children: [
                  const Icon(
                    Icons.self_improvement_outlined,
                    size: AppSpacing.iconSm,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    'Go to Meditation',
                    style: AppTypography.h3.copyWith(fontSize: 13),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: AppSpacing.iconSm,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
