import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/constants/hive_boxes.dart';
import '../../../core/services/hive_service.dart';
import '../model/app_lock_settings_model.dart';

class AppLockRepository {
  AppLockRepository();

  static const String _settingsKey = 'security_app_lock_settings';
  static const String _pinHashKey = 'security_app_lock_pin_hash';

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  // ── Settings ──────────────────────────────────────────────────────────────

  Future<void> saveSettings(AppLockSettings settings) async {
    await HiveService.put(
      HiveBoxes.security,
      _settingsKey,
      settings.toMap(),
    );
  }

  AppLockSettings loadSettings() {
    final raw = HiveService.get<Map>(HiveBoxes.security, _settingsKey);
    if (raw == null) return AppLockSettings.initial();
    return AppLockSettings.fromMap(Map<String, dynamic>.from(raw));
  }

  Future<void> resetSettings() async {
    await saveSettings(AppLockSettings.initial());
  }

  // ── PIN storage / verification ────────────────────────────────────────────

  Future<void> savePin(String pin) async {
    final cleaned = pin.trim();
    if (cleaned.isEmpty) {
      throw ArgumentError('PIN cannot be empty');
    }

    final hash = _hashPin(cleaned);
    await _secureStorage.write(key: _pinHashKey, value: hash);

    final current = loadSettings();
    await saveSettings(
      current.copyWith(
        pinSet: true,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<bool> hasPin() async {
    final value = await _secureStorage.read(key: _pinHashKey);
    return value != null && value.isNotEmpty;
  }

  Future<bool> verifyPin(String pin) async {
    final cleaned = pin.trim();
    if (cleaned.isEmpty) return false;

    final savedHash = await _secureStorage.read(key: _pinHashKey);
    if (savedHash == null || savedHash.isEmpty) return false;

    final incomingHash = _hashPin(cleaned);
    return incomingHash == savedHash;
  }

  Future<void> deletePin() async {
    await _secureStorage.delete(key: _pinHashKey);

    final current = loadSettings();
    await saveSettings(
      current.copyWith(
        pinSet: false,
        isEnabled: false,
        biometricsEnabled: false,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<bool> changePin({
    required String oldPin,
    required String newPin,
  }) async {
    final ok = await verifyPin(oldPin);
    if (!ok) return false;

    await savePin(newPin);
    return true;
  }

  // ── Convenience methods ───────────────────────────────────────────────────

  Future<void> enableLock({
    bool biometricsEnabled = false,
    bool lockOnBackground = true,
    int autoLockMinutes = 0,
  }) async {
    final current = loadSettings();
    final pinExists = await hasPin();

    await saveSettings(
      current.copyWith(
        isEnabled: pinExists,
        biometricsEnabled: pinExists ? biometricsEnabled : false,
        lockOnBackground: lockOnBackground,
        autoLockMinutes: autoLockMinutes,
        pinSet: pinExists,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> disableLock() async {
    final current = loadSettings();
    await saveSettings(
      current.copyWith(
        isEnabled: false,
        biometricsEnabled: false,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> setBiometricsEnabled(bool value) async {
    final current = loadSettings();
    final pinExists = await hasPin();

    await saveSettings(
      current.copyWith(
        biometricsEnabled: pinExists ? value : false,
        pinSet: pinExists,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> setLockOnBackground(bool value) async {
    final current = loadSettings();
    await saveSettings(
      current.copyWith(
        lockOnBackground: value,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> setAutoLockMinutes(int minutes) async {
    final safeMinutes = minutes < 0 ? 0 : minutes;
    final current = loadSettings();

    await saveSettings(
      current.copyWith(
        autoLockMinutes: safeMinutes,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> syncPinFlag() async {
    final current = loadSettings();
    final pinExists = await hasPin();

    if (current.pinSet != pinExists) {
      await saveSettings(
        current.copyWith(
          pinSet: pinExists,
          isEnabled: pinExists ? current.isEnabled : false,
          biometricsEnabled: pinExists ? current.biometricsEnabled : false,
          updatedAt: DateTime.now(),
        ),
      );
    }
  }

  Future<void> clearAllSecurityData() async {
    await _secureStorage.delete(key: _pinHashKey);
    await HiveService.put(
      HiveBoxes.security,
      _settingsKey,
      AppLockSettings.initial().toMap(),
    );
  }

  // ── Internal helpers ──────────────────────────────────────────────────────

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }
}