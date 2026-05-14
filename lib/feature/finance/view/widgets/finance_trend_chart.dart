import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../model/finance_models.dart';

class FinanceTrendChart extends StatelessWidget {
  final List<FinanceAccount> accounts;
  final List<FinanceTransaction> transactions;

  const FinanceTrendChart({
    super.key,
    required this.accounts,
    required this.transactions,
  });

  @override
  Widget build(BuildContext context) {
    final series = _buildSeries();
    final net = series.firstWhere((s) => s.label == 'Net');

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPad),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CASH FLOW TREND', style: AppTypography.label),
                    const SizedBox(height: 3),
                    Text(
                      'Last 30 days: income, expenses, and net',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _fmt(net.points.last.value),
                    style: AppTypography.mono.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'NET 30D',
                    style: AppTypography.caption.copyWith(
                      color: net.points.last.value >= 0
                          ? AppColors.success
                          : AppColors.warning,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 180,
            width: double.infinity,
            child: CustomPaint(painter: _FinanceTrendPainter(series)),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: series.map(_LegendChip.new).toList(),
          ),
        ],
      ),
    );
  }

  List<_TrendSeries> _buildSeries() {
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 29));
    final days = List.generate(30, (i) => start.add(Duration(days: i)));

    final specs = const [
      _SeriesSpec(label: 'Net', color: AppColors.accent, kind: _SeriesKind.net),
      _SeriesSpec(
        label: 'Income',
        color: AppColors.success,
        kind: _SeriesKind.income,
      ),
      _SeriesSpec(
        label: 'Expenses',
        color: Color(0xFFFF5C5C),
        kind: _SeriesKind.expense,
      ),
    ];

    return specs.map((spec) {
      final points = days.map((day) {
        final endOfDay = DateTime(day.year, day.month, day.day, 23, 59, 59);
        return _TrendPoint(
          date: day,
          value: _flowThroughEndOfDay(spec.kind, start, endOfDay),
        );
      }).toList();
      return _TrendSeries(label: spec.label, color: spec.color, points: points);
    }).toList();
  }

  double _flowThroughEndOfDay(
    _SeriesKind kind,
    DateTime start,
    DateTime endOfDay,
  ) {
    var income = 0.0;
    var expense = 0.0;

    for (final tx in transactions) {
      if (tx.transactionDate.isBefore(start) ||
          tx.transactionDate.isAfter(endOfDay)) {
        continue;
      }
      switch (tx.type) {
        case TransactionType.income:
          income += tx.amount;
          break;
        case TransactionType.expense:
          expense += tx.amount;
          break;
        case TransactionType.transferIn:
        case TransactionType.transferOut:
        case TransactionType.adjustment:
          break;
      }
    }

    switch (kind) {
      case _SeriesKind.income:
        return income;
      case _SeriesKind.expense:
        return -expense;
      case _SeriesKind.net:
        return income - expense;
    }
  }

  static String _fmt(double value) {
    final abs = value.abs();
    if (abs >= 1000000) return 'TZS ${(value / 1000000).toStringAsFixed(2)}M';
    if (abs >= 1000) return 'TZS ${(value / 1000).toStringAsFixed(1)}K';
    return 'TZS ${value.toStringAsFixed(0)}';
  }
}

class _LegendChip extends StatelessWidget {
  final _TrendSeries series;

  const _LegendChip(this.series);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: series.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: series.color.withValues(alpha: 0.24),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: series.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            series.label,
            style: AppTypography.chip.copyWith(
              color: series.color,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

class _FinanceTrendPainter extends CustomPainter {
  final List<_TrendSeries> series;

  _FinanceTrendPainter(this.series);

  @override
  void paint(Canvas canvas, Size size) {
    final allValues = series.expand((s) => s.points.map((p) => p.value));
    var minY = allValues.reduce(math.min);
    var maxY = allValues.reduce(math.max);
    if ((maxY - minY).abs() < 1) {
      minY -= 1;
      maxY += 1;
    }

    final gridPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.45)
      ..strokeWidth = 0.6;
    for (var i = 0; i <= 3; i++) {
      final y = size.height * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final zero = _mapY(0, minY, maxY, size.height);
    if (zero >= 0 && zero <= size.height) {
      canvas.drawLine(
        Offset(0, zero),
        Offset(size.width, zero),
        Paint()
          ..color = AppColors.textMuted.withValues(alpha: 0.25)
          ..strokeWidth = 0.8,
      );
    }

    for (final item in series) {
      final points = item.points;
      if (points.length < 2) continue;

      final path = Path();
      for (var i = 0; i < points.length; i++) {
        final x = points.length == 1
            ? 0.0
            : size.width * (i / (points.length - 1));
        final y = _mapY(points[i].value, minY, maxY, size.height);
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      canvas.drawPath(
        path,
        Paint()
          ..color = item.color
          ..strokeWidth = item.label == 'Net' ? 2.3 : 1.8
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );

      final last = points.last;
      canvas.drawCircle(
        Offset(size.width, _mapY(last.value, minY, maxY, size.height)),
        item.label == 'All' ? 3.5 : 2.7,
        Paint()..color = item.color,
      );
    }
  }

  double _mapY(double value, double minY, double maxY, double height) {
    final t = (value - minY) / (maxY - minY);
    return height - (t * height);
  }

  @override
  bool shouldRepaint(covariant _FinanceTrendPainter oldDelegate) =>
      oldDelegate.series != series;
}

class _SeriesSpec {
  final String label;
  final Color color;
  final _SeriesKind kind;

  const _SeriesSpec({
    required this.label,
    required this.color,
    required this.kind,
  });
}

enum _SeriesKind { income, expense, net }

class _TrendSeries {
  final String label;
  final Color color;
  final List<_TrendPoint> points;

  const _TrendSeries({
    required this.label,
    required this.color,
    required this.points,
  });
}

class _TrendPoint {
  final DateTime date;
  final double value;

  const _TrendPoint({required this.date, required this.value});
}
