import '../models/session_schedule.dart';
import '../models/trainer_weekday.dart';
import '../models/week_range.dart';

class CalendarService {
  static final CalendarService _instance = CalendarService._internal();
  factory CalendarService() => _instance;
  CalendarService._internal();

  DateTime normalizeDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  WeekRange weekOf(DateTime date) {
    final normalized = normalizeDay(date);
    final start = normalized.subtract(
      Duration(days: normalized.weekday - DateTime.monday),
    );
    final end = start.add(const Duration(days: 6));
    return WeekRange(
      start: start,
      end: end,
      days: List.generate(7, (index) => start.add(Duration(days: index))),
    );
  }

  String dayKeyFor(DateTime date) {
    return normalizeDay(date).toIso8601String();
  }

  DateTime? lessonDateForSchedule(SessionSchedule schedule, WeekRange week) {
    final day = TrainerWeekday.fromStorageKey(schedule.dayOfWeek);
    if (day == null) return null;
    return week.dateFor(day);
  }
}
