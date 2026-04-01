import 'package:flutter_test/flutter_test.dart';
import 'package:ptrainer/models/period.dart';
import 'package:ptrainer/services/period_service.dart';

void main() {
  final service = PeriodService();

  Period buildPeriod({
    int? id,
    required String startDate,
    required String endDate,
    String? postponedEndDate,
  }) {
    return Period(
      id: id,
      clientId: 1,
      startDate: startDate,
      endDate: endDate,
      postponedEndDate: postponedEndDate,
    );
  }

  group('PeriodService', () {
    test('effectiveEnd prefers postponed end date when present', () {
      final period = buildPeriod(
        startDate: '2026-03-01T00:00:00.000',
        endDate: '2026-03-31T00:00:00.000',
        postponedEndDate: '2026-04-05T00:00:00.000',
      );

      expect(service.effectiveEnd(period), DateTime(2026, 4, 5));
    });

    test(
      'findActivePeriod returns first non-finished period in sorted order',
      () {
        final periods = [
          buildPeriod(
            id: 2,
            startDate: '2026-04-10T00:00:00.000',
            endDate: '2026-04-20T00:00:00.000',
          ),
          buildPeriod(
            id: 1,
            startDate: '2026-03-01T00:00:00.000',
            endDate: '2026-03-31T00:00:00.000',
          ),
        ];

        final result = service.findActivePeriod(
          periods,
          now: DateTime(2026, 4, 15),
        );

        expect(result.period?.id, 2);
        expect(result.index, 2);
      },
    );

    test('findActivePeriod falls back to last period when all are in past', () {
      final periods = [
        buildPeriod(
          id: 1,
          startDate: '2026-01-01T00:00:00.000',
          endDate: '2026-01-31T00:00:00.000',
        ),
        buildPeriod(
          id: 2,
          startDate: '2026-02-01T00:00:00.000',
          endDate: '2026-02-28T00:00:00.000',
        ),
      ];

      final result = service.findActivePeriod(
        periods,
        now: DateTime(2026, 3, 15),
      );

      expect(result.period?.id, 2);
      expect(result.index, 2);
    });

    test('findLastPeriod returns null for empty list', () {
      final result = service.findLastPeriod(const []);

      expect(result.period, isNull);
      expect(result.index, -1);
    });

    test('findLastPeriod returns latest period by start date', () {
      final periods = [
        buildPeriod(
          id: 9,
          startDate: '2026-05-01T00:00:00.000',
          endDate: '2026-05-31T00:00:00.000',
        ),
        buildPeriod(
          id: 7,
          startDate: '2026-03-01T00:00:00.000',
          endDate: '2026-03-31T00:00:00.000',
        ),
      ];

      final result = service.findLastPeriod(periods);

      expect(result.period?.id, 9);
      expect(result.index, 2);
    });
  });
}
