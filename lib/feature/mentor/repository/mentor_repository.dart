// lib/feature/mentor/repository/mentor_repository.dart

import '../../../core/constants/hive_boxes.dart';
import '../../../core/services/hive_service.dart';
import '../model/mentor_models.dart';

class MentorRepository {
  static const _messagesKey = 'mentor_messages';
  static const _lastMorningKey = 'mentor_last_morning';
  static const _lastSundayKey = 'mentor_last_sunday';

  List<MentorMessage> loadMessages() {
    final raw = HiveService.get<List>(HiveBoxes.aiMentor, _messagesKey) ?? [];
    return raw
        .whereType<Map>()
        .map((e) => MentorMessage.fromMap(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<void> saveMessages(List<MentorMessage> messages) async {
    await HiveService.put(
      HiveBoxes.aiMentor,
      _messagesKey,
      messages.map((m) => m.toMap()).toList(),
    );
  }

  String? loadLastMorningKey() =>
      HiveService.get<String>(HiveBoxes.aiMentor, _lastMorningKey);

  Future<void> saveLastMorningKey(String key) =>
      HiveService.put(HiveBoxes.aiMentor, _lastMorningKey, key);

  String? loadLastSundayKey() =>
      HiveService.get<String>(HiveBoxes.aiMentor, _lastSundayKey);

  Future<void> saveLastSundayKey(String key) =>
      HiveService.put(HiveBoxes.aiMentor, _lastSundayKey, key);
}
