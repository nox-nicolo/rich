// lib/core/utils/string_utils.dart

class RichStringUtils {
  RichStringUtils._();

  static String capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  static String titleCase(String s) {
    return s.split(' ').map(capitalize).join(' ');
  }

  static String truncate(String s, int maxLength,
      {String ellipsis = '...'}) {
    if (s.length <= maxLength) return s;
    return '${s.substring(0, maxLength - ellipsis.length)}$ellipsis';
  }

  static String initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'
        .toUpperCase();
  }

  static bool isNullOrEmpty(String? s) =>
      s == null || s.trim().isEmpty;

  static int wordCount(String s) {
    if (s.trim().isEmpty) return 0;
    return s.trim().split(RegExp(r'\s+')).length;
  }

  static String pluralize(
      int count, String singular, String plural) {
    return count == 1 ? singular : plural;
  }

  static String compactNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000)    return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}
