import 'package:flutter_test/flutter_test.dart';
import 'package:ptrainer/models/session_schedule.dart';
import 'package:ptrainer/models/trainer_weekday.dart';
import 'package:ptrainer/services/calendar_service.dart';

void main() {
  final service = CalendarService();

  group('CalendarService', () {
    test('normalizeDay strips time components', () {
      expect(
        service.normalizeDay(DateTime(2026, 4, 1, 15, 45, 12)),
        DateTime(2026, 4, 1),
      );
    });

    test('weekOf returns monday-based week range with seven days', () {
      final week = service.weekOf(DateTime(2026, 4, 2, 20));

      expect(week.start, DateTime(2026, 3, 30));
      expect(week.end, DateTime(2026, 4, 5));
      expect(week.days, hasLength(7));
      expect(week.dateFor(TrainerWeekday.monday), DateTime(2026, 3, 30));
      expect(week.dateFor(TrainerWeekday.sunday), DateTime(2026, 4, 5));
    });

    test('dayKeyFor uses normalized ISO day value', () {
      expect(
        service.dayKeyFor(DateTime(2026, 4, 1, 23, 59)),
        '2026-04-01T00:00:00.000',
      );
    });

    test('lessonDateForSchedule resolves schedule day in the given week', () {
      final week = service.weekOf(DateTime(2026, 4, 2));
      final schedule = SessionSchedule(dayOfWeek: 'Perşembe', time: '19:00');

      expect(
        service.lessonDateForSchedule(schedule, week),
        DateTime(2026, 4, 2),
      );
    });

    test('lessonDateForSchedule returns null for unknown storage key', () {
      final week = service.weekOf(DateTime(2026, 4, 2));
      final schedule = SessionSchedule(dayOfWeek: 'Thursday', time: '19:00');

      expect(service.lessonDateForSchedule(schedule, week), isNull);
    });
  });
}
