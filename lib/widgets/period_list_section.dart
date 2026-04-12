import 'package:flutter/material.dart';
import '../models/period.dart';
import '../models/client.dart';
import '../models/package_type.dart';
import '../models/session_schedule.dart';
import '../models/trainer_weekday.dart';
import '../pages/period_calendar_page.dart';
import '../l10n/app_localizations.dart';

/// Periyotlar listesi bölümü – renkli kartlar ile.
class PeriodListSection extends StatelessWidget {
  final List<Period> periods;
  final Client client;
  final List<SessionSchedule> schedules;
  final Map<int, int> attendedCounts;
  final VoidCallback onAddPeriod;
  final void Function(Period period) onPeriodDetail;
  final VoidCallback onDataChanged;

  const PeriodListSection({
    super.key,
    required this.periods,
    required this.client,
    required this.schedules,
    required this.attendedCounts,
    required this.onAddPeriod,
    required this.onPeriodDetail,
    required this.onDataChanged,
  });

  /// Periyot durumuna göre renk çifti döndürür (gradient başlangıç, bitiş)
  (Color, Color) _periodColors(Period period, int attended, int total) {
    // Ödeme bekliyor → turuncu tonu
    if (!period.isPaid) {
      return (const Color(0xFFE65100), const Color(0xFFFF9800));
    }
    // Tüm dersler tamamlanmış → soft hardal sarısı
    if (total > 0 && attended >= total) {
      return (const Color(0xFFC9A227), const Color(0xFFE2C275));
    }
    // Ötelenmiş bitiş var → soft amber
    if (period.postponedEndDate != null) {
      return (const Color(0xFFD4A843), const Color(0xFFE8C96A));
    }
    // Normal aktif → soft yeşil
    return (const Color(0xFF4CAF50), const Color(0xFF81C784));
  }

  String _formatDate(String isoDate) {
    try {
      final d = DateTime.parse(isoDate);
      return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    } catch (_) {
      return isoDate.substring(0, 10);
    }
  }

  int _totalLessonsForPeriod(Period period) {
    if (client.packageType == PackageType.daily) {
      return client.sessionPackage ?? 0;
    }

    final weekdays = schedules
        .map((s) => TrainerWeekday.fromStorageKey(s.dayOfWeek)?.weekdayNumber)
        .whereType<int>()
        .toSet();
    if (weekdays.isEmpty) return 0;

    final start = DateTime.tryParse(period.startDate);
    final end = DateTime.tryParse(period.endDate);
    if (start == null || end == null) return 0;

    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day);
    if (endDate.isBefore(startDate)) return 0;

    int count = 0;
    DateTime current = startDate;
    while (!current.isAfter(endDate)) {
      if (weekdays.contains(current.weekday)) count++;
      current = current.add(const Duration(days: 1));
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Başlık satırı
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.timeline, color: Color(0xFF00BCD4), size: 22),
                const SizedBox(width: 8),
                Text(
                  l.periods,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            FilledButton.icon(
              onPressed: onAddPeriod,
              icon: const Icon(Icons.add, size: 18),
              label: Text(l.newPeriod),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF00BCD4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (periods.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              children: [
                Icon(Icons.event_busy, color: Colors.grey[400], size: 40),
                const SizedBox(height: 8),
                Text(
                  l.noPeriodYet,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: periods.length,
            itemBuilder: (context, index) {
              final period = periods[index];
              final attendedCount = period.id != null
                  ? (attendedCounts[period.id!] ?? 0)
                  : 0;
              final totalCount = _totalLessonsForPeriod(period);
              final (colorStart, colorEnd) = _periodColors(
                period,
                attendedCount,
                totalCount,
              );
              final progress = totalCount > 0
                  ? attendedCount / totalCount
                  : 0.0;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: colorStart.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Column(
                    children: [
                      // ── Üst gradient bölüm ──
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [colorStart, colorEnd],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Periyot başlığı + ilerleme
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Text(
                                    l.periodNumber(periods.length - index),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    l.lessonsProgress(
                                      attendedCount,
                                      totalCount,
                                    ),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Progress bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 6,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.3,
                                ),
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Tarihler
                            Row(
                              children: [
                                const Icon(
                                  Icons.play_arrow,
                                  color: Colors.white70,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDate(period.startDate),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                const Icon(
                                  Icons.stop,
                                  color: Colors.white70,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatDate(period.endDate),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                            if (period.postponedEndDate != null) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.event_busy,
                                    color: Colors.yellowAccent,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    l.postponedInfo(
                                      _formatDate(period.postponedEndDate!),
                                    ),
                                    style: const TextStyle(
                                      color: Colors.yellowAccent,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      // ── Alt beyaz bölüm: Ödeme + Butonlar ──
                      Container(
                        width: double.infinity,
                        color: Colors.white,
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                        child: Column(
                          children: [
                            // Ödeme satırı
                            Row(
                              children: [
                                Icon(
                                  period.isPaid
                                      ? Icons.check_circle
                                      : Icons.pending,
                                  color: period.isPaid
                                      ? Colors.green
                                      : Colors.orange,
                                  size: 18,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    period.paymentAmount != null
                                        ? (period.isPaid
                                              ? l.paymentPaid(
                                                  period.paymentAmount!
                                                      .toStringAsFixed(0),
                                                )
                                              : l.paymentPending(
                                                  period.paymentAmount!
                                                      .toStringAsFixed(0),
                                                ))
                                        : l.noPaymentInfo,
                                    style: TextStyle(
                                      color: period.isPaid
                                          ? Colors.green[700]
                                          : Colors.orange[800],
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            // Butonlar
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.edit, size: 16),
                                    label: Text(
                                      l.payment,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: colorStart,
                                      side: BorderSide(color: colorStart),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                    ),
                                    onPressed: () => onPeriodDetail(period),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: FilledButton.icon(
                                    icon: const Icon(
                                      Icons.calendar_month,
                                      size: 16,
                                    ),
                                    label: Text(
                                      l.calendar,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: colorStart,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                    ),
                                    onPressed: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => PeriodCalendarPage(
                                            period: period,
                                            client: client,
                                            schedules: schedules,
                                            onAttendanceChanged: onDataChanged,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
