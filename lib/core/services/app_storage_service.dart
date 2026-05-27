import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../constants/hive_boxes.dart';

class AppStorageService {
  AppStorageService._();

  static Future<Directory> supportDirectory([String? child]) async {
    final base = await getApplicationSupportDirectory();
    final dir = Directory(child == null ? base.path : '${base.path}/$child');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<Directory> hiveDirectory() => supportDirectory('hive');

  static Future<Directory> coversDirectory() => supportDirectory('covers');

  static Future<Directory> writingImagesDirectory() =>
      supportDirectory('writing_images');

  static Future<Directory> capturesDirectory() =>
      supportDirectory('rich_captures');

  static Future<void> migrateLegacyHiveFiles(Directory destination) async {
    final legacyDirectories = <Directory>[
      await getApplicationDocumentsDirectory(),
    ];

    for (final source in legacyDirectories) {
      if (!_isDifferentPath(source.path, destination.path)) continue;
      await _copyHiveFiles(source, destination);
    }
  }

  static Future<void> _copyHiveFiles(
    Directory source,
    Directory destination,
  ) async {
    if (!await source.exists()) return;

    try {
      await for (final entity in source.list(followLinks: false)) {
        if (entity is! File) continue;

        final name = _basename(entity.path);
        final isHiveFile = HiveBoxes.all.any(
          (box) =>
              name == box ||
              name.startsWith('$box.') ||
              name.startsWith('${box}_'),
        );
        if (!isHiveFile) continue;

        final target = File('${destination.path}/$name');
        if (await target.exists()) continue;
        await entity.copy(target.path);
      }
    } on FileSystemException {
      return;
    }
  }

  static bool _isDifferentPath(String a, String b) {
    final left = a.endsWith(Platform.pathSeparator)
        ? a.substring(0, a.length - 1)
        : a;
    final right = b.endsWith(Platform.pathSeparator)
        ? b.substring(0, b.length - 1)
        : b;
    return left != right;
  }

  static String _basename(String path) {
    final normalized = path.replaceAll(r'\', '/');
    final slash = normalized.lastIndexOf('/');
    return slash == -1 ? normalized : normalized.substring(slash + 1);
  }
}
