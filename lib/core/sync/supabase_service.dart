import 'package:supabase_flutter/supabase_flutter.dart';

import 'sync_repository.dart';

class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  static const _url = String.fromEnvironment('SUPABASE_URL');
  static const _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const _email = String.fromEnvironment('SUPABASE_SYNC_EMAIL');
  static const _password = String.fromEnvironment('SUPABASE_SYNC_PASSWORD');
  static const _autoAnonymousAuth = bool.fromEnvironment(
    'SUPABASE_AUTO_ANON_AUTH',
    defaultValue: false,
  );

  bool _initialized = false;

  bool get isConfigured => _url.isNotEmpty && _anonKey.isNotEmpty;
  bool get isInitialized => _initialized;

  SupabaseClient? get client {
    if (!_initialized) return null;
    return Supabase.instance.client;
  }

  Future<void> init() async {
    if (_initialized || !isConfigured) return;

    await Supabase.initialize(url: _url, anonKey: _anonKey);
    _initialized = true;

    if (_autoAnonymousAuth) {
      await ensureSession();
    }
  }

  Future<bool> ensureSession() async {
    final current = client;
    if (current == null) return false;
    if (current.auth.currentSession != null) return true;

    try {
      if (_email.isNotEmpty && _password.isNotEmpty) {
        final response = await current.auth.signInWithPassword(
          email: _email,
          password: _password,
        );
        return response.session != null;
      }

      if (!_autoAnonymousAuth) return false;

      final deviceId = SyncRepository().loadDeviceId();
      final response = await current.auth.signInAnonymously(
        data: {'device_id': deviceId},
      );
      return response.session != null;
    } catch (_) {
      return false;
    }
  }
}
