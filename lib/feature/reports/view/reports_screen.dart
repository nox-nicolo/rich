// lib/feature/reports/view/reports_screen.dart
//
// Unified history view with two sections:
//   1. LAST 35 DAYS — per-day cards with feature breakdown.
//   2. MONTHLY REPORTS — aggregated feature stats per month.

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/tracking/model/daily_record.dart';
import '../../../core/tracking/model/monthly_report.dart';
import '../../../core/tracking/tracking_feature.dart';
import '../../../core/tracking/tracking_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  late List<DailyRecord> _dailies;
  late List<MonthlyReport> _monthly;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _refresh();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _dailies = TrackingService.allDailies();
      _monthly = TrackingService.allMonthlyReports();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('REPORTS',
            style: AppTypography.label
                .copyWith(color: AppColors.textPrimary, letterSpacing: 3)),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: AppSpacing.iconSm,
                color: AppColors.textMuted),
            onPressed: () async {
              await TrackingService.runRetention();
              _refresh();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: AppColors.accent,
          indicatorWeight: 1.5,
          labelStyle: AppTypography.label,
          unselectedLabelStyle: AppTypography.label,
          labelColor: AppColors.textPrimary,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(text: 'DAILY'),
            Tab(text: 'MONTHLY'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _DailyTab(dailies: _dailies),
          _MonthlyTab(monthly: _monthly),
        ],
      ),
    );
  }
}

// ── Daily Tab ────────────────────────────────────────────────────────────────

class _DailyTab extends StatelessWidget {
  final List<DailyRecord> dailies;
  const _DailyTab({required this.dailies});

  @override
  Widget build(BuildContext context) {
    final byDate = <String, List<DailyRecord>>{};
    for (final r in dailies) {
      final k = r.date.toIso8601String().split('T').first;
      byDate.putIfAbsent(k, () => []).add(r);
    }
    final dateKeys = byDate.keys.toList()..sort((a, b) => b.compareTo(a));

    if (dateKeys.isEmpty) {
      return _EmptyState(
        icon: Icons.timeline_outlined,
        title: 'No daily records yet',
        subtitle: 'Activity from all features will appear here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 80),
      physics: const BouncingScrollPhysics(),
      itemCount: dateKeys.length,
      itemBuilder: (_, i) {
        final key = dateKeys[i];
        final records = byDate[key]!;
        return _DayCard(dateKey: key, records: records, isToday: i == 0);
      },
    );
  }
}

// ── Day Card ─────────────────────────────────────────────────────────────────

class _DayCard extends StatelessWidget {
  final String dateKey;
  final List<DailyRecord> records;
  final bool isToday;

  const _DayCard({
    required this.dateKey,
    required this.records,
    this.isToday = false,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(dateKey);
    final displayDate = date != null ? _formatDate(date) : dateKey;
    final totalFeatures = records.length;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isToday
              ? AppColors.accent.withValues(alpha: 0.2)
              : AppColors.border,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
            child: Row(
              children: [
                if (isToday)
                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.3),
                          width: 0.5),
                    ),
                    child: Text('TODAY',
                        style: AppTypography.chip
                            .copyWith(color: AppColors.success, fontSize: 9)),
                  ),
                Text(displayDate,
                    style: AppTypography.h3.copyWith(fontSize: 13)),
                const Spacer(),
                Text('$totalFeatures ${totalFeatures == 1 ? 'feature' : 'features'}',
                    style: AppTypography.caption),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Feature rows
          ...records.map((r) => _FeatureCard(
                feature: r.feature,
                data: r.data,
              )),

          const SizedBox(height: 4),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[d.weekday - 1]}, ${months[d.month]} ${d.day}';
  }
}

// ── Feature Card (inside a day) ──────────────────────────────────────────────

class _FeatureCard extends StatelessWidget {
  final TrackingFeature feature;
  final Map<String, dynamic> data;

  const _FeatureCard({required this.feature, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();

    final (icon, color) = _featureMeta(feature);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Feature icon badge
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 10),

          // Feature name + stat pills
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(feature.label,
                    style: AppTypography.chip.copyWith(
                        color: color, fontSize: 10, letterSpacing: 1)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: data.entries
                      .map((e) => _StatPill(
                            label: _humanizeKey(e.key),
                            value: _fmt(e.value),
                            color: color,
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Monthly Tab ──────────────────────────────────────────────────────────────

class _MonthlyTab extends StatelessWidget {
  final List<MonthlyReport> monthly;
  const _MonthlyTab({required this.monthly});

  @override
  Widget build(BuildContext context) {
    if (monthly.isEmpty) {
      return _EmptyState(
        icon: Icons.calendar_month_outlined,
        title: 'No monthly reports yet',
        subtitle: 'Reports are generated after daily records exceed 35 days',
      );
    }

    final sorted = [...monthly]
      ..sort((a, b) => b.yearMonth.compareTo(a.yearMonth));

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 80),
      physics: const BouncingScrollPhysics(),
      itemCount: sorted.length,
      itemBuilder: (_, i) => _MonthCard(report: sorted[i]),
    );
  }
}

// ── Month Card ───────────────────────────────────────────────────────────────

class _MonthCard extends StatelessWidget {
  final MonthlyReport report;
  const _MonthCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final displayMonth = _formatYearMonth(report.yearMonth);
    final featureCount = report.byFeature.length;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month header
          Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceVar,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusLg)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_outlined,
                    size: 16, color: AppColors.accent),
                const SizedBox(width: 8),
                Text(displayMonth,
                    style: AppTypography.h3.copyWith(fontSize: 14)),
                const Spacer(),
                Text('$featureCount features tracked',
                    style: AppTypography.caption),
              ],
            ),
          ),

          if (report.byFeature.isEmpty)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Text('No data for this month.',
                  style: AppTypography.caption
                      .copyWith(color: AppColors.textMuted)),
            )
          else ...[
            const SizedBox(height: 8),
            ...report.byFeature.entries.map((e) {
              final feature = TrackingFeatureX.fromKey(e.key);
              if (feature == null) return const SizedBox.shrink();
              return _FeatureCard(feature: feature, data: e.value);
            }),
            const SizedBox(height: 4),
          ],
        ],
      ),
    );
  }

  String _formatYearMonth(String ym) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final parts = ym.split('-');
    if (parts.length != 2) return ym;
    final m = int.tryParse(parts[1]);
    if (m == null || m < 1 || m > 12) return ym;
    return '${months[m]} ${parts[0]}';
  }
}

// ── Stat Pill ────────────────────────────────────────────────────────────────

class _StatPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceVar,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: AppTypography.mono.copyWith(fontSize: 11, color: color)),
          const SizedBox(width: 4),
          Text(label,
              style: AppTypography.caption
                  .copyWith(fontSize: 9, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

// ── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(title, style: AppTypography.body),
          const SizedBox(height: 4),
          Text(subtitle,
              style: AppTypography.caption,
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

(IconData, Color) _featureMeta(TrackingFeature f) {
  switch (f) {
    case TrackingFeature.meditation:
      return (Icons.self_improvement, const Color(0xFF9B59B6));
    case TrackingFeature.trading:
      return (Icons.candlestick_chart_outlined, const Color(0xFFE67E22));
    case TrackingFeature.betting:
      return (Icons.casino_outlined, const Color(0xFFC0392B));
    case TrackingFeature.finance:
      return (Icons.account_balance_wallet_outlined, const Color(0xFF27AE60));
    case TrackingFeature.reading:
      return (Icons.menu_book_outlined, const Color(0xFF3498DB));
    case TrackingFeature.writing:
      return (Icons.edit_note_outlined, const Color(0xFF1ABC9C));
    case TrackingFeature.work:
      return (Icons.work_outline, AppColors.accent);
    case TrackingFeature.life:
      return (Icons.favorite_border, const Color(0xFFE74C3C));
  }
}

String _humanizeKey(String key) {
  // camelCase → spaced lowercase: "pagesRead" → "pages read"
  return key
      .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]!.toLowerCase()}')
      .toLowerCase();
}

String _fmt(dynamic v) {
  if (v is double) {
    if (v.truncateToDouble() == v) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }
  return '$v';
}
