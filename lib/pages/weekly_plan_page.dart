import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/client.dart';
import '../models/session_schedule.dart';
import '../models/trainer_weekday.dart';
import '../models/week_range.dart';

import '../services/calendar_service.dart';
import '../services/error_logger.dart';
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
  final _calendarService = CalendarService();
  final _screenPreloadService = ScreenPreloadService();

  bool _loading = true;
  bool _showPassiveClients = false;

  Map<TrainerWeekday, List<_ClientScheduleInfo>> _schedulesByDay = {};

  late final WeekRange _currentWeek;

  Color _colorForClient(Client client) {
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
        if (!_showPassiveClients && client.isActive == false) continue;

        for (final schedule in preload.schedules) {
          final day = TrainerWeekday.fromStorageKey(schedule.dayOfWeek);
          if (day == null) continue;

          schedulesByDay[day]!.add(
            _ClientScheduleInfo(
              client: client,
              schedule: schedule,
              displayTime: schedule.time,
            ),
          );
        }
      }

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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
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
                            (i) => _buildDayView(TrainerWeekday.values[i]),
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

  Widget _buildDayView(TrainerWeekday day) {
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
        final color = _colorForClient(client);
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
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.access_time, size: 18, color: color),
                            const SizedBox(height: 2),
                            Text(
                              info.displayTime,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 14),
                      // İsim
                      Expanded(
                        child: Text(
                          client.fullName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Colors.grey[400]),
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

  _ClientScheduleInfo({
    required this.client,
    required this.schedule,
    required this.displayTime,
  });
}
