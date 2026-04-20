import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

import '../model/app_lock_settings_model.dart';
import '../repository/app_lock_repository.dart';

class AppLockState {
  final AppLockSettings settings;
  final bool isLocked;
  final bool isAuthenticating;
  final bool biometricsAvailable;
  final bool canCheckBiometrics;
  final DateTime? lastUnlockedAt;
  final DateTime? lastBackgroundedAt;
  final String pinInput;
  final String? errorMessage;
  final bool isLoading;

  const AppLockState({
    required this.settings,
    required this.isLocked,
    required this.isAuthenticating,
    required this.biometricsAvailable,
    required this.canCheckBiometrics,
    required this.lastUnlockedAt,
    required this.lastBackgroundedAt,
    required this.pinInput,
    required this.errorMessage,
    required this.isLoading,
  });

  factory AppLockState.initial() {
    return AppLockState(
      settings: AppLockSettings.initial(),
      isLocked: false,
      isAuthenticating: false,
      biometricsAvailable: false,
      canCheckBiometrics: false,
      lastUnlockedAt: null,
      lastBackgroundedAt: null,
      pinInput: '',
      errorMessage: null,
      isLoading: true,
    );
  }

  AppLockState copyWith({
    AppLockSettings? settings,
    bool? isLocked,
    bool? isAuthenticating,
    bool? biometricsAvailable,
    bool? canCheckBiometrics,
    DateTime? lastUnlockedAt,
    bool clearLastUnlockedAt = false,
    DateTime? lastBackgroundedAt,
    bool clearLastBackgroundedAt = false,
    String? pinInput,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool? isLoading,
  }) {
    return AppLockState(
      settings: settings ?? this.settings,
      isLocked: isLocked ?? this.isLocked,
      isAuthenticating: isAuthenticating ?? this.isAuthenticating,
      biometricsAvailable: biometricsAvailable ?? this.biometricsAvailable,
      canCheckBiometrics: canCheckBiometrics ?? this.canCheckBiometrics,
      lastUnlockedAt:
          clearLastUnlockedAt ? null : (lastUnlockedAt ?? this.lastUnlockedAt),
      lastBackgroundedAt: clearLastBackgroundedAt
          ? null
          : (lastBackgroundedAt ?? this.lastBackgroundedAt),
      pinInput: pinInput ?? this.pinInput,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      isLoading: isLoading ?? this.isLoading,
    );
  }

  bool get isAppLockEnabled => settings.isEnabled && settings.pinSet;

  bool get canUseBiometrics =>
      isAppLockEnabled &&
      settings.biometricsEnabled &&
      biometricsAvailable &&
      canCheckBiometrics;

  bool get shouldShowLockScreen => isAppLockEnabled && isLocked;
}

class AppLockViewModel extends StateNotifier<AppLockState>
    with WidgetsBindingObserver {
  AppLockViewModel(this._repository, this._localAuth)
      : super(AppLockState.initial()) {
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  final AppLockRepository _repository;
  final LocalAuthentication _localAuth;

  Timer? _autoLockTimer;

  Future<void> _init() async {
    state = state.copyWith(isLoading: true, clearErrorMessage: true);

    try {
      await _repository.syncPinFlag();
      final settings = _repository.loadSettings();

      final canCheck = await _safeCanCheckBiometrics();
      final available = await _safeHasAvailableBiometrics();

      final shouldStartLocked = settings.isEnabled && settings.pinSet;

      state = state.copyWith(
        settings: settings,
        canCheckBiometrics: canCheck,
        biometricsAvailable: available,
        isLocked: shouldStartLocked,
        isLoading: false,
        clearErrorMessage: true,
      );

      if (state.canUseBiometrics && state.isLocked) {
        unawaited(tryBiometricUnlock());
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to initialize app lock: $e',
      );
    }
  }

  @override
  void dispose() {
    _autoLockTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState appState) {
    if (!state.isAppLockEnabled) return;

    if (appState == AppLifecycleState.paused ||
        appState == AppLifecycleState.inactive ||
        appState == AppLifecycleState.hidden) {
      _handleBackgrounded();
      return;
    }

    if (appState == AppLifecycleState.resumed) {
      _handleResumed();
    }
  }

  void _handleBackgrounded() {
    // The OS biometric dialog briefly transitions us into inactive/paused.
    // If we treated that as a real background we'd re-arm the lock against
    // ourselves mid-auth, causing a flash of the dashboard followed by the
    // lock screen reappearing when auth resolves.
    if (state.isAuthenticating) return;

    final now = DateTime.now();

    state = state.copyWith(
      lastBackgroundedAt: now,
      clearErrorMessage: true,
    );

    _autoLockTimer?.cancel();

    if (!state.settings.lockOnBackground) return;

    final minutes = state.settings.autoLockMinutes;

    if (minutes <= 0) {
      lock();
      return;
    }

    _autoLockTimer = Timer(Duration(minutes: minutes), () {
      lock();
    });
  }

  void _handleResumed() {
    _autoLockTimer?.cancel();

    // Same guard as backgrounded: a biometric prompt causes paused→resumed
    // transitions that we must not interpret as the user returning to the
    // app. Without this, a stale lastBackgroundedAt + autoLockMinutes=0
    // would re-lock the app the instant auth succeeds.
    if (state.isAuthenticating) return;

    if (!state.settings.lockOnBackground || !state.isAppLockEnabled) return;

    final bgAt = state.lastBackgroundedAt;
    if (bgAt == null) return;

    final minutes = state.settings.autoLockMinutes;
    final now = DateTime.now();

    if (minutes <= 0) {
      lock();
    } else {
      final diff = now.difference(bgAt);
      if (diff.inMinutes >= minutes) {
        lock();
      }
    }

    if (state.canUseBiometrics && state.isLocked) {
      unawaited(tryBiometricUnlock());
    }
  }

  // ── Public actions ────────────────────────────────────────────────────────

  Future<void> refresh() async {
    await _init();
  }

  Future<void> enableLockWithPin({
    required String pin,
    bool biometricsEnabled = false,
    bool lockOnBackground = true,
    int autoLockMinutes = 0,
  }) async {
    final cleaned = pin.trim();
    if (cleaned.isEmpty) {
      state = state.copyWith(errorMessage: 'PIN cannot be empty.');
      return;
    }

    state = state.copyWith(
      isAuthenticating: true,
      clearErrorMessage: true,
    );

    try {
      await _repository.savePin(cleaned);
      await _repository.enableLock(
        biometricsEnabled: biometricsEnabled,
        lockOnBackground: lockOnBackground,
        autoLockMinutes: autoLockMinutes,
      );

      final settings = _repository.loadSettings();

      state = state.copyWith(
        settings: settings,
        isLocked: true,
        pinInput: '',
        isAuthenticating: false,
        clearErrorMessage: true,
      );

      if (state.canUseBiometrics) {
        unawaited(tryBiometricUnlock());
      }
    } catch (e) {
      state = state.copyWith(
        isAuthenticating: false,
        errorMessage: 'Failed to enable app lock: $e',
      );
    }
  }

  Future<void> disableLock() async {
    state = state.copyWith(
      isAuthenticating: true,
      clearErrorMessage: true,
    );

    try {
      await _repository.disableLock();
      final settings = _repository.loadSettings();

      state = state.copyWith(
        settings: settings,
        isLocked: false,
        pinInput: '',
        isAuthenticating: false,
        clearErrorMessage: true,
      );
    } catch (e) {
      state = state.copyWith(
        isAuthenticating: false,
        errorMessage: 'Failed to disable app lock: $e',
      );
    }
  }

  Future<void> deletePinAndDisableLock() async {
    state = state.copyWith(
      isAuthenticating: true,
      clearErrorMessage: true,
    );

    try {
      await _repository.deletePin();
      final settings = _repository.loadSettings();

      state = state.copyWith(
        settings: settings,
        isLocked: false,
        pinInput: '',
        isAuthenticating: false,
        clearErrorMessage: true,
      );
    } catch (e) {
      state = state.copyWith(
        isAuthenticating: false,
        errorMessage: 'Failed to clear app lock: $e',
      );
    }
  }

  Future<bool> verifyPinAndUnlock(String pin) async {
    final cleaned = pin.trim();
    if (cleaned.isEmpty) {
      state = state.copyWith(errorMessage: 'Enter your PIN.');
      return false;
    }

    state = state.copyWith(
      isAuthenticating: true,
      clearErrorMessage: true,
    );

    try {
      final ok = await _repository.verifyPin(cleaned);

      if (!ok) {
        state = state.copyWith(
          isAuthenticating: false,
          pinInput: '',
          errorMessage: 'Incorrect PIN.',
        );
        return false;
      }

      state = state.copyWith(
        isLocked: false,
        isAuthenticating: false,
        pinInput: '',
        lastUnlockedAt: DateTime.now(),
        clearLastBackgroundedAt: true,
        clearErrorMessage: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isAuthenticating: false,
        errorMessage: 'Failed to verify PIN: $e',
      );
      return false;
    }
  }

  Future<bool> tryBiometricUnlock() async {
    if (!state.canUseBiometrics) return false;

    state = state.copyWith(
      isAuthenticating: true,
      clearErrorMessage: true,
    );

    try {
      final didAuthenticate = await _localAuth.authenticate(
        localizedReason: 'Unlock RICH',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          sensitiveTransaction: false,
          useErrorDialogs: true,
        ),
      );

      if (!didAuthenticate) {
        state = state.copyWith(
          isAuthenticating: false,
        );
        return false;
      }

      state = state.copyWith(
        isLocked: false,
        isAuthenticating: false,
        lastUnlockedAt: DateTime.now(),
        clearLastBackgroundedAt: true,
        clearErrorMessage: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isAuthenticating: false,
        errorMessage: 'Biometric unlock failed: $e',
      );
      return false;
    }
  }

  Future<void> changePin({
    required String oldPin,
    required String newPin,
  }) async {
    final oldCleaned = oldPin.trim();
    final newCleaned = newPin.trim();

    if (oldCleaned.isEmpty || newCleaned.isEmpty) {
      state = state.copyWith(errorMessage: 'Old PIN and new PIN are required.');
      return;
    }

    state = state.copyWith(
      isAuthenticating: true,
      clearErrorMessage: true,
    );

    try {
      final changed = await _repository.changePin(
        oldPin: oldCleaned,
        newPin: newCleaned,
      );

      if (!changed) {
        state = state.copyWith(
          isAuthenticating: false,
          errorMessage: 'Old PIN is incorrect.',
        );
        return;
      }

      await _repository.syncPinFlag();

      state = state.copyWith(
        settings: _repository.loadSettings(),
        isAuthenticating: false,
        pinInput: '',
        clearErrorMessage: true,
      );
    } catch (e) {
      state = state.copyWith(
        isAuthenticating: false,
        errorMessage: 'Failed to change PIN: $e',
      );
    }
  }

  Future<void> setBiometricsEnabled(bool value) async {
    try {
      await _repository.setBiometricsEnabled(value);
      state = state.copyWith(
        settings: _repository.loadSettings(),
        clearErrorMessage: true,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to update biometric setting: $e',
      );
    }
  }

  Future<void> setLockOnBackground(bool value) async {
    try {
      await _repository.setLockOnBackground(value);
      state = state.copyWith(
        settings: _repository.loadSettings(),
        clearErrorMessage: true,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to update background lock setting: $e',
      );
    }
  }

  Future<void> setAutoLockMinutes(int minutes) async {
    try {
      await _repository.setAutoLockMinutes(minutes);
      state = state.copyWith(
        settings: _repository.loadSettings(),
        clearErrorMessage: true,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to update auto-lock time: $e',
      );
    }
  }

  void updatePinInput(String value) {
    state = state.copyWith(
      pinInput: value,
      clearErrorMessage: true,
    );
  }

  void appendPinDigit(String digit) {
    if (digit.isEmpty) return;
    if (state.pinInput.length >= 6) return;

    state = state.copyWith(
      pinInput: '${state.pinInput}$digit',
      clearErrorMessage: true,
    );
  }

  void removeLastPinDigit() {
    if (state.pinInput.isEmpty) return;

    state = state.copyWith(
      pinInput: state.pinInput.substring(0, state.pinInput.length - 1),
      clearErrorMessage: true,
    );
  }

  void clearPinInput() {
    state = state.copyWith(
      pinInput: '',
      clearErrorMessage: true,
    );
  }

  void clearError() {
    state = state.copyWith(clearErrorMessage: true);
  }

  void lock() {
    if (!state.isAppLockEnabled) return;

    state = state.copyWith(
      isLocked: true,
      pinInput: '',
      clearErrorMessage: true,
    );
  }

  void unlockUnsafeForTrustedFlow() {
    state = state.copyWith(
      isLocked: false,
      pinInput: '',
      lastUnlockedAt: DateTime.now(),
      clearErrorMessage: true,
    );
  }

  // ── Internal helpers ──────────────────────────────────────────────────────

  Future<bool> _safeCanCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _safeHasAvailableBiometrics() async {
    try {
      final available = await _localAuth.getAvailableBiometrics();
      return available.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}

// ── Providers ───────────────────────────────────────────────────────────────

final appLockRepositoryProvider = Provider<AppLockRepository>(
  (_) => AppLockRepository(),
);

final localAuthProvider = Provider<LocalAuthentication>(
  (_) => LocalAuthentication(),
);

final appLockViewModelProvider =
    StateNotifierProvider<AppLockViewModel, AppLockState>(
  (ref) => AppLockViewModel(
    ref.read(appLockRepositoryProvider),
    ref.read(localAuthProvider),
  ),
);