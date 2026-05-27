// lib/features/overlay/service/screenshot_service.dart
//
// Handles screen capture two ways:
//   1. Full screen via Android MediaProjection (MethodChannel)
//   2. Flutter widget tree via RenderRepaintBoundary

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import '../../../core/services/app_storage_service.dart';

class ScreenshotService {
  static const _channel = MethodChannel('com.rich.app/screenshot');

  // ── Full Screen Capture (Android MediaProjection) ─────────────────────────

  /// Captures the entire screen via native Android.
  /// Returns the saved file path or null on failure.
  /// Requires MediaProjection permission — request before calling.
  Future<String?> captureScreen() async {
    try {
      final path = await _channel.invokeMethod<String>('captureScreen');
      return path;
    } on PlatformException {
      return null;
    }
  }

  // ── Widget Capture (Flutter render tree) ─────────────────────────────────

  /// Captures a Flutter widget wrapped in RepaintBoundary.
  ///
  /// Usage in widget:
  ///   final _key = GlobalKey();
  ///   RepaintBoundary(key: _key, child: MyWidget())
  ///
  ///   final file = await screenshotService.captureWidget(_key);
  Future<File?> captureWidget(GlobalKey key) async {
    try {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final bytes = byteData.buffer.asUint8List();
      return await _saveToFile(bytes);
    } catch (_) {
      return null;
    }
  }

  // ── Save Bytes to File ────────────────────────────────────────────────────

  Future<File?> saveBytesToFile(List<int> bytes) async {
    try {
      return await _saveToFile(bytes);
    } catch (_) {
      return null;
    }
  }

  Future<File> _saveToFile(List<int> bytes) async {
    final capturesDir = await AppStorageService.capturesDirectory();

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${capturesDir.path}/$timestamp.png');
    await file.writeAsBytes(bytes);
    return file;
  }

  // ── Delete Capture File ───────────────────────────────────────────────────

  Future<void> deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }

  // ── Clear All Captures ────────────────────────────────────────────────────

  Future<void> clearAllCaptures() async {
    try {
      final capturesDir = await AppStorageService.capturesDirectory();
      if (await capturesDir.exists()) {
        await capturesDir.delete(recursive: true);
      }
    } catch (_) {}
  }
}
