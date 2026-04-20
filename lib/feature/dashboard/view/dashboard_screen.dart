// lib/features/dashboard/view/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../providers/providers.dart';
import '../viewmodel/dashboard_viewmodel.dart';
import 'widget/command_header_widget.dart';
import 'widget/discipline_score_widget.dart';
import 'widget/next_action_widget.dart';
import 'widget/news_flash_widget.dart';
import 'widget/routine_progress_widget.dart';
import 'widget/pillar_grid_widget.dart';
import 'widget/lock_status_widget.dart';
import 'widget/finance_dashboard_card.dart';
import '../../milestones/view/widgets/milestone_dashboard_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Reload routine + next action from Hive on every visit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardViewModelProvider.notifier).reload();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(dashboardViewModelProvider.notifier).reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state      = ref.watch(dashboardViewModelProvider);
    final latestNews = ref.watch(latestNewsProvider);

    if (state.isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.accent,
            strokeWidth: 1,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [

            // ── Header ──────────────────────────────────────────────────
            const SliverToBoxAdapter(
              child: CommandHeaderWidget(),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([

                  const SizedBox(height: AppSpacing.md),

                  // ── Score + Mental Readiness ─────────────────────────
                  DisciplineScoreWidget(
                    score:     state.disciplineScore,
                    readiness: state.mentalReadiness,
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ── Next Action ──────────────────────────────────────
                  if (state.nextRequiredAction != null)
                    NextActionWidget(
                      action: state.nextRequiredAction!,
                      route:  state.nextActionRoute,
                    ),

                  const SizedBox(height: AppSpacing.lg),

                  // ── High Impact News Flash ───────────────────────────
                  if (latestNews != null &&
                      latestNews.isHighImpact) ...[
                    NewsFlashWidget(news: latestNews),
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // ── Routine Progress ─────────────────────────────────
                  RoutineProgressWidget(state: state),

                  const SizedBox(height: AppSpacing.xl),

                  // ── Pillar Grid ──────────────────────────────────────
                  const PillarGridWidget(),

                  const SizedBox(height: AppSpacing.xl),

                  // ── Lock Status ──────────────────────────────────────
                  const LockStatusWidget(),

                  const SizedBox(height: AppSpacing.xl),

                  // ── Finance ──────────────────────────────────────────
                  const FinanceDashboardCard(),

                  const SizedBox(height: AppSpacing.xl),

                  // ── Milestones (6-month + yearly goals) ──────────────
                  const MilestoneDashboardCard(),

                  const SizedBox(height: AppSpacing.x3l),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
