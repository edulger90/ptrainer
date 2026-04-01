import 'package:flutter_test/flutter_test.dart';
import 'package:ptrainer/models/attendance_record.dart';
import 'package:ptrainer/models/session_schedule.dart';
import 'package:ptrainer/models/week_range.dart';
import 'package:ptrainer/services/attendance_service.dart';

void main() {
  final service = AttendanceService();

  AttendanceRecord buildAttendance({
    DateTime? lessonDate,
    bool attended = false,
    bool cancelled = false,
    bool isPostponed = false,
    DateTime? makeupDate,
  }) {
    return AttendanceRecord(
      lessonDate: lessonDate,
      attended: attended,
      cancelled: cancelled,
      isPostponed: isPostponed,
      makeupDate: makeupDate,
    );
  }

  final week = WeekRange(
    start: DateTime(2026, 3, 30),
    end: DateTime(2026, 4, 5),
    days: List.generate(7, (index) => DateTime(2026, 3, 30 + index)),
  );

  group('AttendanceService', () {
    test('recordsFromMaps parses typed attendance records', () {
      final records = service.recordsFromMaps([
        {
          'id': 4,
          'clientId': 2,
          'periodId': 9,
          'lessonDate': '2026-04-01T00:00:00.000',
          'attended': 1,
          'cancelled': 0,
          'isPostponed': 0,
          'attendedDate': '2026-04-01T10:00:00.000',
          'makeupDate': null,
          'reason': '3',
        },
      ]);

      expect(records, hasLength(1));
      expect(records.first.id, 4);
      expect(records.first.attended, isTrue);
      expect(records.first.lessonDate, DateTime(2026, 4, 1));
      expect(records.first.attendedDate, DateTime(2026, 4, 1, 10));
      expect(records.first.reason, 3);
    });

    test('isEffectivelyAttended treats past makeup as attended', () {
      final attendance = buildAttendance(
        lessonDate: DateTime(2026, 4, 1),
        makeupDate: DateTime(2026, 4, 2, 9),
      );

      expect(
        service.isEffectivelyAttended(
          attendance,
          now: DateTime(2026, 4, 2, 10),
        ),
        isTrue,
      );
    });

    test(
      'resolveAttendanceStatus returns cancelled for non-postponed cancel',
      () {
        final attendance = buildAttendance(
          lessonDate: DateTime(2026, 4, 1),
          cancelled: true,
        );

        expect(
          service.resolveAttendanceStatus(attendance),
          LessonAttendanceStatus.cancelled,
        );
      },
    );

    test(
      'resolveAttendanceStatus returns absent for unattended lesson without makeup',
      () {
        final attendance = buildAttendance(lessonDate: DateTime(2026, 4, 2));

        expect(
          service.resolveAttendanceStatus(attendance),
          LessonAttendanceStatus.absent,
        );
      },
    );

    test(
      'completedLessonCount includes attended, absent, and cancelled items',
      () {
        final records = [
          buildAttendance(lessonDate: DateTime(2026, 4, 1), attended: true),
          buildAttendance(lessonDate: DateTime(2026, 4, 2), cancelled: true),
          buildAttendance(lessonDate: DateTime(2026, 4, 3)),
          buildAttendance(
            lessonDate: DateTime(2026, 4, 4),
            makeupDate: DateTime(2026, 4, 6),
            isPostponed: true,
          ),
        ];

        expect(
          service.completedLessonCount(records, now: DateTime(2026, 4, 4)),
          3,
        );
      },
    );

    test(
      'resolveWeeklyPlacement uses makeup date for pending makeup lesson',
      () {
        final attendance = buildAttendance(
          lessonDate: DateTime(2026, 4, 1),
          isPostponed: true,
          makeupDate: DateTime(2026, 4, 4, 18, 30),
        );

        final placement = service.resolveWeeklyPlacement(
          attendance: attendance,
          week: week,
          schedules: const [],
          now: DateTime(2026, 4, 2),
        );

        expect(placement, isNotNull);
        expect(placement!.showDate, DateTime(2026, 4, 4, 18, 30));
        expect(placement.showTime, '18:30');
        expect(placement.isMakeup, isTrue);
        expect(placement.status, LessonAttendanceStatus.pending);
      },
    );

    test('resolveWeeklyPlacement keeps attended lesson on original date', () {
      final attendance = buildAttendance(
        lessonDate: DateTime(2026, 4, 1),
        attended: true,
        makeupDate: DateTime(2026, 4, 4, 18, 30),
      );
      final schedules = [SessionSchedule(dayOfWeek: 'Çarşamba', time: '09:00')];

      final placement = service.resolveWeeklyPlacement(
        attendance: attendance,
        week: week,
        schedules: schedules,
        now: DateTime(2026, 4, 2),
      );

      expect(placement, isNotNull);
      expect(placement!.showDate, DateTime(2026, 4, 1));
      expect(placement.showTime, '09:00');
      expect(placement.isMakeup, isFalse);
      expect(placement.status, LessonAttendanceStatus.attended);
    });

    test(
      'resolveWeeklyPlacement returns null when lesson date is outside week',
      () {
        final attendance = buildAttendance(
          lessonDate: DateTime(2026, 4, 10),
          attended: true,
        );

        final placement = service.resolveWeeklyPlacement(
          attendance: attendance,
          week: week,
          schedules: const [],
        );

        expect(placement, isNull);
      },
    );

    test(
      'resolveScheduledTime falls back to 00:00 when schedule is missing',
      () {
        expect(
          service.resolveScheduledTime(
            schedules: const [],
            lessonDate: DateTime(2026, 4, 1),
          ),
          '00:00',
        );
      },
    );
  });
}
