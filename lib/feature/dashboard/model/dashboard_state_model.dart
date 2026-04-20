// lib/features/dashboard/model/dashboard_state_model.dart

enum MentalReadiness { high, medium, low, unchecked }

extension MentalReadinessX on MentalReadiness {
  String get label {
    switch (this) {
      case MentalReadiness.high:     return 'SHARP';
      case MentalReadiness.medium:   return 'MODERATE';
      case MentalReadiness.low:      return 'LOW';
      case MentalReadiness.unchecked:return 'UNCHECKED';
    }
  }
}

class DashboardState {
  final Map<String, bool> routineProgress;
  final int disciplineScore;           // 0–100
  final String? nextRequiredAction;
  final String? nextActionRoute;       // route to navigate on tap
  final MentalReadiness mentalReadiness;
  final bool hasHighImpactNews;
  final String? workSummary;
  final bool isLoading;

  const DashboardState({
    required this.routineProgress,
    required this.disciplineScore,
    this.nextRequiredAction,
    this.nextActionRoute,
    required this.mentalReadiness,
    required this.hasHighImpactNews,
    this.workSummary,
    this.isLoading = false,
  });

  factory DashboardState.initial() => const DashboardState(
    routineProgress:    {},
    disciplineScore:    0,
    nextRequiredAction: 'Begin Morning Meditation',
    nextActionRoute:    '/meditation',
    mentalReadiness:    MentalReadiness.unchecked,
    hasHighImpactNews:  false,
    isLoading:          true,
  );

  DashboardState copyWith({
    Map<String, bool>? routineProgress,
    int? disciplineScore,
    String? nextRequiredAction,
    String? nextActionRoute,
    MentalReadiness? mentalReadiness,
    bool? hasHighImpactNews,
    String? workSummary,
    bool? isLoading,
  }) {
    return DashboardState(
      routineProgress:    routineProgress    ?? this.routineProgress,
      disciplineScore:    disciplineScore    ?? this.disciplineScore,
      nextRequiredAction: nextRequiredAction ?? this.nextRequiredAction,
      nextActionRoute:    nextActionRoute    ?? this.nextActionRoute,
      mentalReadiness:    mentalReadiness    ?? this.mentalReadiness,
      hasHighImpactNews:  hasHighImpactNews  ?? this.hasHighImpactNews,
      workSummary:        workSummary        ?? this.workSummary,
      isLoading:          isLoading          ?? this.isLoading,
    );
  }

  int get completedRoutines =>
      routineProgress.values.where((v) => v).length;

  int get totalRoutines => routineProgress.length;

  double get routineCompletionRate => totalRoutines == 0
      ? 0
      : completedRoutines / totalRoutines;
}
