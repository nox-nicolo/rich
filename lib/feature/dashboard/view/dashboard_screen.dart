// lib/features/dashboard/view/dashboard_screen.dart

import 'dart:math' as math;

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
import 'widget/daily_wisdom_card.dart';
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
      body: Stack(
        children: [
          // ── Ambient water-glow layer ─────────────────────────────────────
          // Soft animated radial blobs drift slowly behind the content,
          // bleeding pastel light through the gaps between cards. Pure
          // decoration — IgnorePointer so it never swallows taps.
          const Positioned.fill(
            child: IgnorePointer(child: _GlowingBackground()),
          ),
          // ── Content ───────────────────────────────────────────────────────
          SafeArea(
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

                  // ── Daily Wisdom ─────────────────────────────────────
                  const DailyWisdomCard(),

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
        ],
      ),
    );
  }
}

// ── Animated water-glow background ────────────────────────────────────────────
//
// Three large, very-low-opacity radial blobs drift in slow, slightly-offset
// cycles behind the entire dashboard. The result is a subtle moving aurora
// that bleeds pastel light through the gaps between the cards — it makes
// the whole screen feel alive without competing with the content for
// attention.

class _GlowingBackground extends StatefulWidget {
  const _GlowingBackground();

  @override
  State<_GlowingBackground> createState() => _GlowingBackgroundState();
}

class _GlowingBackgroundState extends State<_GlowingBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final size = MediaQuery.of(context).size;
        final t = _ctrl.value * 2 * math.pi;

        return ClipRect(
          child: Stack(
            children: [
              // Top-left — soft white glow (the "sun")
              Positioned(
                top:  -200 + math.sin(t) * 30,
                left: -140 + math.cos(t) * 20,
                child: const _BlurBlob(
                  color:   Color(0xFFFFFFFF),
                  size:    480,
                  opacity: 0.05,
                ),
              ),

              // Right side, mid-screen — cool blue
              Positioned(
                top:   size.height * 0.32 + math.cos(t * 0.85) * 40,
                right: -180 + math.sin(t * 0.7) * 30,
                child: const _BlurBlob(
                  color:   Color(0xFF3498DB),
                  size:    420,
                  opacity: 0.05,
                ),
              ),

              // Bottom-left — warm purple
              Positioned(
                bottom: -200 + math.sin(t * 0.55 + math.pi / 3) * 35,
                left:   -120 + math.cos(t * 0.9) * 25,
                child: const _BlurBlob(
                  color:   Color(0xFF9B59B6),
                  size:    400,
                  opacity: 0.045,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BlurBlob extends StatelessWidget {
  final Color  color;
  final double size;
  final double opacity;

  const _BlurBlob({
    required this.color,
    required this.size,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width:  size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withValues(alpha: opacity),
            color.withValues(alpha: opacity * 0.5),
            color.withValues(alpha: 0),
          ],
          stops: const [0.0, 0.4, 1.0],
        ),
      ),
    );
  }
}
