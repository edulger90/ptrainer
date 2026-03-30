import '../models/period.dart';

class PeriodUtils {
  /// Returns the active period and its index (1-based) from a list of periods.
  /// If no active period, returns (null, -1).
  static ({Period? period, int index}) findActivePeriod(List<Period> periods) {
    final sorted = List<Period>.from(periods)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    for (int i = 0; i < sorted.length; i++) {
      final period = sorted[i];
      final effectiveEnd = DateTime.parse(
        period.postponedEndDate ?? period.endDate,
      );
      // If effectiveEnd is not before today, consider active
      if (!effectiveEnd.isBefore(DateTime.now())) {
        return (period: period, index: i + 1);
      }
    }
    // If all periods ended before today, return last period as fallback
    if (sorted.isNotEmpty) {
      final lastPeriod = sorted.last;
      final lastEffectiveEnd = DateTime.parse(
        lastPeriod.postponedEndDate ?? lastPeriod.endDate,
      );
      if (lastEffectiveEnd.isBefore(DateTime.now())) {
        return (period: lastPeriod, index: sorted.length);
      }
    }
    return (period: null, index: -1);
  }

  /// Returns the last period and its index (1-based) from a list of periods.
  /// If no period, returns (null, -1).
  static ({Period? period, int index}) findLastPeriod(List<Period> periods) {
    if (periods.isEmpty) return (period: null, index: -1);
    final sorted = List<Period>.from(periods)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    return (period: sorted.last, index: sorted.length);
  }
}
