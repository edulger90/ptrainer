import '../models/period.dart';

class LessonUtils {
  /// Returns the completed lesson count for a period, given attendance records.
  /// Usage: pass attendance.values and the period.
  static int completedLessonCount(
    Iterable<Map<String, dynamic>> attendanceRecords,
    Period period,
  ) {
    // For PeriodCalendarPage, isExtended logic is used for UI, but DB always stores isPostponed per attendance.
    return attendanceRecords.where((r) {
      final attended = (r['attended'] as int? ?? 0) == 1;
      final cancelled = (r['cancelled'] as int? ?? 0) == 1;
      final isPostponed = (r['isPostponed'] as int? ?? 0) == 1;
      if (attended) return true;
      if (cancelled && !isPostponed) return true;
      return false;
    }).length;
  }
}
