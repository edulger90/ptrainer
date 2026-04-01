import 'package:flutter/material.dart';
import '../models/attendance_record.dart';
import '../models/user.dart';
import '../models/client.dart';
import '../models/session_schedule.dart';
import '../models/trainer_weekday.dart';
import '../models/week_range.dart';

import '../services/attendance_service.dart';
import '../services/calendar_service.dart';
import '../services/error_logger.dart';
import '../services/period_service.dart';
import '../services/screen_preload_service.dart';
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
  final _attendanceService = AttendanceService();
  final _calendarService = CalendarService();
  final _periodService = PeriodService();

  Color _colorForClient(Client client) {
    // Deterministic color from client id or name
    final palette = [
      const Color(0xFF00ACC1),
      const Color(0xFF43A047),
      const Color(0xFFFFB300),
      const Color(0xFF8E24AA),
      const Color(0xFF1E88E5),
      const Color(0xFFE91E63),
      const Color(0xFFFB8C00),
      const Color(0xFF00897B),
      const Color(0xFF3949AB),
      const Color(0xFFD81B60),
      const Color(0xFF6D4C41),
      const Color(0xFF00838F),
      const Color(0xFF7CB342),
      const Color(0xFFF4511E),
    ];
    int hash = client.id ?? client.fullName.hashCode;
    return palette[hash.abs() % palette.length];
  }

  final _screenPreloadService = ScreenPreloadService();
  bool _loading = true;
  bool _showPassiveClients = false;

  // Gün -> List of (Client, SessionSchedule, currentLessonCount, totalLessons)
  Map<TrainerWeekday, List<_ClientScheduleInfo>> _schedulesByDay = {};

  late final WeekRange _currentWeek;

  @override
  void initState() {
    super.initState();
    _currentWeek = _calendarService.weekOf(DateTime.now());
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userId = widget.currentUser.id;
      if (userId == null) return;

      final clientPreloads = await _screenPreloadService
          .loadWeeklyClientPreloads(
            userId: userId,
            startDate: _currentWeek.start,
            endDate: _currentWeek.end,
          );
      final schedulesByDay = <TrainerWeekday, List<_ClientScheduleInfo>>{};

      for (final day in TrainerWeekday.values) {
        schedulesByDay[day] = [];
      }

      for (final preload in clientPreloads) {
        final client = preload.client;
        // Pasif client'ları filtrele (switch'e göre)
        if (!_showPassiveClients && client.isActive == false) continue;
        final schedules = preload.schedules;
        final periods = preload.periods;

        final active = _periodService.findActivePeriod(periods);
        final last = _periodService.findLastPeriod(periods);
        int completedLessons = 0;
        bool hasActive = false;
        // Period? displayPeriod; // No longer needed
        int displayPeriodIndex = -1;
        final periodAttendanceRecords = preload.relevantPeriodAttendance;

        if (active.period != null && active.period!.id != null) {
          completedLessons = _attendanceService.completedLessonCount(
            periodAttendanceRecords,
          );

          final effectiveEnd = DateTime.parse(
            active.period!.postponedEndDate ?? active.period!.endDate,
          );
          final lastLessonAttendance = periodAttendanceRecords
              .where((record) => record.lessonDate == effectiveEnd)
              .firstOrNull;
          bool periodReallyEnded = false;
          if (lastLessonAttendance != null && lastLessonAttendance.attended) {
            periodReallyEnded = true;
          }
          hasActive = !periodReallyEnded;
          // displayPeriod = active.period;
          displayPeriodIndex = active.index;
        } else if (last.period != null && last.period!.id != null) {
          // displayPeriod = last.period;
          displayPeriodIndex = last.index;
          completedLessons = _attendanceService.completedLessonCount(
            periodAttendanceRecords,
          );
        }

        final showPeriodLabel = displayPeriodIndex > 0;
        final handledLessonDays = <TrainerWeekday>{};
        final attendanceRecords = preload.weeklyAttendance;

        for (final attendance in attendanceRecords) {
          final lessonDate = attendance.lessonDate;
          if (_attendanceService.isWithinRange(
            lessonDate,
            start: _currentWeek.start,
            end: _currentWeek.end,
          )) {
            final lessonDay = _dayFor(lessonDate!);
            if (lessonDay != null) handledLessonDays.add(lessonDay);
          }

          final resolvedEntry = _attendanceService.resolveWeeklyPlacement(
            attendance: attendance,
            week: _currentWeek,
            schedules: schedules,
          );
          if (resolvedEntry == null) continue;

          final day = _dayFor(resolvedEntry.showDate);
          if (day == null || !schedulesByDay.containsKey(day)) continue;

          final matchingSchedule = _findScheduleForDay(schedules, day);
          if (matchingSchedule == null) continue;

          schedulesByDay[day]!.add(
            _ClientScheduleInfo(
              client: client,
              schedule: matchingSchedule,
              displayTime: resolvedEntry.showTime,
              isMakeup: resolvedEntry.isMakeup,
              status: resolvedEntry.status,
              completedLessons: completedLessons,
              totalLessons: client.sessionPackage,
              hasActivePeriod: hasActive,
              activePeriodIndex: displayPeriodIndex,
              showPeriodLabel: showPeriodLabel,
            ),
          );
        }

        for (final schedule in schedules) {
          final lessonDate = _lessonDateForSchedule(schedule);
          if (lessonDate == null) continue;

          final lessonDay = _dayFor(lessonDate);
          if (lessonDay == null) continue;
          if (handledLessonDays.contains(lessonDay)) continue;

          schedulesByDay[lessonDay]!.add(
            _ClientScheduleInfo(
              client: client,
              schedule: schedule,
              displayTime: schedule.time,
              isMakeup: false,
              status: LessonAttendanceStatus.pending,
              completedLessons: completedLessons,
              totalLessons: client.sessionPackage,
              hasActivePeriod: hasActive,
              activePeriodIndex: displayPeriodIndex,
              showPeriodLabel: showPeriodLabel,
            ),
          );
        }
      }

      // Her gün için saate göre sırala
      for (final day in TrainerWeekday.values) {
        schedulesByDay[day]!.sort(
          (a, b) => a.displayTime.compareTo(b.displayTime),
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

  SessionSchedule? _findScheduleForDay(
    List<SessionSchedule> schedules,
    TrainerWeekday day,
  ) {
    for (final schedule in schedules) {
      if (schedule.dayOfWeek == day.storageKey) return schedule;
    }
    return null;
  }

  DateTime? _lessonDateForSchedule(SessionSchedule schedule) {
    return _calendarService.lessonDateForSchedule(schedule, _currentWeek);
  }

  TrainerWeekday? _dayFor(DateTime date) {
    return TrainerWeekday.fromDate(date);
  }

  Color _statusColor(LessonAttendanceStatus status, Color fallback) {
    switch (status) {
      case LessonAttendanceStatus.cancelled:
        return Colors.red[700]!;
      case LessonAttendanceStatus.absent:
        return Colors.red[700]!;
      case LessonAttendanceStatus.attended:
        return Colors.green[700]!;
      case LessonAttendanceStatus.pending:
        return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // Her gün tab'ı için renk
    return DefaultTabController(
      length: TrainerWeekday.values.length,
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
                // Pasif client göster switch'i başlık altına taşındı
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        l.showPassiveClients,
                        style: const TextStyle(fontSize: 13),
                      ),
                      Switch(
                        value: _showPassiveClients,
                        onChanged: (val) {
                          setState(() {
                            _showPassiveClients = val;
                            _loading = true;
                          });
                          _loadData();
                        },
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
                  tabs: TrainerWeekday.values
                      .map((day) => Tab(text: day.localized(context)))
                      .toList(),
                ),
                // ── İçerik ──
                Expanded(
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : TabBarView(
                          children: List.generate(
                            TrainerWeekday.values.length,
                            (i) => _buildDayView(
                              TrainerWeekday.values[i],
                              Colors.grey,
                            ),
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

  Widget _buildDayView(TrainerWeekday day, Color dayColor) {
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
        final progress = info.totalLessons > 0
            ? info.completedLessons / info.totalLessons
            : 0.0;
        final color = _colorForClient(client);
        final accentColor = _statusColor(info.status, color);
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
                    color: color.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.1),
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
                          color: accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 18,
                              color: accentColor,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              info.displayTime,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: accentColor,
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
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: accentColor,
                              ),
                            ),
                            if (info.isMakeup) const SizedBox(height: 4),
                            if (info.isMakeup)
                              Text(
                                l.makeup,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange[700],
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
                                      backgroundColor: color.withValues(
                                        alpha: 0.12,
                                      ),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        color,
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
                                    color: color,
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
  final String displayTime;
  final bool isMakeup;
  final LessonAttendanceStatus status;
  final int completedLessons;
  final int totalLessons;
  final bool hasActivePeriod;
  final int activePeriodIndex;
  final bool showPeriodLabel;

  _ClientScheduleInfo({
    required this.client,
    required this.schedule,
    required this.displayTime,
    required this.isMakeup,
    required this.status,
    required this.completedLessons,
    required this.totalLessons,
    required this.hasActivePeriod,
    required this.activePeriodIndex,
    required this.showPeriodLabel,
  });
}
