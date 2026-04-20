// lib/feature/milestones/repository/milestone_repository.dart

import 'package:hive/hive.dart';
import '../../../core/constants/hive_boxes.dart';
import '../../../core/services/hive_service.dart';
import '../model/milestone.dart';

class MilestoneRepository {
  Box<dynamic> get _box => HiveService.box(HiveBoxes.milestones);

  static const _key = 'milestones';

  Future<void> save(Milestone m) async {
    final List<dynamic> all =
        List.from(_box.get(_key, defaultValue: []) as List);
    final idx = all.indexWhere((e) => (e as Map)['id'] == m.id);
    if (idx >= 0) {
      all[idx] = m.toMap();
    } else {
      all.add(m.toMap());
    }
    await _box.put(_key, all);
  }

  Future<void> delete(String id) async {
    final List<dynamic> all =
        List.from(_box.get(_key, defaultValue: []) as List);
    all.removeWhere((e) => (e as Map)['id'] == id);
    await _box.put(_key, all);
  }

  List<Milestone> loadAll() {
    final List<dynamic> all =
        List.from(_box.get(_key, defaultValue: []) as List);
    return all
        .map((e) => Milestone.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList()
      ..sort((a, b) => a.targetDate.compareTo(b.targetDate));
  }
}
