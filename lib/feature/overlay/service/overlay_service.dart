// lib/features/overlay/service/overlay_service.dart
//
// Communicates with the Android native layer via MethodChannel
// to show/hide/move the SYSTEM_ALERT_WINDOW overlay.
//
// Native side implementation needed in:
//   android/app/src/main/kotlin/.../MainActivity.kt
//
// Required AndroidManifest.xml permission:
//   <uses-permission android:name="android.permission.SYSTEM_ALERT_WINDOW"/>

import 'package:flutter/services.dart';

class OverlayService {
  static const _channel =
      MethodChannel('com.rich.app/overlay');

  // ── Permission ────────────────────────────────────────────────────────────

  /// Check if SYSTEM_ALERT_WINDOW is granted
  Future<bool> hasPermission() async {
    try {
      final result =
          await _channel.invokeMethod<bool>('hasOverlayPermission');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Open Android settings to grant SYSTEM_ALERT_WINDOW
  Future<bool> requestPermission() async {
    try {
      final result = await _channel
          .invokeMethod<bool>('requestOverlayPermission');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  // ── Visibility ────────────────────────────────────────────────────────────

  /// Show the floating overlay window
  Future<void> showOverlay() async {
    try {
      await _channel.invokeMethod('showOverlay');
    } on PlatformException catch (e) {
      throw OverlayServiceException(
          'Failed to show overlay: ${e.message}');
    }
  }

  /// Hide the floating overlay window
  Future<void> hideOverlay() async {
    try {
      await _channel.invokeMethod('hideOverlay');
    } on PlatformException catch (e) {
      throw OverlayServiceException(
          'Failed to hide overlay: ${e.message}');
    }
  }

  // ── Position ──────────────────────────────────────────────────────────────

  /// Update overlay window position on screen
  Future<void> updatePosition(double x, double y) async {
    try {
      await _channel.invokeMethod(
        'updateOverlayPosition',
        {'x': x, 'y': y},
      );
    } on PlatformException {
      // Non-critical — swallow silently
    }
  }

  // ── App Launch ────────────────────────────────────────────────────────────

  /// Bring the main RICH app to foreground from the overlay
  Future<void> launchMainApp() async {
    try {
      await _channel.invokeMethod('launchMainApp');
    } on PlatformException catch (e) {
      throw OverlayServiceException(
          'Failed to launch main app: ${e.message}');
    }
  }
}

class OverlayServiceException implements Exception {
  final String message;
  OverlayServiceException(this.message);

  @override
  String toString() => 'OverlayServiceException: $message';
}
