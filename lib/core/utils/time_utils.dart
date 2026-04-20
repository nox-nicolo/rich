// lib/core/utils/time_utils.dart

class RichTimeUtils {
  RichTimeUtils._();

  static String formatHHMM(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static String formatMMSS(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  static String formatHHMMSS(int totalSeconds) {
    final h = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  static String formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    }
    if (duration.inMinutes > 0) return '${duration.inMinutes}m';
    return '${duration.inSeconds}s';
  }

  static String formatSeconds(int seconds) {
    final m = seconds ~/ 60;
    if (m == 0) return '${seconds}s';
    return '${m}m';
  }

  static int get utcHour => DateTime.now().toUtc().hour;

  static bool isWithinRange(int startHour, int endHour) {
    final h = utcHour;
    if (endHour > startHour) {
      return h >= startHour && h < endHour;
    }
    return h >= startHour || h < endHour;
  }

  static String greetingByTime() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    if (hour < 21) return 'Good Evening';
    return 'Good Night';
  }
}
