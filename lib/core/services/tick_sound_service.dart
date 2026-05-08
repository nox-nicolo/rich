// lib/core/services/tick_sound_service.dart
//
// Plays an alternating tick/tock tone once per second during task focus.
// The waveform is generated in memory and also written to temp WAV files.
// DeviceFileSource is more reliable than BytesSource on some Android devices,
// while the bytes remain as a fallback. No asset file is shipped with the app.

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

class TickSoundService {
  TickSoundService._();
  static final TickSoundService instance = TickSoundService._();

  static const double _tickHz = 443.0;
  static const double _tockHz = 554.0;
  static const int _sampleRate = 44100;
  static const int _durationMs = 80;
  static const double _decayRate = 28.0;
  static const double _volume = 0.50;

  AudioPlayer? _player;
  Uint8List? _tickBytes;
  Uint8List? _tockBytes;
  String? _tickPath;
  String? _tockPath;
  bool enabled = true;
  bool _ready = false;
  bool _useTock = false;

  Future<void> prime() async {
    if (_ready) return;
    _tickBytes ??= _buildWav(_tickHz);
    _tockBytes ??= _buildWav(_tockHz);

    final player = _player ??= AudioPlayer();
    await player.setReleaseMode(ReleaseMode.stop);
    await player.setPlayerMode(PlayerMode.lowLatency);

    try {
      final dir = await getTemporaryDirectory();
      final tickFile = File('${dir.path}/rich_task_tick.wav');
      final tockFile = File('${dir.path}/rich_task_tock.wav');
      if (!await tickFile.exists()) {
        await tickFile.writeAsBytes(_tickBytes!, flush: true);
      }
      if (!await tockFile.exists()) {
        await tockFile.writeAsBytes(_tockBytes!, flush: true);
      }
      _tickPath = tickFile.path;
      _tockPath = tockFile.path;
    } catch (_) {
      _tickPath = null;
      _tockPath = null;
    }

    _ready = true;
  }

  Future<void> tick() async {
    if (!enabled) return;
    try {
      await prime();
      final player = _player;
      if (player == null) return;

      await player.stop();
      final path = _useTock ? _tockPath : _tickPath;
      final bytes = _useTock ? _tockBytes : _tickBytes;
      _useTock = !_useTock;

      if (path != null) {
        await player.play(DeviceFileSource(path), volume: 1.0);
      } else {
        await player.play(BytesSource(bytes!), volume: 1.0);
      }
    } catch (_) {
      // Audio failures should never break the timer.
    }
  }

  Future<void> stop() async {
    try {
      await _player?.stop();
    } catch (_) {}
  }

  Future<void> dispose() async {
    try {
      await _player?.dispose();
    } catch (_) {}
    _player = null;
    _ready = false;
    _useTock = false;
  }

  Uint8List _buildWav(double frequencyHz) {
    final sampleCount = (_sampleRate * _durationMs) ~/ 1000;
    final samples = Int16List(sampleCount);
    for (int i = 0; i < sampleCount; i++) {
      final t = i / _sampleRate;
      final envelope = math.exp(-t * _decayRate);
      final value =
          math.sin(2 * math.pi * frequencyHz * t) * envelope * _volume;
      samples[i] = (value * 32767).clamp(-32768, 32767).toInt();
    }

    final pcmBytes = samples.buffer.asUint8List();
    final dataSize = pcmBytes.length;
    final fileSize = 36 + dataSize;

    final wav = BytesBuilder();
    wav.add(ascii.encode('RIFF'));
    _le32(wav, fileSize);
    wav.add(ascii.encode('WAVE'));
    wav.add(ascii.encode('fmt '));
    _le32(wav, 16);
    _le16(wav, 1);
    _le16(wav, 1);
    _le32(wav, _sampleRate);
    _le32(wav, _sampleRate * 2);
    _le16(wav, 2);
    _le16(wav, 16);
    wav.add(ascii.encode('data'));
    _le32(wav, dataSize);
    wav.add(pcmBytes);

    return wav.toBytes();
  }

  static void _le16(BytesBuilder b, int v) {
    b.addByte(v & 0xff);
    b.addByte((v >> 8) & 0xff);
  }

  static void _le32(BytesBuilder b, int v) {
    b.addByte(v & 0xff);
    b.addByte((v >> 8) & 0xff);
    b.addByte((v >> 16) & 0xff);
    b.addByte((v >> 24) & 0xff);
  }
}
