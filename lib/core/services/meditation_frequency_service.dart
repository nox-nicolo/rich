// lib/core/services/meditation_frequency_service.dart

import 'package:flutter/services.dart';

class MeditationFrequencyService {
  MeditationFrequencyService._();
  static final MeditationFrequencyService instance =
      MeditationFrequencyService._();

  static const _channel = MethodChannel('com.rich.app/frequency');

  double? _playingFrequency;

  Future<void> play(double frequencyHz, {double volume = 0.14}) async {
    if (_playingFrequency == frequencyHz) return;
    _playingFrequency = frequencyHz;

    try {
      await _channel.invokeMethod<void>('play', {
        'frequencyHz': frequencyHz,
        'volume': volume.clamp(0.0, 1.0),
      });
    } catch (_) {
      _playingFrequency = null;
    }
  }

  Future<void> stop() async {
    if (_playingFrequency == null) return;
    _playingFrequency = null;

    try {
      await _channel.invokeMethod<void>('stop');
    } catch (_) {}
  }
}
