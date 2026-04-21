import 'attendance_record.dart';
import 'body_measurement.dart';
import 'client.dart';
import 'period.dart';
import 'program_type.dart';
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

class MonthlyCancellationItem {
  final Client client;
  final int cancelledCount;
  final int monthlyLessonCount;

  const MonthlyCancellationItem({
    required this.client,
    required this.cancelledCount,
    required this.monthlyLessonCount,
  });
}

class MonthlyRevenuePoint {
  final DateTime monthStart;
  final double paidAmount;
  final double expectedAmount;

  const MonthlyRevenuePoint({
    required this.monthStart,
    required this.paidAmount,
    required this.expectedAmount,
  });
}

class ProgramTypeDistributionItem {
  final ProgramType programType;
  final int count;

  const ProgramTypeDistributionItem({
    required this.programType,
    required this.count,
  });
}

class HomeMonthlyAnalyticsPreload {
  final DateTime monthStart;
  final DateTime monthEnd;
  final double totalPaidAmount;
  final double totalExpectedAmount;
  final int cancelledNonHolidayCount;
  final List<MonthlyCancellationItem> topCancelledItems;
  final List<MonthlyRevenuePoint> revenueTrend;
  final List<ProgramTypeDistributionItem> cancellationDistribution;

  const HomeMonthlyAnalyticsPreload({
    required this.monthStart,
    required this.monthEnd,
    required this.totalPaidAmount,
    required this.totalExpectedAmount,
    required this.cancelledNonHolidayCount,
    required this.topCancelledItems,
    required this.revenueTrend,
    required this.cancellationDistribution,
  });
}
