// lib/features/dashboard/model/pillar_summary_model.dart

import '../../rules_engine/model/domain_models.dart';

// ── Pillar Status ─────────────────────────────────────────────────────────────

enum PillarStatus { active, idle, locked, completed, warning }

extension PillarStatusX on PillarStatus {
  String get label {
    switch (this) {
      case PillarStatus.active:    return 'ACTIVE';
      case PillarStatus.idle:      return 'IDLE';
      case PillarStatus.locked:    return 'LOCKED';
      case PillarStatus.completed: return 'DONE';
      case PillarStatus.warning:   return 'WARNING';
    }
  }
}

// ── Pillar Summary ────────────────────────────────────────────────────────────

class PillarSummary {
  final RichFeature feature;
  final String label;
  final String sublabel;
  final PillarStatus status;
  final String route;
  final String? statusDetail;   // e.g. "3 tasks pending"
  final double? progressValue;  // 0.0–1.0 for progress bar (optional)

  const PillarSummary({
    required this.feature,
    required this.label,
    required this.sublabel,
    required this.status,
    required this.route,
    this.statusDetail,
    this.progressValue,
  });

  bool get isLocked    => status == PillarStatus.locked;
  bool get isCompleted => status == PillarStatus.completed;
  bool get isActive    => status == PillarStatus.active;

  PillarSummary copyWith({
    PillarStatus? status,
    String? statusDetail,
    double? progressValue,
  }) {
    return PillarSummary(
      feature:       feature,
      label:         label,
      sublabel:      sublabel,
      status:        status        ?? this.status,
      route:         route,
      statusDetail:  statusDetail  ?? this.statusDetail,
      progressValue: progressValue ?? this.progressValue,
    );
  }
}

// ── Default Pillar Definitions ────────────────────────────────────────────────
// Static definitions — status gets overridden at runtime by the ViewModel

final class PillarDefinitions {
  PillarDefinitions._();

  static const all = [
    PillarSummary(
      feature:  RichFeature.meditation,
      label:    'MEDITATION',
      sublabel: 'Gatekeeper',
      status:   PillarStatus.idle,
      route:    '/meditation',
    ),
    PillarSummary(
      feature:  RichFeature.work,
      label:    'WORK',
      sublabel: 'Execution',
      status:   PillarStatus.idle,
      route:    '/work',
    ),
    PillarSummary(
      feature:  RichFeature.life,
      label:    'LIFE',
      sublabel: 'Body & Time',
      status:   PillarStatus.idle,
      route:    '/life',
    ),
    PillarSummary(
      feature:  RichFeature.trading,
      label:    'TRADING',
      sublabel: 'Intelligence',
      status:   PillarStatus.locked,
      route:    '/trading',
    ),
    PillarSummary(
      feature:  RichFeature.betting,
      label:    'BETTING',
      sublabel: 'Discipline',
      status:   PillarStatus.locked,
      route:    '/betting',
    ),
    PillarSummary(
      feature:  RichFeature.reading,
      label:    'READING',
      sublabel: 'Knowledge In',
      status:   PillarStatus.idle,
      route:    '/reading',
    ),
    PillarSummary(
      feature:  RichFeature.writing,
      label:    'WRITING',
      sublabel: 'Knowledge Out',
      status:   PillarStatus.idle,
      route:    '/writing',
    ),
  ];
}
