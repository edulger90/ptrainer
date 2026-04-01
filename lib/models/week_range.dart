import 'trainer_weekday.dart';

class WeekRange {
  final DateTime start;
  final DateTime end;
  final List<DateTime> days;

  const WeekRange({required this.start, required this.end, required this.days});

  bool contains(DateTime? date) {
    if (date == null) return false;
    return !date.isBefore(start) && !date.isAfter(end);
  }

  DateTime? dateFor(TrainerWeekday day) {
    final index = day.weekdayNumber - DateTime.monday;
    if (index < 0 || index >= days.length) return null;
    return days[index];
  }
}
