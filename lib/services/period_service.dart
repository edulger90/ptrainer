import '../models/period.dart';

class PeriodService {
  static final PeriodService _instance = PeriodService._internal();
  factory PeriodService() => _instance;
  PeriodService._internal();

  DateTime effectiveEnd(Period period) {
    return DateTime.parse(period.postponedEndDate ?? period.endDate);
  }

  ({Period? period, int index}) findActivePeriod(
    List<Period> periods, {
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final sorted = List<Period>.from(periods)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    for (int index = 0; index < sorted.length; index++) {
      final period = sorted[index];
      if (!effectiveEnd(period).isBefore(current)) {
        return (period: period, index: index + 1);
      }
    }
    if (sorted.isNotEmpty) {
      final lastPeriod = sorted.last;
      if (effectiveEnd(lastPeriod).isBefore(current)) {
        return (period: lastPeriod, index: sorted.length);
      }
    }
    return (period: null, index: -1);
  }

  ({Period? period, int index}) findLastPeriod(List<Period> periods) {
    if (periods.isEmpty) return (period: null, index: -1);
    final sorted = List<Period>.from(periods)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    return (period: sorted.last, index: sorted.length);
  }
}
