// lib/features/betting/model/lockdown_model.dart

enum LockdownReason {
  consecutiveLosses,
  dailyStopReached,
  emotionalState,
  tradingSessionActive,
  manualLock,
}

extension LockdownReasonX on LockdownReason {
  String get label {
    switch (this) {
      case LockdownReason.consecutiveLosses:
        return 'Consecutive Losses';
      case LockdownReason.dailyStopReached:
        return 'Daily Stop Reached';
      case LockdownReason.emotionalState:
        return 'Emotional State';
      case LockdownReason.tradingSessionActive:
        return 'Trading Session Active';
      case LockdownReason.manualLock:
        return 'Manual Lock';
    }
  }

  String get description {
    switch (this) {
      case LockdownReason.consecutiveLosses:
        return 'You have hit the consecutive loss threshold. A cooldown is required.';
      case LockdownReason.dailyStopReached:
        return 'Daily stop limit has been reached. Betting is closed for today.';
      case LockdownReason.emotionalState:
        return 'Emotional state check flagged instability. Reset before continuing.';
      case LockdownReason.tradingSessionActive:
        return 'An active trading session is running. Betting is suspended.';
      case LockdownReason.manualLock:
        return 'You manually locked betting. Unlock when ready.';
    }
  }

  String get unlockInstruction {
    switch (this) {
      case LockdownReason.consecutiveLosses:
        return 'Wait for the cooldown timer to expire, then complete a Meditation reset.';
      case LockdownReason.dailyStopReached:
        return 'Betting resumes tomorrow. Use this time to review.';
      case LockdownReason.emotionalState:
        return 'Complete a Meditation Reset session, then recheck your emotional state.';
      case LockdownReason.tradingSessionActive:
        return 'End your Trading session to unlock Betting.';
      case LockdownReason.manualLock:
        return 'Tap unlock when you are ready to proceed with discipline.';
    }
  }
}

class LockdownModel {
  final bool isLocked;
  final LockdownReason? reason;
  final DateTime? lockedAt;
  final DateTime? cooldownExpiresAt;
  final int consecutiveLosses;

  const LockdownModel({
    required this.isLocked,
    this.reason,
    this.lockedAt,
    this.cooldownExpiresAt,
    required this.consecutiveLosses,
  });

  factory LockdownModel.unlocked() {
    return const LockdownModel(
      isLocked: false,
      consecutiveLosses: 0,
    );
  }

  bool get hasCooldown => cooldownExpiresAt != null;

  bool get cooldownActive {
    if (cooldownExpiresAt == null) return false;
    return DateTime.now().isBefore(cooldownExpiresAt!);
  }

  Duration? get remainingCooldown {
    if (cooldownExpiresAt == null) return null;
    final remaining = cooldownExpiresAt!.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }

  LockdownModel lock({
    required LockdownReason reason,
    Duration? cooldownDuration,
  }) {
    return LockdownModel(
      isLocked: true,
      reason: reason,
      lockedAt: DateTime.now(),
      cooldownExpiresAt: cooldownDuration != null
          ? DateTime.now().add(cooldownDuration)
          : null,
      consecutiveLosses: consecutiveLosses,
    );
  }

  LockdownModel unlock() {
    return LockdownModel(
      isLocked: false,
      consecutiveLosses: 0,
    );
  }

  LockdownModel incrementLoss() {
    return LockdownModel(
      isLocked: isLocked,
      reason: reason,
      lockedAt: lockedAt,
      cooldownExpiresAt: cooldownExpiresAt,
      consecutiveLosses: consecutiveLosses + 1,
    );
  }

  LockdownModel resetLosses() {
    return LockdownModel(
      isLocked: isLocked,
      reason: reason,
      lockedAt: lockedAt,
      cooldownExpiresAt: cooldownExpiresAt,
      consecutiveLosses: 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isLocked': isLocked,
      'reason': reason?.index,
      'lockedAt': lockedAt?.toIso8601String(),
      'cooldownExpiresAt': cooldownExpiresAt?.toIso8601String(),
      'consecutiveLosses': consecutiveLosses,
    };
  }

  factory LockdownModel.fromMap(Map<String, dynamic> m) {
    return LockdownModel(
      isLocked: m['isLocked'] as bool,
      reason: m['reason'] != null
          ? LockdownReason.values[m['reason'] as int]
          : null,
      lockedAt: m['lockedAt'] != null
          ? DateTime.parse(m['lockedAt'] as String)
          : null,
      cooldownExpiresAt: m['cooldownExpiresAt'] != null
          ? DateTime.parse(m['cooldownExpiresAt'] as String)
          : null,
      consecutiveLosses: m['consecutiveLosses'] as int? ?? 0,
    );
  }
}
