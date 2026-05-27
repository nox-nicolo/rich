// lib/core/services/tick_sound_service.dart
//
// Plays a lightweight system click once per second during task focus.

import 'package:flutter/services.dart';

class TickSoundService {
  TickSoundService._();
  static final TickSoundService instance = TickSoundService._();

  bool enabled = true;

  Future<void> prime() async {
    // Async no-op: callers can still warm the service without pulling a native
    // audio plugin into desktop builds.
  }

  Future<void> tick() async {
    if (!enabled) return;

    try {
      await SystemSound.play(SystemSoundType.click);
    } catch (_) {
      // Audio failures should never break the timer.
    }
  }

  Future<void> stop() async {}

  Future<void> dispose() async {}
}
