import '../models/attendance_record.dart';
import '../models/session_schedule.dart';
import '../models/trainer_weekday.dart';
import '../models/week_range.dart';

class AttendanceService {
  static final AttendanceService _instance = AttendanceService._internal();
  factory AttendanceService() => _instance;
  AttendanceService._internal();

  List<AttendanceRecord> recordsFromMaps(
    Iterable<Map<String, dynamic>> attendanceMaps,
  ) {
    return attendanceMaps.map(AttendanceRecord.fromMap).toList();
  }

  bool isWithinRange(
    DateTime? date, {
    required DateTime start,
    required DateTime end,
  }) {
    if (date == null) return false;
    final normalizedStart = DateTime(start.year, start.month, start.day);
    final normalizedEnd = DateTime(
      end.year,
      end.month,
      end.day,
      23,
      59,
      59,
      999,
    );
    return !date.isBefore(normalizedStart) && !date.isAfter(normalizedEnd);
  }

  bool isEffectivelyAttended(AttendanceRecord attendance, {DateTime? now}) {
    final current = now ?? DateTime.now();
    if (attendance.cancelled && !attendance.isPostponed) return false;
    if (attendance.attended) return true;
    if (attendance.makeupDate == null) return false;
    return !attendance.makeupDate!.isAfter(current);
  }

  LessonAttendanceStatus resolveAttendanceStatus(
    AttendanceRecord attendance, {
    DateTime? now,
  }) {
    if (attendance.cancelled && !attendance.isPostponed) {
      return LessonAttendanceStatus.cancelled;
    }
    if (isEffectivelyAttended(attendance, now: now)) {
      return LessonAttendanceStatus.attended;
    }
    if (attendance.absent && attendance.makeupDate == null) {
      return LessonAttendanceStatus.absent;
    }
    return LessonAttendanceStatus.pending;
  }

  bool countsAsCompleted(AttendanceRecord attendance, {DateTime? now}) {
    if (resolveAttendanceStatus(attendance, now: now) ==
        LessonAttendanceStatus.attended) {
      return true;
    }
    if (attendance.cancelled && !attendance.isPostponed) {
      return true;
    }
    if (attendance.absent &&
        !attendance.cancelled &&
        attendance.makeupDate == null) {
      return true;
    }
    return false;
  }

  int completedLessonCount(
    Iterable<AttendanceRecord> attendanceRecords, {
    DateTime? now,
  }) {
    return attendanceRecords
        .where((attendance) => countsAsCompleted(attendance, now: now))
        .length;
  }

  AttendancePlacement? resolveWeeklyPlacement({
    required AttendanceRecord attendance,
    required WeekRange week,
    required List<SessionSchedule> schedules,
    DateTime? now,
  }) {
    final status = resolveAttendanceStatus(attendance, now: now);
    if (status == LessonAttendanceStatus.pending &&
        week.contains(attendance.makeupDate)) {
      final makeupDate = attendance.makeupDate!;
      return AttendancePlacement(
        showDate: makeupDate,
        showTime: _formatTime(makeupDate),
        isMakeup: true,
        status: status,
      );
    }

    final lessonDate = attendance.lessonDate;
    if (!week.contains(lessonDate)) {
      return null;
    }

    return AttendancePlacement(
      showDate: lessonDate!,
      showTime: resolveScheduledTime(
        schedules: schedules,
        lessonDate: lessonDate,
      ),
      isMakeup: false,
      status: status,
    );
  }

  String resolveScheduledTime({
    required List<SessionSchedule> schedules,
    required DateTime lessonDate,
  }) {
    final dayName = TrainerWeekday.fromDate(lessonDate)?.storageKey;
    if (dayName == null) return '00:00';
    for (final schedule in schedules) {
      if (schedule.dayOfWeek == dayName) {
        return schedule.time;
      }
    }
    return '00:00';
  }

  String _formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
