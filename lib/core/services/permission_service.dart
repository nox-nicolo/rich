// lib/core/services/permission_service.dart

import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  PermissionService._();
  static final PermissionService instance = PermissionService._();

  static const _channel = MethodChannel('com.rich.app/overlay');

  // ── Overlay — SYSTEM_ALERT_WINDOW (Android only) ──────────────────────────

  Future<bool> hasOverlayPermission() async {
    try {
      final result =
          await _channel.invokeMethod<bool>('hasOverlayPermission');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  Future<bool> requestOverlayPermission() async {
    try {
      final result =
          await _channel.invokeMethod<bool>('requestOverlayPermission');
      return result ?? false;
    } on PlatformException {
      return false;
    }
  }

  // ── Notifications ─────────────────────────────────────────────────────────

  Future<bool> hasNotificationPermission() async {
    return await Permission.notification.isGranted;
  }

  Future<bool> requestNotificationPermission() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  // ── Camera ────────────────────────────────────────────────────────────────

  Future<bool> hasCameraPermission() async {
    return await Permission.camera.isGranted;
  }

  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  // ── Storage ───────────────────────────────────────────────────────────────

  Future<bool> hasStoragePermission() async {
    return await Permission.storage.isGranted;
  }

  Future<bool> requestStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  // ── Request all required at once ──────────────────────────────────────────

  Future<Map<Permission, PermissionStatus>> requestAllRequired() async {
    return await [
      Permission.notification,
      Permission.camera,
      Permission.storage,
    ].request();
  }

  // ── Open app settings ─────────────────────────────────────────────────────

  Future<void> openSettings() async {
    await openAppSettings();
  }
}
