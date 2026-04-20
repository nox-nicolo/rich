// lib/core/services/vibration_service.dart
//
// App-wide haptic feedback helper. Provides a 3x heavy-impact pulse
// that feels noticeably stronger than the system default.

import 'package:flutter/services.dart';

class VibrationService {
  VibrationService._();

  /// Single heavy impact — the strongest built-in haptic.
  static Future<void> heavy() async {
    await HapticFeedback.heavyImpact();
  }

  /// Triple heavy pulse with short gaps. Feels ~3x stronger than
  /// a normal tap vibration and is used for key moments (completing
  /// tasks, session start/end, goal milestones, etc.).
  static Future<void> strongPulse() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.heavyImpact();
  }

  /// Light feedback for toggle / tap interactions.
  static Future<void> light() async {
    await HapticFeedback.lightImpact();
  }

  /// Medium feedback for selections.
  static Future<void> medium() async {
    await HapticFeedback.mediumImpact();
  }
}
