import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/client.dart';
import '../models/session_schedule.dart';
import '../models/period.dart';
import '../services/database.dart';
import '../services/error_logger.dart';
import 'client_detail_page.dart';
import '../widgets/app_background.dart';
import '../l10n/app_localizations.dart';

class WeeklyPlanPage extends StatefulWidget {
  final User currentUser;
  const WeeklyPlanPage({super.key, required this.currentUser});

  @override
  State<WeeklyPlanPage> createState() => _WeeklyPlanPageState();
}

class _WeeklyPlanPageState extends State<WeeklyPlanPage> {
  final _db = AppDatabase();
  bool _loading = true;

  // Gün -> List of (Client, SessionSchedule, currentLessonCount, totalLessons)
  Map<String, List<_ClientScheduleInfo>> _schedulesByDay = {};

  // Internal day keys (matching DB storage)
  static const List<String> _days = [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar',
  ];

  String _localizedDay(BuildContext context, String dayKey) {
    final l = AppLocalizations.of(context);
    switch (dayKey) {
      case 'Pazartesi':
        return l.monday;
      case 'Salı':
        return l.tuesday;
      case 'Çarşamba':
        return l.wednesday;
      case 'Perşembe':
        return l.thursday;
      case 'Cuma':
        return l.friday;
      case 'Cumartesi':
        return l.saturday;
      case 'Pazar':
        return l.sunday;
      default:
        return dayKey;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userId = widget.currentUser.id;
      if (userId == null) return;

      final clients = await _db.getClientsByUser(userId);
      final schedulesByDay = <String, List<_ClientScheduleInfo>>{};

      for (final day in _days) {
        schedulesByDay[day] = [];
      }

      for (final client in clients) {
        final clientId = client.id;
        if (clientId == null) continue;

        final schedules = await _db.getSessionSchedulesByClient(clientId);
        final periods = await _db.getPeriodsByClient(clientId);

        // En son açık periyodu bul (bitiş tarihi bugün veya sonrası)
        Period? activePeriod;
        int activePeriodIndex =
            -1; // Kaçıncı periyot olduğunu bulmak için eklendi

        // periods listesi varsayılan olarak tarihe göre azalan (en yeni en üstte) sıralı geliyor olabilir
        // Kronolojik(en eski en üstte) olarak sıralayıp indeksini bulalım
        final sortedPeriods = List<Period>.from(periods)
          ..sort((a, b) => a.startDate.compareTo(b.startDate));

        for (int i = 0; i < sortedPeriods.length; i++) {
          final period = sortedPeriods[i];
          final endDate = DateTime.parse(period.endDate);
          if (endDate.isAfter(
            DateTime.now().subtract(const Duration(days: 1)),
          )) {
            activePeriod = period;
            activePeriodIndex = i + 1; // 1-based index
            break;
          }
        }

        // Tamamlanan ders sayısını hesapla
        // Yeşil tik + Kırmızı çarpı = tamamlanmış, İptal/erteleme sayılmaz
        int completedLessons = 0;
        if (activePeriod != null && activePeriod.id != null) {
          final attendanceRecords = await _db.getAttendanceForPeriod(
            clientId,
            activePeriod.id!,
          );
          completedLessons = attendanceRecords.values
              .where((r) => (r['cancelled'] as int? ?? 0) == 0)
              .length;
        }

        for (final schedule in schedules) {
          final day = schedule.dayOfWeek;
          if (schedulesByDay.containsKey(day)) {
            schedulesByDay[day]!.add(
              _ClientScheduleInfo(
                client: client,
                schedule: schedule,
                completedLessons: completedLessons,
                totalLessons: client.sessionPackage,
                hasActivePeriod: activePeriod != null,
                activePeriodIndex: activePeriodIndex,
              ),
            );
          }
        }
      }

      // Her gün için saate göre sırala
      for (final day in _days) {
        schedulesByDay[day]!.sort(
          (a, b) => a.schedule.time.compareTo(b.schedule.time),
        );
      }

      if (!mounted) return;
      setState(() {
        _schedulesByDay = schedulesByDay;
        _loading = false;
      });
    } catch (e, stack) {
      ErrorLogger().logError(
        error: e.toString(),
        stackTrace: stack.toString(),
        extra: '_WeeklyPlanPageState._loadData',
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // Her gün tab'ı için renk
    final tabColors = [
      const Color(0xFF00ACC1), // Pazartesi - cyan
      const Color(0xFF43A047), // Salı - green
      const Color(0xFFFFB300), // Çarşamba - amber
      const Color(0xFF8E24AA), // Perşembe - purple
      const Color(0xFF1E88E5), // Cuma - blue
      const Color(0xFFE91E63), // Cumartesi - pink
      const Color(0xFFFB8C00), // Pazar - orange
    ];
    return DefaultTabController(
      length: _days.length,
      child: Scaffold(
        body: AppBackground(
          child: SafeArea(
            child: Column(
              children: [
                // ── Üst Bar ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF00BCD4,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Color(0xFF00897B),
                            size: 20,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          l.weeklyPlan,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // ── Tab Bar ──
                TabBar(
                  isScrollable: true,
                  indicatorColor: const Color(0xFF00897B),
                  indicatorWeight: 3,
                  labelColor: const Color(0xFF00897B),
                  unselectedLabelColor: Colors.grey,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  tabs: _days
                      .map((day) => Tab(text: _localizedDay(context, day)))
                      .toList(),
                ),
                // ── İçerik ──
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : TabBarView(
                          children: List.generate(
                            _days.length,
                            (i) => _buildDayView(_days[i], tabColors[i]),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDayView(String day, Color dayColor) {
    final schedules = _schedulesByDay[day] ?? [];
    final l = AppLocalizations.of(context);

    if (schedules.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_available, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 12),
            Text(
              l.noLessonToday,
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: schedules.length,
      itemBuilder: (context, index) {
        final info = schedules[index];
        final client = info.client;
        final schedule = info.schedule;
        final progress = info.totalLessons > 0
            ? info.completedLessons / info.totalLessons
            : 0.0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder: (_) => ClientDetailPage(client: client),
                      ),
                    )
                    .then((_) => _loadData());
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: dayColor.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: dayColor.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Saat rozeti
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: dayColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.access_time, size: 18, color: dayColor),
                            const SizedBox(height: 2),
                            Text(
                              schedule.time,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: dayColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      // İsim + İlerleme
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              client.fullName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            // İlerleme çubuğu
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      backgroundColor: dayColor.withValues(
                                        alpha: 0.12,
                                      ),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        dayColor,
                                      ),
                                      minHeight: 6,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '${info.completedLessons}/${info.totalLessons}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: dayColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Periyot durumu
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: info.hasActivePeriod
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          info.hasActivePeriod
                              ? l.periodLabel(info.activePeriodIndex)
                              : l.noPeriod,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: info.hasActivePeriod
                                ? Colors.green[700]
                                : Colors.red[400],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ClientScheduleInfo {
  final Client client;
  final SessionSchedule schedule;
  final int completedLessons;
  final int totalLessons;
  final bool hasActivePeriod;
  final int activePeriodIndex;

  _ClientScheduleInfo({
    required this.client,
    required this.schedule,
    required this.completedLessons,
    required this.totalLessons,
    required this.hasActivePeriod,
    required this.activePeriodIndex,
  });
}
