// lib/feature/mentor/repository/mentor_api_key_repository.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MentorApiKeyRepository {
  static const _storage = FlutterSecureStorage();
  static const _openAiKey = 'mentor_openai_api_key';

  Future<void> saveOpenAiKey(String key) async {
    final cleaned = key.trim();
    if (cleaned.isEmpty) {
      await clearOpenAiKey();
      return;
    }
    await _storage.write(key: _openAiKey, value: cleaned);
  }

  Future<String?> loadOpenAiKey() async {
    final value = await _storage.read(key: _openAiKey);
    if (value == null || value.trim().isEmpty) return null;
    return value.trim();
  }

  Future<bool> hasOpenAiKey() async => (await loadOpenAiKey()) != null;

  Future<void> clearOpenAiKey() => _storage.delete(key: _openAiKey);
}
