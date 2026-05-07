import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/attendance_record.dart';
import '../models/client.dart';
import '../models/lesson_reason.dart';
import '../models/period.dart';
import '../models/program_type.dart';
import '../models/session_schedule.dart';
import '../models/trainer_weekday.dart';
import '../models/user.dart';
import '../models/screen_preload.dart';
import '../services/attendance_actions_service.dart';
import '../services/attendance_service.dart';
import '../services/calendar_service.dart';
import '../services/database.dart';
import '../services/error_logger.dart';
import '../services/period_service.dart';
import '../services/premium_service.dart';
import '../services/screen_preload_service.dart';
import '../widgets/app_background.dart';
import 'premium_page.dart';
import 'client_detail_page.dart';

class MonthlyAttendancePage extends StatefulWidget {
  const MonthlyAttendancePage({super.key, required this.currentUser});

  final User currentUser;

  @override
  State<MonthlyAttendancePage> createState() => _MonthlyAttendancePageState();
}

class _MonthlyAttendancePageState extends State<MonthlyAttendancePage> {
  static const _initialPage = 1200;

  final _db = AppDatabase();
  final _attendanceActionsService = AttendanceActionsService();
  final _attendanceService = AttendanceService();
  final _calendarService = CalendarService();
  final _periodService = PeriodService();
  final _screenPreloadService = ScreenPreloadService();

  late final DateTime _baseMonth;
  late final PageController _pageController;

  final Map<String, _MonthlyCalendarData> _monthCache = {};
  final Set<String> _loadingMonthKeys = <String>{};

  bool _showPassiveClients = false;
  int _currentPage = _initialPage;
  bool _countryInitialized = false;
  _HolidayCountry _selectedCountry = _HolidayCountry.turkey;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _baseMonth = DateTime(now.year, now.month, 1);
    _pageController = PageController(initialPage: _initialPage);
    _loadMonth(_monthForPage(_currentPage));
    _loadMonth(_monthForPage(_currentPage + 1));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_countryInitialized) return;
    final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
    _selectedCountry = _HolidayCountryX.fromLocale(
      deviceLocale.countryCode?.isNotEmpty == true
          ? deviceLocale
          : Localizations.localeOf(context),
    );
    _countryInitialized = true;
  }

  Future<void> _showLegendInfo() async {
    if (!mounted) return;

    final l = AppLocalizations.of(context);

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l.monthlyAttendanceLegendTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LegendRow(
                  icon: Icons.check_circle_rounded,
                  color: Colors.green,
                  text: l.monthlyAttendanceLegendAttended,
                ),
                const SizedBox(height: 10),
                _LegendRow(
                  icon: Icons.highlight_off_rounded,
                  color: Colors.red,
                  text: l.monthlyAttendanceLegendAbsent,
                ),
                const SizedBox(height: 10),
                _LegendRow(
                  icon: Icons.schedule_rounded,
                  color: const Color(0xFF1E88E5),
                  text: l.monthlyAttendanceLegendPending,
                ),
                const SizedBox(height: 10),
                _LegendRow(
                  icon: Icons.event_repeat_rounded,
                  color: const Color(0xFFFB8C00),
                  text: l.monthlyAttendanceLegendMakeup,
                ),
                const SizedBox(height: 10),
                _LegendRow(
                  icon: Icons.cancel_rounded,
                  color: const Color(0xFFC8A415),
                  text: l.monthlyAttendanceLegendCancelled,
                ),
                const SizedBox(height: 10),
                _LegendRow(
                  icon: Icons.celebration_rounded,
                  color: const Color(0xFFEF6C00),
                  text: l.reasonResmiTatil,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l.ok),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  DateTime get _visibleMonth => _monthForPage(_currentPage);

  DateTime _monthForPage(int page) {
    final offset = page - _initialPage;
    return DateTime(_baseMonth.year, _baseMonth.month + offset, 1);
  }

  String _monthKey(DateTime month) {
    return '${month.year}-${month.month.toString().padLeft(2, '0')}';
  }

  DateTime _monthStart(DateTime month) => DateTime(month.year, month.month, 1);

  DateTime _monthEnd(DateTime month) =>
      DateTime(month.year, month.month + 1, 0, 23, 59, 59, 999);

  Future<void> _loadMonth(DateTime month) async {
    final key = _monthKey(month);
    if (_monthCache.containsKey(key) || _loadingMonthKeys.contains(key)) return;

    final userId = widget.currentUser.id;
    if (userId == null) return;

    _loadingMonthKeys.add(key);
    if (mounted) {
      setState(() {});
    }

    try {
      final preloads = await _screenPreloadService.loadWeeklyClientPreloads(
        userId: userId,
        startDate: _monthStart(month),
        endDate: _monthEnd(month),
      );

      final entriesByDay = _buildEntriesByDay(preloads: preloads, month: month);

      if (!mounted) return;
      setState(() {
        _monthCache[key] = _MonthlyCalendarData(entriesByDay: entriesByDay);
        _loadingMonthKeys.remove(key);
      });
    } catch (e, stack) {
      ErrorLogger().logError(
        error: e.toString(),
        stackTrace: stack.toString(),
        extra: '_MonthlyAttendancePageState._loadMonth',
      );
      if (!mounted) return;
      setState(() {
        _loadingMonthKeys.remove(key);
      });
    }
  }

  Map<String, List<_MonthlyAttendanceEntry>> _buildEntriesByDay({
    required List<WeeklyClientPreload> preloads,
    required DateTime month,
  }) {
    final start = _monthStart(month);
    final end = _monthEnd(month);
    final entriesByDay = <String, List<_MonthlyAttendanceEntry>>{
      for (
        var day = start;
        !day.isAfter(DateTime(month.year, month.month + 1, 0));
        day = day.add(const Duration(days: 1))
      )
        _calendarService.dayKeyFor(day): <_MonthlyAttendanceEntry>[],
    };

    for (final preload in preloads) {
      final client = preload.client;
      if (!_showPassiveClients && client.isActive == false) continue;

      final handledLessonDays = <String>{};
      final lessonWeekdays = preload.schedules
          .map((schedule) => TrainerWeekday.fromStorageKey(schedule.dayOfWeek))
          .whereType<TrainerWeekday>()
          .map((day) => day.weekdayNumber)
          .toSet();
      final periodEndsById = <int, DateTime>{
        for (final period in preload.periods)
          if (period.id != null)
            period.id!: DateTime(
              _periodService.effectiveEnd(period).year,
              _periodService.effectiveEnd(period).month,
              _periodService.effectiveEnd(period).day,
            ),
      };
      final periodPaidById = <int, bool>{
        for (final period in preload.periods)
          if (period.id != null) period.id!: period.isPaid,
      };

      for (final attendance in preload.weeklyAttendance) {
        final lessonDate = attendance.lessonDate;
        if (_attendanceService.isWithinRange(
          lessonDate,
          start: start,
          end: end,
        )) {
          handledLessonDays.add(_calendarService.dayKeyFor(lessonDate!));
        }

        final placement = _resolveMonthlyPlacement(
          attendance: attendance,
          start: start,
          end: end,
          schedules: preload.schedules,
        );
        if (placement == null) continue;

        entriesByDay[_calendarService.dayKeyFor(placement.showDate)]?.add(
          _MonthlyAttendanceEntry(
            client: client,
            time: placement.showTime,
            status: placement.status,
            isMakeup: placement.isMakeup,
            source: placement.isMakeup
                ? _MonthlyEntrySource.makeup
                : _MonthlyEntrySource.attendance,
            lessonDate: attendance.lessonDate ?? placement.showDate,
            periodId: attendance.periodId,
            attendanceRecord: attendance,
            lessonWeekdays: lessonWeekdays,
            isPeriodLastDay: _isPeriodLastDay(
              lessonDate: attendance.lessonDate ?? placement.showDate,
              periodId: attendance.periodId,
              periodEndsById: periodEndsById,
            ),
            isPeriodPaid: _isPeriodPaid(
              periodId: attendance.periodId,
              periodPaidById: periodPaidById,
            ),
          ),
        );
      }

      for (final schedule in preload.schedules) {
        for (final lessonDate in _scheduleDatesForMonth(
          schedule: schedule,
          start: start,
          end: end,
        )) {
          if (handledLessonDays.contains(
            _calendarService.dayKeyFor(lessonDate),
          )) {
            continue;
          }

          final coveringPeriod = _coveringPeriodForDay(
            preload.periods,
            lessonDate,
          );
          if (coveringPeriod == null) continue;

          entriesByDay[_calendarService.dayKeyFor(lessonDate)]?.add(
            _MonthlyAttendanceEntry(
              client: client,
              time: schedule.time,
              status: LessonAttendanceStatus.pending,
              isMakeup: false,
              source: _MonthlyEntrySource.schedule,
              lessonDate: lessonDate,
              periodId: coveringPeriod.id,
              attendanceRecord: null,
              lessonWeekdays: lessonWeekdays,
              isPeriodLastDay: _isPeriodLastDay(
                lessonDate: lessonDate,
                periodId: coveringPeriod.id,
                periodEndsById: periodEndsById,
              ),
              isPeriodPaid: _isPeriodPaid(
                periodId: coveringPeriod.id,
                periodPaidById: periodPaidById,
              ),
            ),
          );
        }
      }
    }

    for (final entries in entriesByDay.values) {
      entries.sort((left, right) {
        final timeCompare = left.time.compareTo(right.time);
        if (timeCompare != 0) return timeCompare;
        return left.client.fullName.compareTo(right.client.fullName);
      });
    }

    return entriesByDay;
  }

  AttendancePlacement? _resolveMonthlyPlacement({
    required AttendanceRecord attendance,
    required DateTime start,
    required DateTime end,
    required List<SessionSchedule> schedules,
  }) {
    final status = _attendanceService.resolveAttendanceStatus(attendance);

    if (!attendance.cancelled &&
        _attendanceService.isWithinRange(
          attendance.makeupDate,
          start: start,
          end: end,
        )) {
      final makeupDate = attendance.makeupDate!;
      return AttendancePlacement(
        showDate: makeupDate,
        showTime:
            '${makeupDate.hour.toString().padLeft(2, '0')}:${makeupDate.minute.toString().padLeft(2, '0')}',
        isMakeup: true,
        status: status,
      );
    }

    final lessonDate = attendance.lessonDate;
    if (!_attendanceService.isWithinRange(lessonDate, start: start, end: end)) {
      return null;
    }

    return AttendancePlacement(
      showDate: lessonDate!,
      showTime: _attendanceService.resolveScheduledTime(
        schedules: schedules,
        lessonDate: lessonDate,
      ),
      isMakeup: false,
      status: status,
    );
  }

  Iterable<DateTime> _scheduleDatesForMonth({
    required SessionSchedule schedule,
    required DateTime start,
    required DateTime end,
  }) sync* {
    final weekday = TrainerWeekday.fromStorageKey(
      schedule.dayOfWeek,
    )?.weekdayNumber;
    if (weekday == null) return;

    for (
      var day = start;
      !day.isAfter(end);
      day = day.add(const Duration(days: 1))
    ) {
      if (day.weekday == weekday) {
        yield day;
      }
    }
  }

  bool _periodCoversDay(Period period, DateTime day) {
    final start = DateTime.parse(period.startDate);
    final end = _periodService.effectiveEnd(period);
    return !start.isAfter(day) && !end.isBefore(day);
  }

  Period? _coveringPeriodForDay(List<Period> periods, DateTime day) {
    Period? match;
    for (final period in periods) {
      if (!_periodCoversDay(period, day)) continue;
      if (match == null) {
        match = period;
        continue;
      }
      final currentStart = DateTime.parse(match.startDate);
      final candidateStart = DateTime.parse(period.startDate);
      if (candidateStart.isAfter(currentStart)) {
        match = period;
      }
    }
    return match;
  }

  bool _isPeriodLastDay({
    required DateTime lessonDate,
    required int? periodId,
    required Map<int, DateTime> periodEndsById,
  }) {
    if (periodId == null) return false;
    final endDay = periodEndsById[periodId];
    if (endDay == null) return false;
    return _dateOnly(lessonDate) == endDay;
  }

  bool _isPeriodPaid({
    required int? periodId,
    required Map<int, bool> periodPaidById,
  }) {
    if (periodId == null) return true;
    return periodPaidById[periodId] ?? true;
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  String _dayKeyFor(DateTime date) => _calendarService.dayKeyFor(date);

  String _formatDateForDialog(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }

  String _formatDayLabel(DateTime day, BuildContext context) {
    final weekdayLabel = TrainerWeekday.fromDate(day)?.localized(context) ?? '';
    final dayText = day.day.toString().padLeft(2, '0');
    final monthText = day.month.toString().padLeft(2, '0');
    return '$weekdayLabel $dayText/$monthText';
  }

  List<LessonReason> _reasonOptionsForClient(Client client) {
    if (client.programType == ProgramType.personal) {
      return const [
        LessonReason.resmiTatil,
        LessonReason.hastalik,
        LessonReason.other,
      ];
    }

    return const [
      LessonReason.resmiTatil,
      LessonReason.sporcuHasta,
      LessonReason.trainerHasta,
      LessonReason.sporcuKisisel,
      LessonReason.trainerKisisel,
      LessonReason.other,
    ];
  }

  Future<_ReasonSelection?> _pickReasonDialog(Client client) async {
    final l = AppLocalizations.of(context);
    return showDialog<_ReasonSelection>(
      context: context,
      builder: (context) {
        return _ReasonPickerDialog(
          l: l,
          reasonOptions: _reasonOptionsForClient(client),
        );
      },
    );
  }

  Future<bool> _confirmPastPeriodUpdateIfNeeded(
    _MonthlyAttendanceEntry entry,
  ) async {
    final clientId = entry.client.id;
    final currentPeriodId = entry.periodId;
    if (clientId == null || currentPeriodId == null) return false;

    final hasLaterPeriod = await _attendanceActionsService
        .requiresPastPeriodConfirmation(
          clientId: clientId,
          currentPeriodId: currentPeriodId,
        );

    if (!hasLaterPeriod || !mounted) return true;

    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l.pastPeriodUpdateConfirmTitle),
          content: Text(
            l.pastPeriodUpdateConfirmBody(
              _formatDateForDialog(entry.lessonDate),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.yes),
            ),
          ],
        );
      },
    );

    return confirmed == true;
  }

  Future<bool> _toggleAttendanceForEntry(_MonthlyAttendanceEntry entry) async {
    final clientId = entry.client.id;
    final periodId = entry.periodId;
    final attendance = entry.attendanceRecord;
    if (clientId == null || periodId == null) return false;
    if (!await _confirmPastPeriodUpdateIfNeeded(entry)) return false;
    if (attendance != null && attendance.cancelled) return false;

    await _attendanceActionsService.toggleAttendance(
      clientId: clientId,
      periodId: periodId,
      lessonDate: entry.lessonDate,
      existingAttendance: attendance,
    );
    return true;
  }

  Future<bool> _setMakeupForEntry(_MonthlyAttendanceEntry entry) async {
    final clientId = entry.client.id;
    final periodId = entry.periodId;
    final attendance = entry.attendanceRecord;
    if (clientId == null || periodId == null) return false;
    if (!await _confirmPastPeriodUpdateIfNeeded(entry)) return false;
    if (attendance != null && attendance.cancelled) return false;

    final period = await _db.getPeriodById(periodId);
    if (period == null || !mounted) return false;

    final periodStart = DateTime.parse(period.startDate);
    final periodEnd = _periodService.effectiveEnd(period);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final normalizedPeriodStart = DateTime(
      periodStart.year,
      periodStart.month,
      periodStart.day,
    );

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: entry.lessonDate,
      firstDate: today.isBefore(normalizedPeriodStart)
          ? today
          : normalizedPeriodStart,
      lastDate: periodEnd.add(const Duration(days: 60)),
      selectableDayPredicate: (candidate) {
        final normalizedCandidate = DateTime(
          candidate.year,
          candidate.month,
          candidate.day,
        );
        if (normalizedCandidate == today) return true;
        return !normalizedCandidate.isBefore(normalizedPeriodStart);
      },
    );
    if (pickedDate == null || !mounted) return false;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: attendance?.makeupDate?.hour ?? 12,
        minute: attendance?.makeupDate?.minute ?? 0,
      ),
    );
    if (pickedTime == null || !mounted) return false;

    final selection = await _pickReasonDialog(entry.client);
    if (selection == null) return false;

    await _attendanceActionsService.setMakeup(
      clientId: clientId,
      periodId: periodId,
      lessonDate: entry.lessonDate,
      makeupDateTime: DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      ),
      reason: selection.reason.index,
      reasonNote: selection.note,
    );
    return true;
  }

  Future<bool> _cancelLessonForEntry(_MonthlyAttendanceEntry entry) async {
    final clientId = entry.client.id;
    final periodId = entry.periodId;
    final attendance = entry.attendanceRecord;
    if (clientId == null || periodId == null) return false;
    if (!await _confirmPastPeriodUpdateIfNeeded(entry)) return false;

    if (attendance != null && attendance.cancelled) {
      return _unCancelLessonForEntry(entry);
    }

    final selection = await _pickReasonDialog(entry.client);
    if (selection == null || !mounted) return false;

    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l.cancelLesson),
          content: Text(
            l.cancelLessonBody(_formatDateForDialog(entry.lessonDate)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.giveUp),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC8A415),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.confirmCancel),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return false;

    final addToEnd = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l.addLessonToPeriodEndTitle),
          content: Text(l.addLessonToPeriodEndBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.no),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00897B),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.yes),
            ),
          ],
        );
      },
    );

    await _attendanceActionsService.cancelLesson(
      clientId: clientId,
      periodId: periodId,
      lessonDate: entry.lessonDate,
      addToEnd: addToEnd == true,
      reason: selection.reason.index,
      reasonNote: selection.note,
      lessonWeekdays: entry.lessonWeekdays,
    );
    return true;
  }

  Future<bool> _unCancelLessonForEntry(_MonthlyAttendanceEntry entry) async {
    final clientId = entry.client.id;
    final periodId = entry.periodId;
    if (clientId == null || periodId == null || !mounted) return false;

    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l.undoCancel),
          content: Text(
            l.undoCancelBody(_formatDateForDialog(entry.lessonDate)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.giveUp),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.confirmUndo),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return false;

    await _attendanceActionsService.undoCancelledLesson(
      clientId: clientId,
      periodId: periodId,
      lessonDate: entry.lessonDate,
      lessonWeekdays: entry.lessonWeekdays,
    );
    return true;
  }

  Future<bool> _resetEntry(_MonthlyAttendanceEntry entry) async {
    final clientId = entry.client.id;
    final periodId = entry.periodId;
    final attendance = entry.attendanceRecord;
    if (clientId == null ||
        periodId == null ||
        attendance == null ||
        !mounted) {
      return false;
    }
    if (!await _confirmPastPeriodUpdateIfNeeded(entry)) return false;

    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l.resetAction),
          content: Text(
            l.resetActionBody(_formatDateForDialog(entry.lessonDate)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l.giveUp),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: Text(l.resetActionConfirm),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return false;

    await _attendanceActionsService.resetAttendance(
      clientId: clientId,
      periodId: periodId,
      lessonDate: entry.lessonDate,
      existingAttendance: attendance,
      lessonWeekdays: entry.lessonWeekdays,
    );

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.actionReset)));
    }

    return true;
  }

  Future<void> _reloadVisibleMonthData() async {
    final previousMonth = _monthForPage(_currentPage - 1);
    final currentMonth = _visibleMonth;
    final nextMonth = _monthForPage(_currentPage + 1);
    if (!mounted) return;
    setState(() {
      _monthCache.remove(_monthKey(previousMonth));
      _monthCache.remove(_monthKey(currentMonth));
      _monthCache.remove(_monthKey(nextMonth));
    });
    await _loadMonth(previousMonth);
    await _loadMonth(currentMonth);
    await _loadMonth(nextMonth);
  }

  Future<void> _openDayDetails(DateTime day) async {
    final l = AppLocalizations.of(context);
    final monthData = _monthCache[_monthKey(_visibleMonth)];
    final dayKey = _dayKeyFor(day);
    var entries =
        monthData?.entriesByDay[dayKey] ?? const <_MonthlyAttendanceEntry>[];
    final holidays = _HolidayService.holidaysForDay(
      country: _selectedCountry,
      day: day,
    );

    if (entries.isEmpty && holidays.isEmpty) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> refreshDayEntries() async {
              await _reloadVisibleMonthData();
              if (!mounted) return;
              setSheetState(() {
                entries =
                    _monthCache[_monthKey(_visibleMonth)]
                        ?.entriesByDay[dayKey] ??
                    const <_MonthlyAttendanceEntry>[];
              });
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDayLabel(day, context),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      MaterialLocalizations.of(context).formatFullDate(day),
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    if (holidays.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        l.monthlyAttendanceHolidaySection,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: holidays
                            .map(
                              (holiday) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3E0),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  holiday.name,
                                  style: const TextStyle(
                                    color: Color(0xFFEF6C00),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 12),
                    if (entries.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          l.monthlyAttendanceNoEntries,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    else
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: entries.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final entry = entries[index];
                            final attendance = entry.attendanceRecord;
                            final isCancelled =
                                attendance?.cancelled == true ||
                                entry.status ==
                                    LessonAttendanceStatus.cancelled;
                            final isAttended =
                                entry.status == LessonAttendanceStatus.attended;
                            final canReset = attendance != null;
                            final canRunActions = entry.periodId != null;

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: _MonthlyStatusBadge(
                                color: _statusColor(entry.status),
                                icon: _entryIconData(entry),
                              ),
                              title: Text(entry.client.fullName),
                              subtitle: _buildEntrySubtitle(entry, l),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    entry.time,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  IconButton(
                                    tooltip: l.monthlyAttendanceOpenClient,
                                    icon: const Icon(
                                      Icons.person_outline_rounded,
                                    ),
                                    onPressed: () async {
                                      await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => ClientDetailPage(
                                            client: entry.client,
                                          ),
                                        ),
                                      );
                                      await refreshDayEntries();
                                    },
                                  ),
                                  PopupMenuButton<_MonthlyEntryAction>(
                                    tooltip: l.settings,
                                    icon: const Icon(Icons.more_vert),
                                    onSelected:
                                        (_MonthlyEntryAction action) async {
                                          switch (action) {
                                            case _MonthlyEntryAction
                                                .toggleAttendance:
                                              if (!canRunActions || isCancelled)
                                                return;
                                              if (!await _toggleAttendanceForEntry(
                                                entry,
                                              )) {
                                                return;
                                              }
                                              await refreshDayEntries();
                                              return;
                                            case _MonthlyEntryAction.setMakeup:
                                              if (!canRunActions || isCancelled)
                                                return;
                                              if (!await _setMakeupForEntry(
                                                entry,
                                              )) {
                                                return;
                                              }
                                              await refreshDayEntries();
                                              return;
                                            case _MonthlyEntryAction
                                                .cancelOrUndo:
                                              if (!canRunActions) return;
                                              if (!await _cancelLessonForEntry(
                                                entry,
                                              )) {
                                                return;
                                              }
                                              await refreshDayEntries();
                                              return;
                                            case _MonthlyEntryAction.reset:
                                              if (!canRunActions || !canReset)
                                                return;
                                              if (!await _resetEntry(entry)) {
                                                return;
                                              }
                                              await refreshDayEntries();
                                              return;
                                          }
                                        },
                                    itemBuilder: (context) => [
                                      PopupMenuItem<_MonthlyEntryAction>(
                                        value: _MonthlyEntryAction
                                            .toggleAttendance,
                                        enabled: canRunActions && !isCancelled,
                                        child: Text(
                                          isAttended
                                              ? l.resetAction
                                              : l.markAttendanceDone,
                                        ),
                                      ),
                                      PopupMenuItem<_MonthlyEntryAction>(
                                        value: _MonthlyEntryAction.setMakeup,
                                        enabled: canRunActions && !isCancelled,
                                        child: Text(l.selectMakeupDate),
                                      ),
                                      PopupMenuItem<_MonthlyEntryAction>(
                                        value: _MonthlyEntryAction.cancelOrUndo,
                                        enabled: canRunActions,
                                        child: Text(
                                          isCancelled
                                              ? l.undoCancelTooltip
                                              : l.cancelAndPostpone,
                                        ),
                                      ),
                                      PopupMenuItem<_MonthlyEntryAction>(
                                        value: _MonthlyEntryAction.reset,
                                        enabled: canRunActions && canReset,
                                        child: Text(l.resetAction),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget? _buildEntrySubtitle(
    _MonthlyAttendanceEntry entry,
    AppLocalizations l,
  ) {
    final labels = <String>[];
    if (entry.isMakeup) {
      labels.add(l.makeup);
    } else if (entry.status == LessonAttendanceStatus.cancelled) {
      labels.add(l.cancelled);
    } else if (entry.status == LessonAttendanceStatus.pending) {
      labels.add(l.monthlyAttendanceLegendPending);
    }
    if (!entry.isPeriodPaid) {
      labels.add('!');
    }
    if (entry.isPeriodLastDay) {
      labels.add('*');
    }
    if (labels.isEmpty) return null;
    return Text(labels.join('  •  '));
  }

  IconData _entryIconData(_MonthlyAttendanceEntry entry) {
    if (entry.isMakeup) return Icons.event_repeat_rounded;
    switch (entry.status) {
      case LessonAttendanceStatus.attended:
        return Icons.check_circle_rounded;
      case LessonAttendanceStatus.absent:
        return Icons.highlight_off_rounded;
      case LessonAttendanceStatus.cancelled:
        return Icons.cancel_rounded;
      case LessonAttendanceStatus.pending:
        return Icons.schedule_rounded;
    }
  }

  Future<void> _goToPage(int page) async {
    await _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  Color _statusColor(LessonAttendanceStatus status) {
    switch (status) {
      case LessonAttendanceStatus.attended:
        return Colors.green;
      case LessonAttendanceStatus.absent:
        return Colors.red;
      case LessonAttendanceStatus.cancelled:
        return const Color(0xFFC8A415);
      case LessonAttendanceStatus.pending:
        return const Color(0xFF1E88E5);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final visibleMonth = _visibleMonth;
    if (!PremiumService().canAccessWeeklyPlan) {
      return const PremiumPage();
    }

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF00BCD4).withValues(alpha: 0.12),
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
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          l.monthlyAttendance,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 380;

                  final monthSwitcher = Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => _goToPage(_currentPage - 1),
                          icon: const Icon(Icons.chevron_left_rounded),
                        ),
                        Expanded(
                          child: Center(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 260),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              transitionBuilder: (child, animation) {
                                final offsetAnimation = Tween<Offset>(
                                  begin: const Offset(0, 0.18),
                                  end: Offset.zero,
                                ).animate(animation);

                                return FadeTransition(
                                  opacity: animation,
                                  child: SlideTransition(
                                    position: offsetAnimation,
                                    child: child,
                                  ),
                                );
                              },
                              child: Text(
                                MaterialLocalizations.of(
                                  context,
                                ).formatMonthYear(visibleMonth),
                                key: ValueKey(_monthKey(visibleMonth)),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: isCompact ? 15 : 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _goToPage(_currentPage + 1),
                          icon: const Icon(Icons.chevron_right_rounded),
                        ),
                      ],
                    ),
                  );

                  final headerRow = Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    child: Row(
                      children: [
                        Expanded(child: monthSwitcher),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.info_outline),
                          color: const Color(0xFF00897B),
                          tooltip: l.monthlyAttendanceLegendTooltip,
                          onPressed: _showLegendInfo,
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                  );

                  final controls = Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: isCompact
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              DropdownButtonFormField<_HolidayCountry>(
                                value: _selectedCountry,
                                decoration: InputDecoration(
                                  labelText: l.monthlyAttendanceCountryLabel,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  isDense: true,
                                ),
                                items: _HolidayCountry.values
                                    .map(
                                      (country) =>
                                          DropdownMenuItem<_HolidayCountry>(
                                            value: country,
                                            child: Text(
                                              country.code,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                    )
                                    .toList(),
                                onChanged: (country) {
                                  if (country == null) return;
                                  setState(() {
                                    _selectedCountry = country;
                                  });
                                },
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.88),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey[200]!),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(child: Text(l.showPassiveClients)),
                                    Switch(
                                      value: _showPassiveClients,
                                      onChanged: (value) {
                                        setState(() {
                                          _showPassiveClients = value;
                                          _monthCache.clear();
                                        });
                                        _loadMonth(_visibleMonth);
                                        _loadMonth(
                                          _monthForPage(_currentPage + 1),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : Wrap(
                            spacing: 12,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              SizedBox(
                                width: 108,
                                child: DropdownButtonFormField<_HolidayCountry>(
                                  value: _selectedCountry,
                                  decoration: InputDecoration(
                                    labelText: l.monthlyAttendanceCountryLabel,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    isDense: true,
                                  ),
                                  items: _HolidayCountry.values
                                      .map(
                                        (country) =>
                                            DropdownMenuItem<_HolidayCountry>(
                                              value: country,
                                              child: Text(
                                                country.code,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                      )
                                      .toList(),
                                  onChanged: (country) {
                                    if (country == null) return;
                                    setState(() {
                                      _selectedCountry = country;
                                    });
                                  },
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(l.showPassiveClients),
                                  Switch(
                                    value: _showPassiveClients,
                                    onChanged: (value) {
                                      setState(() {
                                        _showPassiveClients = value;
                                        _monthCache.clear();
                                      });
                                      _loadMonth(_visibleMonth);
                                      _loadMonth(
                                        _monthForPage(_currentPage + 1),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                  );

                  return Column(children: [headerRow, controls]);
                },
              ),
              const SizedBox(height: 12),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (page) {
                    setState(() {
                      _currentPage = page;
                    });
                    _loadMonth(_monthForPage(page));
                    _loadMonth(_monthForPage(page + 1));
                  },
                  itemBuilder: (context, page) {
                    final month = _monthForPage(page);
                    final key = _monthKey(month);
                    final data = _monthCache[key];
                    final isLoading = _loadingMonthKeys.contains(key);
                    final holidaysByDay = _HolidayService.holidaysByDay(
                      country: _selectedCountry,
                      month: month,
                    );

                    if (data == null && !isLoading) {
                      _loadMonth(month);
                    }

                    return isLoading && data == null
                        ? const Center(child: CircularProgressIndicator())
                        : TweenAnimationBuilder<double>(
                            key: ValueKey('month-view-$key'),
                            tween: Tween<double>(begin: 0, end: 1),
                            duration: const Duration(milliseconds: 240),
                            curve: Curves.easeOutCubic,
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, (1 - value) * 18),
                                  child: child,
                                ),
                              );
                            },
                            child: _MonthlyCalendarView(
                              month: month,
                              data:
                                  data ??
                                  const _MonthlyCalendarData(entriesByDay: {}),
                              holidaysByDay: holidaysByDay,
                              onDayTap: _openDayDetails,
                              statusColor: _statusColor,
                            ),
                          );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthlyCalendarView extends StatelessWidget {
  const _MonthlyCalendarView({
    required this.month,
    required this.data,
    required this.holidaysByDay,
    required this.onDayTap,
    required this.statusColor,
  });

  final DateTime month;
  final _MonthlyCalendarData data;
  final Map<String, List<_Holiday>> holidaysByDay;
  final Future<void> Function(DateTime day) onDayTap;
  final Color Function(LessonAttendanceStatus status) statusColor;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final monthDays = DateTime(month.year, month.month + 1, 0).day;
    final leadingEmptyCount = (month.weekday + 6) % 7;
    final totalItems = leadingEmptyCount + monthDays;
    final weekdayLabels = _weekdayHeaders(context);
    final today = DateTime.now();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 420;
        final calendarWidth = constraints.maxWidth < 820
            ? 820.0
            : constraints.maxWidth;
        final visibleEntries = isCompact ? 1 : 2;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: calendarWidth,
              child: Column(
                children: [
                  Row(
                    children: [
                      for (final label in weekdayLabels)
                        Expanded(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      mainAxisExtent: isCompact ? 152 : 178,
                    ),
                    itemCount: totalItems,
                    itemBuilder: (context, index) {
                      if (index < leadingEmptyCount) {
                        return const SizedBox.shrink();
                      }

                      final dayNumber = index - leadingEmptyCount + 1;
                      final day = DateTime(month.year, month.month, dayNumber);
                      final key = DateTime(
                        day.year,
                        day.month,
                        day.day,
                      ).toIso8601String();
                      final entries =
                          data.entriesByDay[key] ??
                          const <_MonthlyAttendanceEntry>[];
                      final holidays = holidaysByDay[key] ?? const <_Holiday>[];
                      final isToday =
                          day.year == today.year &&
                          day.month == today.month &&
                          day.day == today.day;
                      final hasContent =
                          entries.isNotEmpty || holidays.isNotEmpty;
                      final summary = _DayCellSummary.from(entries, holidays);

                      return Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: hasContent ? () => onDayTap(day) : null,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _surfaceColorFor(summary, isToday),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isToday
                                    ? const Color(0xFF00897B)
                                    : Colors.grey[200]!,
                                width: isToday ? 1.5 : 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '$dayNumber',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: isToday
                                            ? const Color(0xFF00897B)
                                            : Colors.black87,
                                      ),
                                    ),
                                    const Spacer(),
                                    if (holidays.isNotEmpty)
                                      const Icon(
                                        Icons.celebration_rounded,
                                        size: 14,
                                        color: Color(0xFFEF6C00),
                                      ),
                                    if (entries.isNotEmpty) ...[
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(
                                            alpha: 0.06,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Text(
                                          '${entries.length}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                if (holidays.isNotEmpty)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF3E0),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      holidays.first.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFFEF6C00),
                                      ),
                                    ),
                                  ),
                                if (holidays.isEmpty) const SizedBox(height: 4),
                                const SizedBox(height: 10),
                                Expanded(
                                  child: entries.isEmpty
                                      ? const SizedBox.shrink()
                                      : Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            for (final entry in entries.take(
                                              visibleEntries,
                                            ))
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 4,
                                                ),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Icon(
                                                      _iconFor(entry),
                                                      size: 12,
                                                      color: statusColor(
                                                        entry.status,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(
                                                        '${entry.time} ${entry.client.fullName}',
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight:
                                                              entry.isMakeup
                                                              ? FontWeight.w600
                                                              : FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            const Spacer(),
                                            Wrap(
                                              spacing: 4,
                                              runSpacing: 4,
                                              children: [
                                                if (summary.attendedCount > 0)
                                                  _MiniCountBadge(
                                                    icon: Icons
                                                        .check_circle_rounded,
                                                    color: Colors.green,
                                                    count:
                                                        summary.attendedCount,
                                                    label: l
                                                        .monthlyAttendanceLegendAttended,
                                                  ),
                                                if (summary.pendingCount > 0)
                                                  _MiniCountBadge(
                                                    icon:
                                                        Icons.schedule_rounded,
                                                    color: const Color(
                                                      0xFF1E88E5,
                                                    ),
                                                    count: summary.pendingCount,
                                                    label: l
                                                        .monthlyAttendanceLegendPending,
                                                  ),
                                                if (summary.makeupCount > 0)
                                                  _MiniCountBadge(
                                                    icon: Icons
                                                        .event_repeat_rounded,
                                                    color: const Color(
                                                      0xFFFB8C00,
                                                    ),
                                                    count: summary.makeupCount,
                                                    label: l
                                                        .monthlyAttendanceLegendMakeup,
                                                  ),
                                                if (summary.absentCount > 0)
                                                  _MiniCountBadge(
                                                    icon: Icons
                                                        .highlight_off_rounded,
                                                    color: Colors.red,
                                                    count: summary.absentCount,
                                                    label: l
                                                        .monthlyAttendanceLegendAbsent,
                                                  ),
                                                if (summary.cancelledCount > 0)
                                                  _MiniCountBadge(
                                                    icon: Icons.cancel_rounded,
                                                    color: const Color(
                                                      0xFFC8A415,
                                                    ),
                                                    count:
                                                        summary.cancelledCount,
                                                    label: l
                                                        .monthlyAttendanceLegendCancelled,
                                                  ),
                                                if (entries.length >
                                                    visibleEntries)
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.black
                                                          .withValues(
                                                            alpha: 0.05,
                                                          ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            999,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      '+${entries.length - visibleEntries}',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: Colors.grey[700],
                                                      ),
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
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<String> _weekdayHeaders(BuildContext context) {
    final labels = MaterialLocalizations.of(context).narrowWeekdays;
    return [
      labels[1],
      labels[2],
      labels[3],
      labels[4],
      labels[5],
      labels[6],
      labels[0],
    ];
  }

  Color _surfaceColorFor(_DayCellSummary summary, bool isToday) {
    if (isToday) {
      return const Color(0xFF00897B).withValues(alpha: 0.07);
    }
    if (summary.holidayCount > 0) return const Color(0xFFFFF8E1);
    if (summary.cancelledCount > 0) {
      return const Color(0xFFFFF4E5);
    }
    if (summary.makeupCount > 0) {
      return const Color(0xFFFFF7ED);
    }
    if (summary.attendedCount > 0) {
      return const Color(0xFFF1FBF6);
    }
    if (summary.pendingCount > 0) {
      return const Color(0xFFF3F8FF);
    }
    if (summary.absentCount > 0) {
      return const Color(0xFFFFF2F2);
    }
    return Colors.white;
  }

  IconData _iconFor(_MonthlyAttendanceEntry entry) {
    if (entry.isMakeup) return Icons.event_repeat_rounded;
    switch (entry.status) {
      case LessonAttendanceStatus.attended:
        return Icons.check_circle_rounded;
      case LessonAttendanceStatus.absent:
        return Icons.highlight_off_rounded;
      case LessonAttendanceStatus.cancelled:
        return Icons.cancel_rounded;
      case LessonAttendanceStatus.pending:
        return Icons.schedule_rounded;
    }
  }
}

class _MonthlyCalendarData {
  const _MonthlyCalendarData({required this.entriesByDay});

  final Map<String, List<_MonthlyAttendanceEntry>> entriesByDay;
}

class _MonthlyAttendanceEntry {
  const _MonthlyAttendanceEntry({
    required this.client,
    required this.time,
    required this.status,
    required this.isMakeup,
    required this.source,
    required this.lessonDate,
    required this.periodId,
    required this.attendanceRecord,
    required this.lessonWeekdays,
    required this.isPeriodLastDay,
    required this.isPeriodPaid,
  });

  final Client client;
  final String time;
  final LessonAttendanceStatus status;
  final bool isMakeup;
  final _MonthlyEntrySource source;
  final DateTime lessonDate;
  final int? periodId;
  final AttendanceRecord? attendanceRecord;
  final Set<int> lessonWeekdays;
  final bool isPeriodLastDay;
  final bool isPeriodPaid;
}

enum _MonthlyEntrySource { attendance, makeup, schedule }

enum _MonthlyEntryAction { toggleAttendance, setMakeup, cancelOrUndo, reset }

enum _HolidayCountry { turkey, unitedStates, spain, netherlands }

extension _HolidayCountryX on _HolidayCountry {
  static _HolidayCountry fromLocale(Locale locale) {
    switch (locale.countryCode?.toUpperCase()) {
      case 'TR':
        return _HolidayCountry.turkey;
      case 'US':
        return _HolidayCountry.unitedStates;
      case 'ES':
        return _HolidayCountry.spain;
      case 'NL':
        return _HolidayCountry.netherlands;
    }

    switch (locale.languageCode) {
      case 'es':
        return _HolidayCountry.spain;
      case 'nl':
        return _HolidayCountry.netherlands;
      case 'en':
        return _HolidayCountry.unitedStates;
      default:
        return _HolidayCountry.turkey;
    }
  }

  String get code {
    switch (this) {
      case _HolidayCountry.turkey:
        return 'TR';
      case _HolidayCountry.unitedStates:
        return 'US';
      case _HolidayCountry.spain:
        return 'ES';
      case _HolidayCountry.netherlands:
        return 'NL';
    }
  }
}

class _Holiday {
  const _Holiday({required this.date, required this.name});

  final DateTime date;
  final String name;
}

class _HolidayService {
  static Map<String, List<_Holiday>> holidaysByDay({
    required _HolidayCountry country,
    required DateTime month,
  }) {
    final holidays = _holidaysForYear(
      country,
      month.year,
    ).where((holiday) => holiday.date.month == month.month).toList();
    final grouped = <String, List<_Holiday>>{};
    for (final holiday in holidays) {
      final key = DateTime(
        holiday.date.year,
        holiday.date.month,
        holiday.date.day,
      ).toIso8601String();
      grouped.putIfAbsent(key, () => <_Holiday>[]).add(holiday);
    }
    return grouped;
  }

  static List<_Holiday> holidaysForDay({
    required _HolidayCountry country,
    required DateTime day,
  }) {
    return _holidaysForYear(country, day.year)
        .where(
          (holiday) =>
              holiday.date.year == day.year &&
              holiday.date.month == day.month &&
              holiday.date.day == day.day,
        )
        .toList();
  }

  static List<_Holiday> _holidaysForYear(_HolidayCountry country, int year) {
    switch (country) {
      case _HolidayCountry.turkey:
        return _turkeyHolidays(year);
      case _HolidayCountry.unitedStates:
        return _usHolidays(year);
      case _HolidayCountry.spain:
        return _spainHolidays(year);
      case _HolidayCountry.netherlands:
        return _netherlandsHolidays(year);
    }
  }

  static List<_Holiday> _turkeyHolidays(int year) {
    return [
      _fixedHoliday(year, 1, 1, 'New Year'),
      _fixedHoliday(year, 4, 23, 'National Sovereignty and Children\'s Day'),
      _fixedHoliday(year, 5, 1, 'Labour and Solidarity Day'),
      _fixedHoliday(
        year,
        5,
        19,
        'Commemoration of Ataturk, Youth and Sports Day',
      ),
      ..._turkeyReligiousHolidays(year),
      _fixedHoliday(year, 7, 15, 'Democracy and National Unity Day'),
      _fixedHoliday(year, 8, 30, 'Victory Day'),
      _fixedHoliday(year, 10, 28, 'Republic Day Eve'),
      _fixedHoliday(year, 10, 29, 'Republic Day'),
    ];
  }

  static List<_Holiday> _turkeyReligiousHolidays(int year) {
    final dates = _TurkeyReligiousHolidayDates.forYear(year);
    if (dates == null) return const <_Holiday>[];

    return [
      _holiday(dates.ramadanEve, 'Ramazan Bayrami Arifesi'),
      ..._holidayRange(dates.ramadanStart, 3, 'Ramazan Bayrami'),
      _holiday(dates.kurbanEve, 'Kurban Bayrami Arifesi'),
      ..._holidayRange(dates.kurbanStart, 4, 'Kurban Bayrami'),
    ];
  }

  static List<_Holiday> _holidayRange(
    DateTime start,
    int dayCount,
    String baseName,
  ) {
    return List<_Holiday>.generate(dayCount, (index) {
      return _holiday(
        start.add(Duration(days: index)),
        '$baseName ${index + 1}. Gun',
      );
    });
  }

  static List<_Holiday> _usHolidays(int year) {
    return [
      _fixedHoliday(year, 1, 1, 'New Year\'s Day'),
      _nthWeekdayHoliday(
        year,
        1,
        DateTime.monday,
        3,
        'Martin Luther King Jr. Day',
      ),
      _nthWeekdayHoliday(year, 2, DateTime.monday, 3, 'Presidents\' Day'),
      _lastWeekdayHoliday(year, 5, DateTime.monday, 'Memorial Day'),
      _fixedHoliday(year, 6, 19, 'Juneteenth'),
      _fixedHoliday(year, 7, 4, 'Independence Day'),
      _nthWeekdayHoliday(year, 9, DateTime.monday, 1, 'Labor Day'),
      _nthWeekdayHoliday(year, 10, DateTime.monday, 2, 'Columbus Day'),
      _fixedHoliday(year, 11, 11, 'Veterans Day'),
      _nthWeekdayHoliday(year, 11, DateTime.thursday, 4, 'Thanksgiving'),
      _fixedHoliday(year, 12, 25, 'Christmas Day'),
    ];
  }

  static List<_Holiday> _spainHolidays(int year) {
    final easter = _easterSunday(year);
    return [
      _fixedHoliday(year, 1, 1, 'Ano Nuevo'),
      _fixedHoliday(year, 1, 6, 'Epifania del Senor'),
      _holiday(easter.subtract(const Duration(days: 2)), 'Viernes Santo'),
      _fixedHoliday(year, 5, 1, 'Fiesta del Trabajo'),
      _fixedHoliday(year, 8, 15, 'Asuncion de la Virgen'),
      _fixedHoliday(year, 10, 12, 'Fiesta Nacional de Espana'),
      _fixedHoliday(year, 11, 1, 'Todos los Santos'),
      _fixedHoliday(year, 12, 6, 'Dia de la Constitucion'),
      _fixedHoliday(year, 12, 8, 'Inmaculada Concepcion'),
      _fixedHoliday(year, 12, 25, 'Navidad'),
    ];
  }

  static List<_Holiday> _netherlandsHolidays(int year) {
    final easter = _easterSunday(year);
    return [
      _fixedHoliday(year, 1, 1, 'Nieuwjaarsdag'),
      _holiday(easter.subtract(const Duration(days: 2)), 'Goede Vrijdag'),
      _holiday(easter.add(const Duration(days: 1)), 'Tweede Paasdag'),
      _fixedHoliday(year, 4, 27, 'Koningsdag'),
      _fixedHoliday(year, 5, 5, 'Bevrijdingsdag'),
      _holiday(easter.add(const Duration(days: 39)), 'Hemelvaartsdag'),
      _holiday(easter.add(const Duration(days: 50)), 'Tweede Pinksterdag'),
      _fixedHoliday(year, 12, 25, 'Eerste Kerstdag'),
      _fixedHoliday(year, 12, 26, 'Tweede Kerstdag'),
    ];
  }

  static _Holiday _fixedHoliday(int year, int month, int day, String name) {
    return _Holiday(date: DateTime(year, month, day), name: name);
  }

  static _Holiday _holiday(DateTime date, String name) {
    return _Holiday(
      date: DateTime(date.year, date.month, date.day),
      name: name,
    );
  }

  static _Holiday _nthWeekdayHoliday(
    int year,
    int month,
    int weekday,
    int occurrence,
    String name,
  ) {
    final firstDay = DateTime(year, month, 1);
    final offset = (weekday - firstDay.weekday + 7) % 7;
    final day = 1 + offset + ((occurrence - 1) * 7);
    return _Holiday(date: DateTime(year, month, day), name: name);
  }

  static _Holiday _lastWeekdayHoliday(
    int year,
    int month,
    int weekday,
    String name,
  ) {
    final lastDay = DateTime(year, month + 1, 0);
    final offset = (lastDay.weekday - weekday + 7) % 7;
    return _Holiday(
      date: DateTime(year, month, lastDay.day - offset),
      name: name,
    );
  }

  static DateTime _easterSunday(int year) {
    final a = year % 19;
    final b = year ~/ 100;
    final c = year % 100;
    final d = b ~/ 4;
    final e = b % 4;
    final f = (b + 8) ~/ 25;
    final g = (b - f + 1) ~/ 3;
    final h = (19 * a + b - d - g + 15) % 30;
    final i = c ~/ 4;
    final k = c % 4;
    final l = (32 + 2 * e + 2 * i - h - k) % 7;
    final m = (a + 11 * h + 22 * l) ~/ 451;
    final month = (h + l - 7 * m + 114) ~/ 31;
    final day = ((h + l - 7 * m + 114) % 31) + 1;
    return DateTime(year, month, day);
  }
}

class _DayCellSummary {
  const _DayCellSummary({
    required this.holidayCount,
    required this.pendingCount,
    required this.attendedCount,
    required this.absentCount,
    required this.cancelledCount,
    required this.makeupCount,
  });

  factory _DayCellSummary.from(
    List<_MonthlyAttendanceEntry> entries,
    List<_Holiday> holidays,
  ) {
    var pendingCount = 0;
    var attendedCount = 0;
    var absentCount = 0;
    var cancelledCount = 0;
    var makeupCount = 0;

    for (final entry in entries) {
      if (entry.isMakeup) {
        makeupCount++;
      }
      switch (entry.status) {
        case LessonAttendanceStatus.pending:
          pendingCount++;
        case LessonAttendanceStatus.attended:
          attendedCount++;
        case LessonAttendanceStatus.absent:
          absentCount++;
        case LessonAttendanceStatus.cancelled:
          cancelledCount++;
      }
    }

    return _DayCellSummary(
      holidayCount: holidays.length,
      pendingCount: pendingCount,
      attendedCount: attendedCount,
      absentCount: absentCount,
      cancelledCount: cancelledCount,
      makeupCount: makeupCount,
    );
  }

  final int holidayCount;
  final int pendingCount;
  final int attendedCount;
  final int absentCount;
  final int cancelledCount;
  final int makeupCount;
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    );
  }
}

class _MiniCountBadge extends StatelessWidget {
  const _MiniCountBadge({
    required this.icon,
    required this.color,
    required this.count,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 3),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyStatusBadge extends StatelessWidget {
  const _MonthlyStatusBadge({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}

class _TurkeyReligiousHolidayDates {
  const _TurkeyReligiousHolidayDates({
    required this.ramadanEve,
    required this.ramadanStart,
    required this.kurbanEve,
    required this.kurbanStart,
  });

  final DateTime ramadanEve;
  final DateTime ramadanStart;
  final DateTime kurbanEve;
  final DateTime kurbanStart;

  static _TurkeyReligiousHolidayDates? forYear(int year) {
    switch (year) {
      case 2024:
        return _TurkeyReligiousHolidayDates(
          ramadanEve: DateTime(2024, 4, 9),
          ramadanStart: DateTime(2024, 4, 10),
          kurbanEve: DateTime(2024, 6, 15),
          kurbanStart: DateTime(2024, 6, 16),
        );
      case 2025:
        return _TurkeyReligiousHolidayDates(
          ramadanEve: DateTime(2025, 3, 29),
          ramadanStart: DateTime(2025, 3, 30),
          kurbanEve: DateTime(2025, 6, 5),
          kurbanStart: DateTime(2025, 6, 6),
        );
      case 2026:
        return _TurkeyReligiousHolidayDates(
          ramadanEve: DateTime(2026, 3, 19),
          ramadanStart: DateTime(2026, 3, 20),
          kurbanEve: DateTime(2026, 5, 26),
          kurbanStart: DateTime(2026, 5, 27),
        );
      case 2027:
        return _TurkeyReligiousHolidayDates(
          ramadanEve: DateTime(2027, 3, 9),
          ramadanStart: DateTime(2027, 3, 10),
          kurbanEve: DateTime(2027, 5, 16),
          kurbanStart: DateTime(2027, 5, 17),
        );
      case 2028:
        return _TurkeyReligiousHolidayDates(
          ramadanEve: DateTime(2028, 2, 26),
          ramadanStart: DateTime(2028, 2, 27),
          kurbanEve: DateTime(2028, 5, 4),
          kurbanStart: DateTime(2028, 5, 5),
        );
      case 2029:
        return _TurkeyReligiousHolidayDates(
          ramadanEve: DateTime(2029, 2, 13),
          ramadanStart: DateTime(2029, 2, 14),
          kurbanEve: DateTime(2029, 4, 23),
          kurbanStart: DateTime(2029, 4, 24),
        );
      case 2030:
        return _TurkeyReligiousHolidayDates(
          ramadanEve: DateTime(2030, 2, 3),
          ramadanStart: DateTime(2030, 2, 4),
          kurbanEve: DateTime(2030, 4, 13),
          kurbanStart: DateTime(2030, 4, 14),
        );
      default:
        return null;
    }
  }
}

class _ReasonSelection {
  const _ReasonSelection({required this.reason, this.note});

  final LessonReason reason;
  final String? note;
}

class _ReasonPickerDialog extends StatefulWidget {
  const _ReasonPickerDialog({required this.l, required this.reasonOptions});

  final AppLocalizations l;
  final List<LessonReason> reasonOptions;

  @override
  State<_ReasonPickerDialog> createState() => _ReasonPickerDialogState();
}

class _ReasonPickerDialogState extends State<_ReasonPickerDialog> {
  late final TextEditingController reasonNoteController;
  late LessonReason selected;

  @override
  void initState() {
    super.initState();
    reasonNoteController = TextEditingController();
    selected = widget.reasonOptions.first;
  }

  @override
  void dispose() {
    reasonNoteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.l.selectReason),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...widget.reasonOptions.map((reason) {
              return RadioListTile<LessonReason>(
                title: Text(widget.l.lessonReasonLabel(reason)),
                value: reason,
                // ignore: deprecated_member_use
                groupValue: selected,
                // ignore: deprecated_member_use
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => selected = value);
                },
                visualDensity: VisualDensity.compact,
                selected: selected == reason,
              );
            }),
            const SizedBox(height: 8),
            TextField(
              controller: reasonNoteController,
              minLines: 3,
              maxLines: 6,
              maxLength: 4000,
              inputFormatters: [LengthLimitingTextInputFormatter(4000)],
              decoration: InputDecoration(
                labelText: widget.l.reasonNoteLabel,
                hintText: widget.l.reasonNoteHint,
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: Text(widget.l.cancel),
        ),
        ElevatedButton(
          onPressed: () {
            final note = reasonNoteController.text.trim();
            Navigator.pop(
              context,
              _ReasonSelection(
                reason: selected,
                note: note.isEmpty ? null : note,
              ),
            );
          },
          child: Text(widget.l.save),
        ),
      ],
    );
  }
}
