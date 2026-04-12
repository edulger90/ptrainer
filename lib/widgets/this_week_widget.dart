import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/attendance_record.dart';
import '../models/client.dart';
import '../models/session_schedule.dart';
import '../models/trainer_weekday.dart';
import '../models/week_range.dart';
import '../models/user.dart';
import '../services/attendance_service.dart';
import '../services/calendar_service.dart';
import '../services/period_service.dart';
import '../services/screen_preload_service.dart';

class WeekClientInfo {
  final Client client;
  final String time;
  final bool isMakeup;
  final WeekEntrySource source;
  final LessonAttendanceStatus status;

  const WeekClientInfo({
    required this.client,
    required this.time,
    required this.isMakeup,
    required this.source,
    required this.status,
  });
}

enum WeekEntrySource { attendance, makeup, schedule }

class ThisWeekWidget extends StatefulWidget {
  final User currentUser;

  const ThisWeekWidget({super.key, required this.currentUser});

  @override
  State<ThisWeekWidget> createState() => _ThisWeekWidgetState();
}

class _ThisWeekWidgetState extends State<ThisWeekWidget>
    with WidgetsBindingObserver {
  final _attendanceService = AttendanceService();
  final _calendarService = CalendarService();
  final _periodService = PeriodService();
  final _screenPreloadService = ScreenPreloadService();
  final _weekScrollController = ScrollController();

  late final WeekRange _currentWeek;
  late final WeekRange _nextWeek;

  bool _isLoading = true;
  bool _isNextWeekInView = false;
  Map<String, List<WeekClientInfo>> _weekData = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _weekScrollController.addListener(_handleWeekScroll);
    _currentWeek = _calendarService.weekOf(DateTime.now());
    _nextWeek = _calendarService.weekOf(
      _currentWeek.end.add(const Duration(days: 1)),
    );
    _loadWeekData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _weekScrollController.removeListener(_handleWeekScroll);
    _weekScrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;
    setState(() {
      _isLoading = true;
    });
    _loadWeekData();
  }

  Future<void> _loadWeekData() async {
    final userId = widget.currentUser.id;
    if (userId == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      return;
    }

    final clientPreloads = await _screenPreloadService.loadWeeklyClientPreloads(
      userId: userId,
      startDate: _displayStart,
      endDate: _displayEnd,
    );
    final weekData = <String, List<WeekClientInfo>>{
      for (final day in _displayDays)
        _calendarService.dayKeyFor(day): <WeekClientInfo>[],
    };

    for (final preload in clientPreloads) {
      final client = preload.client;
      if (client.isActive == false) continue;

      // Hafta için açık bir period yoksa dersi gösterme
      final hasOpenPeriod = preload.periods.any((period) {
        final start = DateTime.parse(period.startDate);
        final end = _periodService.effectiveEnd(period);
        return !start.isAfter(_displayEnd) && !end.isBefore(_displayStart);
      });
      if (!hasOpenPeriod) continue;

      final schedules = preload.schedules;
      final attendanceRecords = preload.weeklyAttendance;
      final handledLessonDays = <String>{};

      for (final attendance in attendanceRecords) {
        final lessonDate = attendance.lessonDate;
        if (_attendanceService.isWithinRange(
          lessonDate,
          start: _displayStart,
          end: _displayEnd,
        )) {
          handledLessonDays.add(_dayKeyFor(lessonDate!));
        }

        for (final week in [_currentWeek, _nextWeek]) {
          final resolvedEntry = _attendanceService.resolveWeeklyPlacement(
            attendance: attendance,
            week: week,
            schedules: schedules,
          );
          if (resolvedEntry == null) continue;

          final dayKey = _dayKeyFor(resolvedEntry.showDate);
          weekData[dayKey]?.add(
            WeekClientInfo(
              client: client,
              time: resolvedEntry.showTime,
              isMakeup: resolvedEntry.isMakeup,
              source: resolvedEntry.isMakeup
                  ? WeekEntrySource.makeup
                  : WeekEntrySource.attendance,
              status: resolvedEntry.status,
            ),
          );
        }
      }

      for (final schedule in schedules) {
        for (final lessonDate in _lessonDatesForSchedule(schedule)) {
          // O ders günü için açık bir period yoksa listeye ekleme
          final hasCoveringPeriod = preload.periods.any((period) {
            final start = DateTime.parse(period.startDate);
            final end = _periodService.effectiveEnd(period);
            return !start.isAfter(lessonDate) && !end.isBefore(lessonDate);
          });
          if (!hasCoveringPeriod) continue;

          final lessonDayKey = _dayKeyFor(lessonDate);
          if (handledLessonDays.contains(lessonDayKey)) continue;

          weekData[lessonDayKey]?.add(
            WeekClientInfo(
              client: client,
              time: schedule.time,
              isMakeup: false,
              source: WeekEntrySource.schedule,
              status: LessonAttendanceStatus.pending,
            ),
          );
        }
      }
    }

    for (final entries in weekData.values) {
      entries.sort((left, right) => left.time.compareTo(right.time));
    }

    if (!mounted) return;
    setState(() {
      _weekData = weekData;
      _isLoading = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToTodayCard(animated: false);
      _updateVisibleWeekFromScroll();
    });
  }

  void _handleWeekScroll() {
    _updateVisibleWeekFromScroll();
  }

  void _updateVisibleWeekFromScroll() {
    if (!_weekScrollController.hasClients) return;

    double nextWeekStartOffset = 0;
    for (int i = 0; i < _currentWeek.days.length; i++) {
      final day = _displayDays[i];
      final clients = _weekData[_dayKeyFor(day)] ?? const <WeekClientInfo>[];
      nextWeekStartOffset += _cardWidthFor(clients) + 8;
    }

    final shouldShowNextWeek =
        _weekScrollController.offset >= (nextWeekStartOffset - 40);
    if (shouldShowNextWeek == _isNextWeekInView) return;
    if (!mounted) return;
    setState(() {
      _isNextWeekInView = shouldShowNextWeek;
    });
  }

  void _scrollToTodayCard({required bool animated}) {
    if (!_weekScrollController.hasClients) return;

    final today = DateTime.now();
    final todayIndex = _displayDays.indexWhere(
      (day) =>
          day.year == today.year &&
          day.month == today.month &&
          day.day == today.day,
    );
    if (todayIndex < 0) return;

    double offset = 0;
    for (int i = 0; i < todayIndex; i++) {
      final day = _displayDays[i];
      final clients = _weekData[_dayKeyFor(day)] ?? const <WeekClientInfo>[];
      offset += _cardWidthFor(clients) + 8;
    }

    final maxExtent = _weekScrollController.position.maxScrollExtent;
    final target = offset.clamp(0.0, maxExtent).toDouble();

    if (animated) {
      _weekScrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    _weekScrollController.jumpTo(target);
  }

  DateTime get _displayStart => _currentWeek.start;

  DateTime get _displayEnd => _nextWeek.end;

  List<DateTime> get _displayDays => [..._currentWeek.days, ..._nextWeek.days];

  List<DateTime> _lessonDatesForSchedule(SessionSchedule schedule) {
    final currentWeekDate = _calendarService.lessonDateForSchedule(
      schedule,
      _currentWeek,
    );
    final nextWeekDate = _calendarService.lessonDateForSchedule(
      schedule,
      _nextWeek,
    );
    return [
      if (currentWeekDate != null) currentWeekDate,
      if (nextWeekDate != null) nextWeekDate,
    ];
  }

  String _dayKeyFor(DateTime date) {
    return _calendarService.dayKeyFor(date);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF00BCD4).withValues(alpha: 0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00897B).withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 12),
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            SingleChildScrollView(
              controller: _weekScrollController,
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final day in _displayDays) _buildDayCard(context, day),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Row(
      children: [
        const Icon(
          Icons.date_range_rounded,
          color: Color(0xFF00897B),
          size: 22,
        ),
        const SizedBox(width: 8),
        Text(
          _isNextWeekInView ? l.nextWeek : l.thisWeek,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Color(0xFF00897B),
          ),
        ),
      ],
    );
  }

  Widget _buildDayCard(BuildContext context, DateTime day) {
    final today = DateTime.now();
    final isToday =
        day.year == today.year &&
        day.month == today.month &&
        day.day == today.day;
    final clients = _weekData[_dayKeyFor(day)] ?? const <WeekClientInfo>[];

    return Container(
      width: _cardWidthFor(clients),
      margin: const EdgeInsets.only(right: 8),
      constraints: const BoxConstraints(minHeight: 136),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isToday
            ? const Color(0xFF00897B).withValues(alpha: 0.08)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: isToday
            ? Border.all(color: const Color(0xFF00897B), width: 1.5)
            : Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${TrainerWeekday.fromDate(day)?.localized(context) ?? ''} ${day.day.toString().padLeft(2, '0')}/${day.month.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isToday ? const Color(0xFF00897B) : Colors.grey[700],
              ),
            ),
          ),
          const Divider(height: 12, thickness: 0.5),
          if (clients.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  '-',
                  style: TextStyle(color: Colors.grey[400], fontSize: 13),
                ),
              ),
            )
          else
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: clients.map(_buildClientText).toList(),
            ),
        ],
      ),
    );
  }

  double _cardWidthFor(List<WeekClientInfo> clients) {
    if (clients.isEmpty) return 156;

    final longestLabelLength = clients
        .map((info) => '${info.time} ${info.client.fullName}'.length)
        .fold<int>(
          0,
          (maxLength, length) => length > maxLength ? length : maxLength,
        );

    if (clients.length >= 5 || longestLabelLength >= 24) {
      return 224;
    }
    if (clients.length >= 3 || longestLabelLength >= 18) {
      return 204;
    }
    return 186;
  }

  Widget _buildClientText(WeekClientInfo info) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Text(
            info.time,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              info.client.fullName,
              style: TextStyle(
                fontSize: 13,
                color: _textColorFor(info),
                fontWeight: _fontWeightFor(info),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Color _textColorFor(WeekClientInfo info) {
    switch (info.status) {
      case LessonAttendanceStatus.cancelled:
        return Colors.red[700]!;
      case LessonAttendanceStatus.absent:
        return Colors.red[700]!;
      case LessonAttendanceStatus.attended:
        return Colors.green[700]!;
      case LessonAttendanceStatus.pending:
        return info.isMakeup ? Colors.orange[700]! : Colors.grey[800]!;
    }
  }

  FontWeight _fontWeightFor(WeekClientInfo info) {
    if (info.status == LessonAttendanceStatus.pending) {
      return info.isMakeup ? FontWeight.w600 : FontWeight.w500;
    }
    return FontWeight.w700;
  }
}
