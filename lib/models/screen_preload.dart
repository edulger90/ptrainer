import 'attendance_record.dart';
import 'body_measurement.dart';
import 'client.dart';
import 'period.dart';
import 'session_schedule.dart';

class WeeklyClientPreload {
  final Client client;
  final List<SessionSchedule> schedules;
  final List<Period> periods;
  final List<AttendanceRecord> weeklyAttendance;
  final List<AttendanceRecord> relevantPeriodAttendance;

  const WeeklyClientPreload({
    required this.client,
    required this.schedules,
    required this.periods,
    required this.weeklyAttendance,
    required this.relevantPeriodAttendance,
  });
}

class ClientDetailPreload {
  final Client client;
  final List<Period> periods;
  final List<SessionSchedule> schedules;
  final List<BodyMeasurement> measurements;
  final Map<int, int> completedLessonsByPeriodId;

  const ClientDetailPreload({
    required this.client,
    required this.periods,
    required this.schedules,
    required this.measurements,
    required this.completedLessonsByPeriodId,
  });
}

class ClientListItemPreload {
  final Client client;
  final Period? latestPeriod;
  final int completedLessons;

  const ClientListItemPreload({
    required this.client,
    required this.latestPeriod,
    required this.completedLessons,
  });
}

class PeriodCalendarPreload {
  final Period period;
  final List<AttendanceRecord> attendanceRecords;

  const PeriodCalendarPreload({
    required this.period,
    required this.attendanceRecords,
  });
}
