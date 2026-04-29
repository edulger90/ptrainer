import '../models/attendance_record.dart';
import 'database.dart';
import 'period_service.dart';

class AttendanceActionsService {
  final AppDatabase _db = AppDatabase();
  final PeriodService _periodService = PeriodService();

  Future<bool> requiresPastPeriodConfirmation({
    required int clientId,
    required int currentPeriodId,
  }) async {
    final periods = await _db.getPeriodsByClient(clientId);
    final currentPeriod = periods
        .where((p) => p.id == currentPeriodId)
        .firstOrNull;
    if (currentPeriod == null) return false;

    final currentStart = DateTime.tryParse(currentPeriod.startDate);
    if (currentStart == null) return false;

    return periods.any((period) {
      if (period.id == currentPeriodId) return false;
      final periodStart = DateTime.tryParse(period.startDate);
      if (periodStart == null) return false;
      return periodStart.isAfter(currentStart);
    });
  }

  Future<void> toggleAttendance({
    required int clientId,
    required int periodId,
    required DateTime lessonDate,
    AttendanceRecord? existingAttendance,
  }) async {
    final att = existingAttendance;

    if (att != null && att.cancelled) {
      return;
    }

    if (att != null && att.attended && !att.cancelled) {
      await _db.deleteAttendance(
        clientId: clientId,
        periodId: periodId,
        lessonDate: lessonDate,
      );
      return;
    }

    final newAttended = att == null || att.absent;
    final effectiveAttendedDate = newAttended
        ? (att?.makeupDate ?? lessonDate)
        : null;
    await _db.upsertAttendance(
      clientId: clientId,
      periodId: periodId,
      lessonDate: lessonDate,
      attended: newAttended,
      cancelled: false,
      isPostponed: false,
      attendedDate: effectiveAttendedDate,
      makeupDate: att?.makeupDate,
      reason: null,
      reasonNote: null,
    );
  }

  Future<void> setMakeup({
    required int clientId,
    required int periodId,
    required DateTime lessonDate,
    required DateTime makeupDateTime,
    required int reason,
    String? reasonNote,
  }) async {
    await _db.upsertAttendance(
      clientId: clientId,
      periodId: periodId,
      lessonDate: lessonDate,
      attended: false,
      cancelled: false,
      isPostponed: false,
      attendedDate: null,
      makeupDate: makeupDateTime,
      reason: reason,
      reasonNote: reasonNote,
    );
  }

  Future<void> cancelLesson({
    required int clientId,
    required int periodId,
    required DateTime lessonDate,
    required bool addToEnd,
    required int reason,
    String? reasonNote,
    required Set<int> lessonWeekdays,
  }) async {
    await _db.upsertAttendance(
      clientId: clientId,
      periodId: periodId,
      lessonDate: lessonDate,
      attended: false,
      cancelled: true,
      isPostponed: addToEnd,
      attendedDate: null,
      makeupDate: null,
      reason: reason,
      reasonNote: reasonNote,
    );

    if (addToEnd && lessonWeekdays.isNotEmpty) {
      final period = await _db.getPeriodById(periodId);
      if (period == null) return;
      final currentEffectiveEnd = _periodService.effectiveEnd(period);
      final nextLessonDay = _findNextLessonDay(
        currentEffectiveEnd,
        lessonWeekdays,
      );
      await _db.updatePeriod(
        period.copyWith(postponedEndDate: nextLessonDay.toIso8601String()),
      );
    }
  }

  Future<void> undoCancelledLesson({
    required int clientId,
    required int periodId,
    required DateTime lessonDate,
    required Set<int> lessonWeekdays,
  }) async {
    await _db.upsertAttendance(
      clientId: clientId,
      periodId: periodId,
      lessonDate: lessonDate,
      attended: false,
      cancelled: false,
      isPostponed: false,
      attendedDate: null,
      makeupDate: null,
      reason: null,
      reasonNote: null,
    );

    final period = await _db.getPeriodById(periodId);
    if (period?.postponedEndDate == null || lessonWeekdays.isEmpty) return;

    final currentEnd = DateTime.parse(period!.postponedEndDate!);
    final originalEnd = DateTime.parse(period.endDate);
    final previousEnd = _findPreviousLessonDay(currentEnd, lessonWeekdays);

    final newPostponed = previousEnd.isAfter(originalEnd)
        ? previousEnd.toIso8601String()
        : null;

    await _db.updatePeriodPostponedEndDate(periodId, newPostponed);
  }

  Future<void> resetAttendance({
    required int clientId,
    required int periodId,
    required DateTime lessonDate,
    required AttendanceRecord existingAttendance,
    required Set<int> lessonWeekdays,
  }) async {
    if (existingAttendance.cancelled &&
        existingAttendance.isPostponed &&
        lessonWeekdays.isNotEmpty) {
      final period = await _db.getPeriodById(periodId);
      if (period?.postponedEndDate != null) {
        final currentEnd = DateTime.parse(period!.postponedEndDate!);
        final originalEnd = DateTime.parse(period.endDate);
        final previousEnd = _findPreviousLessonDay(currentEnd, lessonWeekdays);

        final newPostponed = previousEnd.isAfter(originalEnd)
            ? previousEnd.toIso8601String()
            : null;

        await _db.updatePeriodPostponedEndDate(periodId, newPostponed);
      }
    }

    await _db.deleteAttendance(
      clientId: clientId,
      periodId: periodId,
      lessonDate: lessonDate,
    );
  }

  Future<int> realignOpenPeriodPendingLessonsToSchedule({
    required int clientId,
    required Set<int> newLessonWeekdays,
    DateTime? now,
  }) async {
    if (newLessonWeekdays.isEmpty) return 0;

    final periods = await _db.getPeriodsByClient(clientId);
    final active = _periodService.findActivePeriod(periods, now: now).period;
    final periodId = active?.id;
    if (active == null || periodId == null) return 0;

    final effectiveEnd = _periodService.effectiveEnd(active);
    final today = _normalizeDay(now ?? DateTime.now());

    final records = await _db.getAttendanceRecordsForPeriod(clientId, periodId);
    final occupiedDays = <DateTime>{};
    final movable = <AttendanceRecord>[];
    var movedCount = 0;

    for (final record in records) {
      final lessonDate = record.lessonDate;
      if (lessonDate == null) continue;
      final normalizedDate = _normalizeDay(lessonDate);

      final isMovable =
          !record.attended &&
          !record.cancelled &&
          record.makeupDate == null &&
          !normalizedDate.isBefore(today);

      if (isMovable) {
        movable.add(record);
      } else {
        occupiedDays.add(normalizedDate);
      }
    }

    movable.sort((a, b) {
      final left = a.lessonDate ?? DateTime(1970);
      final right = b.lessonDate ?? DateTime(1970);
      return left.compareTo(right);
    });

    for (final record in movable) {
      final lessonDate = record.lessonDate;
      if (lessonDate == null) continue;

      final currentDay = _normalizeDay(lessonDate);
      final needsMove =
          !newLessonWeekdays.contains(currentDay.weekday) ||
          occupiedDays.contains(currentDay);

      DateTime targetDay = currentDay;
      if (needsMove) {
        final candidate = _findNextAvailableScheduledDay(
          start: currentDay,
          end: effectiveEnd,
          allowedWeekdays: newLessonWeekdays,
          occupiedDays: occupiedDays,
        );
        if (candidate == null) {
          occupiedDays.add(currentDay);
          continue;
        }
        targetDay = candidate;
      }

      if (!_isSameDay(currentDay, targetDay)) {
        await _db.deleteAttendance(
          clientId: clientId,
          periodId: periodId,
          lessonDate: currentDay,
        );

        await _db.upsertAttendance(
          clientId: clientId,
          periodId: periodId,
          lessonDate: targetDay,
          attended: record.attended,
          cancelled: record.cancelled,
          isPostponed: record.isPostponed,
          attendedDate: record.attendedDate,
          makeupDate: record.makeupDate,
          reason: record.reason,
          reasonNote: record.reasonNote,
        );
        movedCount++;
      }

      occupiedDays.add(targetDay);
    }

    return movedCount;
  }

  DateTime _normalizeDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime? _findNextAvailableScheduledDay({
    required DateTime start,
    required DateTime end,
    required Set<int> allowedWeekdays,
    required Set<DateTime> occupiedDays,
  }) {
    var day = _normalizeDay(start);
    final normalizedEnd = _normalizeDay(end);

    while (!day.isAfter(normalizedEnd)) {
      if (allowedWeekdays.contains(day.weekday) &&
          !occupiedDays.contains(day)) {
        return day;
      }
      day = day.add(const Duration(days: 1));
    }

    return null;
  }

  DateTime _findNextLessonDay(DateTime fromDate, Set<int> lessonWeekdays) {
    var day = fromDate.add(const Duration(days: 1));
    while (!lessonWeekdays.contains(day.weekday)) {
      day = day.add(const Duration(days: 1));
    }
    return day;
  }

  DateTime _findPreviousLessonDay(DateTime fromDate, Set<int> lessonWeekdays) {
    var day = fromDate.subtract(const Duration(days: 1));
    while (!lessonWeekdays.contains(day.weekday)) {
      day = day.subtract(const Duration(days: 1));
    }
    return day;
  }
}
