// lib/feature/reports/view/reports_screen.dart
//
// Unified history view with two tabs:
//   1. DAILY   — per-day cards. Tap to expand into full detail per feature.
//   2. MONTHLY — aggregated per-month cards, also tap-to-expand.
//
// Collapsed view shows the date/month, feature icons, and a count chip.
// Expanded view shows every recorded stat per feature, with smart formatting
// (durations as "2h 15m", currencies with thousands separators, etc.).

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

// ── Day Card (tap to expand) ─────────────────────────────────────────────────

class _DayCard extends StatefulWidget {
  final String dateKey;
  final List<DailyRecord> records;
  final bool isToday;

  const _DayCard({
    required this.dateKey,
    required this.records,
    this.isToday = false,
  });

  @override
  State<_DayCard> createState() => _DayCardState();
}

class _DayCardState extends State<_DayCard> {
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    // Today's card opens expanded so the user lands on full detail.
    _expanded = widget.isToday;
  }

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(widget.dateKey);
    final displayDate =
        date != null ? _formatDate(date) : widget.dateKey;
    final totalFeatures = widget.records.length;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: widget.isToday
              ? AppColors.accent.withValues(alpha: 0.2)
              : AppColors.border,
          width: 0.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Tappable header ────────────────────────────────────────────────
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Row(
                children: [
                  if (widget.isToday)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: AppColors.success.withValues(alpha: 0.3),
                            width: 0.5),
                      ),
                      child: Text('TODAY',
                          style: AppTypography.chip.copyWith(
                              color: AppColors.success, fontSize: 9)),
                    ),
                  Text(displayDate,
                      style: AppTypography.h3.copyWith(fontSize: 13)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVar,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$totalFeatures',
                      style: AppTypography.mono.copyWith(
                          fontSize: 10,
                          color: AppColors.textSecondary),
                    ),
                  ),
                  const Spacer(),
                  // Feature icon row (always visible)
                  ...widget.records.take(5).map((r) {
                    final (icon, color) = _featureMeta(r.feature);
                    return Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(icon, size: 12, color: color),
                      ),
                    );
                  }),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: _expanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.chevron_right,
                        size: 18, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded body — plain conditional render, no animation,
          //    so a flaky AnimatedSize/hit-test on a real device can't hide
          //    the content after a tap.
          if (_expanded) ...[
            const Divider(
                height: 1, color: AppColors.divider, thickness: 0.5),
            const SizedBox(height: 6),
            ...List.generate(widget.records.length, (i) {
              final r = widget.records[i];
              return _FeatureSection(
                feature: r.feature,
                data: r.data,
                isLast: i == widget.records.length - 1,
              );
            }),
            const SizedBox(height: 6),
          ],
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
      itemBuilder: (_, i) =>
          _MonthCard(report: sorted[i], isCurrent: i == 0),
    );
  }
}

// ── Month Card (tap to expand) ───────────────────────────────────────────────

class _MonthCard extends StatefulWidget {
  final MonthlyReport report;
  final bool isCurrent;

  const _MonthCard({required this.report, this.isCurrent = false});

  @override
  State<_MonthCard> createState() => _MonthCardState();
}

class _MonthCardState extends State<_MonthCard> {
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _expanded = widget.isCurrent;
  }

  @override
  Widget build(BuildContext context) {
    final displayMonth = _formatYearMonth(widget.report.yearMonth);
    final featureCount = widget.report.byFeature.length;

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
          // ── Tappable header ────────────────────────────────────────────────
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVar,
                borderRadius: _expanded
                    ? const BorderRadius.vertical(
                        top: Radius.circular(AppSpacing.radiusLg))
                    : BorderRadius.circular(AppSpacing.radiusLg),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_outlined,
                      size: 16, color: AppColors.accent),
                  const SizedBox(width: 8),
                  Text(displayMonth,
                      style: AppTypography.h3.copyWith(fontSize: 14)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('$featureCount',
                        style: AppTypography.mono.copyWith(
                            fontSize: 10,
                            color: AppColors.textSecondary)),
                  ),
                  const Spacer(),
                  ...widget.report.byFeature.entries.take(5).map((e) {
                    final feature = TrackingFeatureX.fromKey(e.key);
                    if (feature == null) return const SizedBox.shrink();
                    final (icon, color) = _featureMeta(feature);
                    return Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(icon, size: 12, color: color),
                      ),
                    );
                  }),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: _expanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.chevron_right,
                        size: 18, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded body — plain conditional render (same reason as day) ──
          if (_expanded) ...[
            if (widget.report.byFeature.isEmpty)
              Padding(
                padding: const EdgeInsets.all(14),
                child: Text('No data for this month.',
                    style: AppTypography.caption
                        .copyWith(color: AppColors.textMuted)),
              )
            else ...[
              const SizedBox(height: 6),
              ...List.generate(
                  widget.report.byFeature.entries.length, (i) {
                final e =
                    widget.report.byFeature.entries.elementAt(i);
                final feature = TrackingFeatureX.fromKey(e.key);
                if (feature == null) {
                  return const SizedBox.shrink();
                }
                return _FeatureSection(
                  feature: feature,
                  data: e.value,
                  isLast: i ==
                      widget.report.byFeature.entries.length - 1,
                );
              }),
              const SizedBox(height: 6),
            ],
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

// ── Full feature section (used in expanded body) ─────────────────────────────
//
// One per feature on a given day/month. Shows the icon + label header, then
// every recorded stat as a labelled row with smart-formatted values.

class _FeatureSection extends StatelessWidget {
  final TrackingFeature feature;
  final Map<String, dynamic> data;
  final bool isLast;

  const _FeatureSection({
    required this.feature,
    required this.data,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    final (icon, color) = _featureMeta(feature);

    // Split entries into scalar stats vs item-list entries (taskItems,
    // meetingItems, etc.). Scalars render as labelled number rows; lists
    // render as a separate "what you actually did" section below them.
    final scalarEntries = <MapEntry<String, dynamic>>[];
    final listEntries   = <MapEntry<String, dynamic>>[];
    for (final e in data.entries) {
      if (e.value is List) {
        listEntries.add(e);
      } else {
        scalarEntries.add(e);
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceVar.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
              color: color.withValues(alpha: 0.15), width: 0.5),
        ),
        margin: EdgeInsets.only(bottom: isLast ? 0 : 8),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Feature header
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 14, color: color),
                ),
                const SizedBox(width: 10),
                Text(
                  feature.label,
                  style: AppTypography.label.copyWith(
                    color: color,
                    letterSpacing: 1.5,
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                Text(
                  '${scalarEntries.length} stat${scalarEntries.length == 1 ? '' : 's'}',
                  style: AppTypography.caption
                      .copyWith(color: AppColors.textMuted, fontSize: 10),
                ),
              ],
            ),
            if (scalarEntries.isNotEmpty) const SizedBox(height: 10),
            // Scalar stat rows
            ...scalarEntries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(
                        child: Text(
                          _humanizeKey(e.key),
                          style: AppTypography.body.copyWith(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _fmtValue(e.key, e.value),
                        style: AppTypography.mono.copyWith(
                          fontSize: 12,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                )),

            // Item-list sections (taskItems, meetingItems, …)
            ...listEntries.map((e) => _ItemList(
                  sectionKey: e.key,
                  items: List<dynamic>.from(e.value as List),
                  color: color,
                )),
          ],
        ),
      ),
    );
  }
}

// ── Item list (used for taskItems / meetingItems / etc.) ─────────────────────
//
// Renders a list of completed tasks or meetings with their full title,
// description / agenda, and duration. This is the "report writing" content
// the user reviews at the end of the day or month.

class _ItemList extends StatelessWidget {
  final String sectionKey;
  final List<dynamic> items;
  final Color color;

  const _ItemList({
    required this.sectionKey,
    required this.items,
    required this.color,
  });

  String get _label {
    switch (sectionKey) {
      case 'taskItems':    return 'Tasks done';
      case 'meetingItems': return 'Meetings';
      default:
        return _humanizeKey(sectionKey);
    }
  }

  IconData get _icon {
    switch (sectionKey) {
      case 'taskItems':    return Icons.check_circle_outline;
      case 'meetingItems': return Icons.groups_outlined;
      default:             return Icons.label_important_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sub-section header
          Row(
            children: [
              Icon(_icon, size: 12, color: color),
              const SizedBox(width: 6),
              Text(
                _label.toUpperCase(),
                style: AppTypography.chip.copyWith(
                  color: color,
                  fontSize: 9,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${items.length}',
                style: AppTypography.mono.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...items.asMap().entries.map((entry) {
            final i = entry.key;
            final raw = entry.value;
            if (raw is! Map) return const SizedBox.shrink();
            final m = Map<String, dynamic>.from(raw);
            return _ItemTile(
              index:    i + 1,
              title:    (m['title'] as String?) ?? '',
              detail:   ((m['description'] ?? m['agenda'] ?? '') as String?) ?? '',
              outcome:  (m['outcome'] as String?) ?? '',
              minutes:  (m['minutes'] as num?)?.toInt(),
              priority: m['priority'] as String?,
              color:    color,
            );
          }),
        ],
      ),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final int     index;
  final String  title;
  final String  detail;
  final String  outcome;
  final int?    minutes;
  final String? priority;
  final Color   color;

  const _ItemTile({
    required this.index,
    required this.title,
    required this.detail,
    required this.outcome,
    required this.minutes,
    required this.priority,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(
          horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
            color: color.withValues(alpha: 0.10), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 22,
                child: Text(
                  '$index.',
                  style: AppTypography.mono.copyWith(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  title.isEmpty ? '(untitled)' : title,
                  style: AppTypography.body.copyWith(
                    fontSize: 12.5,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ),
              if (minutes != null && minutes! > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    _fmtMins(minutes!),
                    style: AppTypography.mono.copyWith(
                      fontSize: 10,
                      color: color,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (detail.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 22),
              child: Text(
                detail.trim(),
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  height: 1.4,
                ),
              ),
            ),
          ],
          if (outcome.trim().isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 22),
              child: Row(
                children: [
                  Icon(Icons.flag_outlined,
                      size: 10, color: color.withValues(alpha: 0.7)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      outcome.trim(),
                      style: AppTypography.caption.copyWith(
                        color: color.withValues(alpha: 0.85),
                        fontSize: 11,
                        height: 1.4,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (priority != null && priority!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 22),
              child: Text(
                priority!.toUpperCase(),
                style: AppTypography.chip.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 8,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _fmtMins(int m) {
    if (m >= 60) {
      final h = m ~/ 60;
      final rest = m % 60;
      return rest > 0 ? '${h}h ${rest}m' : '${h}h';
    }
    return '${m}m';
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

// Pretty label per recorded stat key.
//
// Keys we know about get a hand-tuned label. Anything unknown falls back to
// camelCase → spaced lowercase ("pagesRead" → "pages read") so a newly
// recorded feature still looks reasonable without code changes here.
String _humanizeKey(String key) {
  const overrides = <String, String>{
    'tasksCompleted':         'Tasks completed',
    'tasksScheduled':         'Tasks scheduled',
    'tasksDone':              'Tasks done',
    'tasksPending':           'Tasks carried over',
    'tasksBlocked':           'Tasks blocked',
    'tasksCancelled':         'Tasks cancelled',
    'sessions':               'Focus sessions',
    'deepSessions':           'Deep work sessions',
    'totalSeconds':           'Time focused',
    'taskPlannedSeconds':     'Planned task time',
    'taskActualSeconds':      'Actual task time',
    'taskOverrunSeconds':     'Overrun time',
    'meetings':               'Meetings',
    'meetingActualMinutes':   'Meeting duration',
    'meetingPlannedMinutes':  'Planned meeting',
    'logs':                   'Transactions',
    'income':                 'Income',
    'expense':                'Expenses',
    'pnl':                    'Net P&L',
    'kept':                   'Kept aside',
    'wins':                   'Wins',
    'losses':                 'Losses',
    'stepsSettled':           'Steps settled',
    'pages':                  'Pages read',
    'pagesRead':              'Pages read',
    'highlights':             'Highlights',
    'words':                  'Words written',
    'wordsWritten':           'Words written',
    'minutes':                'Minutes',
  };
  if (overrides.containsKey(key)) return overrides[key]!;
  return key
      .replaceAllMapped(
          RegExp(r'([a-z])([A-Z])'),
          (m) => '${m[1]} ${m[2]!.toLowerCase()}')
      .replaceFirstMapped(
          RegExp(r'^([a-z])'), (m) => m[1]!.toUpperCase());
}

// Format a recorded value based on its key. Times become durations,
// money keys get thousands separators, everything else falls through.
String _fmtValue(String key, dynamic raw) {
  final n = raw is num
      ? raw.toDouble()
      : double.tryParse('$raw') ?? 0.0;
  final lower = key.toLowerCase();

  if (lower.contains('seconds')) {
    return _fmtDuration(n.toInt());
  }
  if (lower.contains('minutes') && key != 'minutes') {
    // e.g. meetingActualMinutes — multiply to seconds for the formatter
    return _fmtDuration((n * 60).toInt());
  }
  if (lower == 'income' ||
      lower == 'expense' ||
      lower == 'pnl' ||
      lower == 'kept') {
    return '${_fmtThousands(n)} TZS';
  }
  if (n.truncateToDouble() == n) return n.toInt().toString();
  return n.toStringAsFixed(2);
}

String _fmtDuration(int seconds) {
  if (seconds <= 0) return '0s';
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  if (h > 0) return m > 0 ? '${h}h ${m}m' : '${h}h';
  if (m > 0) return s > 0 ? '${m}m ${s}s' : '${m}m';
  return '${s}s';
}

String _fmtThousands(double v) {
  final i = v.round();
  final s = i.abs().toString();
  final buf = StringBuffer();
  for (int k = 0; k < s.length; k++) {
    if (k > 0 && (s.length - k) % 3 == 0) buf.write(',');
    buf.write(s[k]);
  }
  return '${i < 0 ? '-' : ''}$buf';
}
