// lib/core/utils/date_utils.dart

class RichDateUtils {
  RichDateUtils._();

  static bool isToday(DateTime dt) {
    final now = DateTime.now();
    return dt.year == now.year &&
        dt.month == now.month &&
        dt.day == now.day;
  }

  static bool isYesterday(DateTime dt) {
    final yesterday =
        DateTime.now().subtract(const Duration(days: 1));
    return dt.year == yesterday.year &&
        dt.month == yesterday.month &&
        dt.day == yesterday.day;
  }

  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  static String formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  static String formatShort(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${dt.day} ${months[dt.month - 1]}';
  }

  static String timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60)  return 'just now';
    if (diff.inMinutes < 60)  return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)    return '${diff.inHours}h ago';
    if (diff.inDays < 7)      return '${diff.inDays}d ago';
    return formatShort(dt);
  }

  static String dayLabel(DateTime dt) {
    if (isToday(dt))     return 'Today';
    if (isYesterday(dt)) return 'Yesterday';
    return formatShort(dt);
  }

  static DateTime startOfDay(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day);

  static DateTime endOfDay(DateTime dt) =>
      DateTime(dt.year, dt.month, dt.day, 23, 59, 59);

  static int daysBetween(DateTime from, DateTime to) {
    final f = startOfDay(from);
    final t = startOfDay(to);
    return t.difference(f).inDays;
  }

  static List<DateTime> last7Days() {
    final today = DateTime.now();
    return List.generate(
      7,
      (i) => today.subtract(Duration(days: 6 - i)),
    );
  }
}
