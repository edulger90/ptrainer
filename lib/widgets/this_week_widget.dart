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
import '../models/week_range.dart';
import '../models/user.dart';
import '../services/attendance_service.dart';
import '../services/attendance_actions_service.dart';
import '../services/calendar_service.dart';
import '../services/database.dart';
import '../services/period_service.dart';
import '../services/screen_preload_service.dart';

class WeekClientInfo {
  final Client client;
  final String time;
  final bool isMakeup;
  final WeekEntrySource source;
  final LessonAttendanceStatus status;
  final DateTime lessonDate;
  final int? periodId;
  final bool hasAttendanceRecord;
  final AttendanceRecord? attendanceRecord;
  final Set<int> lessonWeekdays;

  const WeekClientInfo({
    required this.client,
    required this.time,
    required this.isMakeup,
    required this.source,
    required this.status,
    required this.lessonDate,
    required this.periodId,
    required this.hasAttendanceRecord,
    required this.attendanceRecord,
    required this.lessonWeekdays,
  });

  WeekClientInfo copyWith({
    LessonAttendanceStatus? status,
    bool? hasAttendanceRecord,
    AttendanceRecord? attendanceRecord,
    bool clearAttendanceRecord = false,
  }) {
    return WeekClientInfo(
      client: client,
      time: time,
      isMakeup: isMakeup,
      source: source,
      status: status ?? this.status,
      lessonDate: lessonDate,
      periodId: periodId,
      hasAttendanceRecord: hasAttendanceRecord ?? this.hasAttendanceRecord,
      attendanceRecord: clearAttendanceRecord
          ? null
          : (attendanceRecord ?? this.attendanceRecord),
      lessonWeekdays: lessonWeekdays,
    );
  }
}

enum WeekEntrySource { attendance, makeup, schedule }

enum _DayEntryAction { toggleAttendance, setMakeup, cancelOrUndo, reset }

class ThisWeekWidget extends StatefulWidget {
  final User currentUser;

  const ThisWeekWidget({super.key, required this.currentUser});

  @override
  State<ThisWeekWidget> createState() => _ThisWeekWidgetState();
}

class _ThisWeekWidgetState extends State<ThisWeekWidget>
    with WidgetsBindingObserver {
  final _attendanceService = AttendanceService();
  final _attendanceActionsService = AttendanceActionsService();
  final _calendarService = CalendarService();
  final _periodService = PeriodService();
  final _screenPreloadService = ScreenPreloadService();
  final _db = AppDatabase();
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

  Future<void> _loadWeekData({bool recenterToday = true}) async {
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
      final lessonWeekdays = schedules
          .map((s) => TrainerWeekday.fromStorageKey(s.dayOfWeek)?.weekdayNumber)
          .whereType<int>()
          .toSet();

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
              lessonDate: attendance.lessonDate ?? resolvedEntry.showDate,
              periodId: attendance.periodId,
              hasAttendanceRecord: true,
              attendanceRecord: attendance,
              lessonWeekdays: lessonWeekdays,
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
              lessonDate: lessonDate,
              periodId: _findPeriodIdForDay(preload.periods, lessonDate),
              hasAttendanceRecord: false,
              attendanceRecord: null,
              lessonWeekdays: lessonWeekdays,
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

    if (recenterToday) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToTodayCard(animated: false);
        _updateVisibleWeekFromScroll();
      });
    }
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

  int? _findPeriodIdForDay(List<Period> periods, DateTime lessonDate) {
    for (final period in periods) {
      final periodId = period.id;
      if (periodId == null) continue;
      final start = DateTime.parse(period.startDate);
      final end = _periodService.effectiveEnd(period);
      if (!start.isAfter(lessonDate) && !end.isBefore(lessonDate)) {
        return periodId;
      }
    }
    return null;
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
    ];
  }

  Future<_ReasonSelection?> _pickReasonDialog(Client client) async {
    final l = AppLocalizations.of(context);
    final reasonOptions = _reasonOptionsForClient(client);

    return showDialog<_ReasonSelection>(
      context: context,
      builder: (context) {
        return _ReasonPickerDialog(l: l, reasonOptions: reasonOptions);
      },
    );
  }

  Future<bool> _confirmPastPeriodUpdateIfNeeded(WeekClientInfo info) async {
    final clientId = info.client.id;
    final currentPeriodId = info.periodId;
    if (clientId == null || currentPeriodId == null) return false;

    final hasLaterPeriod = await _attendanceActionsService
        .requiresPastPeriodConfirmation(
          clientId: clientId,
          currentPeriodId: currentPeriodId,
        );

    if (!hasLaterPeriod) return true;
    if (!mounted) return false;

    final l = AppLocalizations.of(context);
    final dateStr =
        '${info.lessonDate.day.toString().padLeft(2, '0')}.${info.lessonDate.month.toString().padLeft(2, '0')}.${info.lessonDate.year}';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l.pastPeriodUpdateConfirmTitle),
          content: Text(l.pastPeriodUpdateConfirmBody(dateStr)),
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

  Future<bool> _toggleAttendanceForEntry(WeekClientInfo info) async {
    final clientId = info.client.id;
    final periodId = info.periodId;
    if (clientId == null || periodId == null) return false;
    if (!await _confirmPastPeriodUpdateIfNeeded(info)) return false;

    final att = info.attendanceRecord;
    if (att != null && att.cancelled) {
      return false;
    }

    await _attendanceActionsService.toggleAttendance(
      clientId: clientId,
      periodId: periodId,
      lessonDate: info.lessonDate,
      existingAttendance: att,
    );

    return true;
  }

  Future<bool> _setMakeupForEntry(WeekClientInfo info) async {
    final clientId = info.client.id;
    final periodId = info.periodId;
    if (clientId == null || periodId == null) return false;
    if (!await _confirmPastPeriodUpdateIfNeeded(info)) return false;

    final att = info.attendanceRecord;
    if (att != null && att.cancelled) return false;

    final period = await _db.getPeriodById(periodId);
    if (period == null || !mounted) return false;

    final periodStart = DateTime.parse(period.startDate);
    final periodEnd = _periodService.effectiveEnd(period);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: info.lessonDate,
      firstDate: periodStart,
      lastDate: periodEnd.add(const Duration(days: 60)),
    );
    if (pickedDate == null || !mounted) return false;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime == null || !mounted) return false;

    final selection = await _pickReasonDialog(info.client);
    if (selection == null) return false;

    final makeupDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    await _attendanceActionsService.setMakeup(
      clientId: clientId,
      periodId: periodId,
      lessonDate: info.lessonDate,
      makeupDateTime: makeupDateTime,
      reason: selection.reason.index,
      reasonNote: selection.note,
    );

    return true;
  }

  Future<bool> _cancelLessonForEntry(WeekClientInfo info) async {
    final clientId = info.client.id;
    final periodId = info.periodId;
    if (clientId == null || periodId == null) return false;
    if (!await _confirmPastPeriodUpdateIfNeeded(info)) return false;

    final att = info.attendanceRecord;
    if (att != null && att.cancelled) {
      return _unCancelLessonForEntry(info);
    }

    final selection = await _pickReasonDialog(info.client);
    if (selection == null || !mounted) return false;

    final l = AppLocalizations.of(context);
    final dateStr =
        '${info.lessonDate.day.toString().padLeft(2, '0')}.${info.lessonDate.month.toString().padLeft(2, '0')}.${info.lessonDate.year}';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l.cancelLesson),
          content: Text(l.cancelLessonBody(dateStr)),
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
      lessonDate: info.lessonDate,
      addToEnd: addToEnd == true,
      reason: selection.reason.index,
      reasonNote: selection.note,
      lessonWeekdays: info.lessonWeekdays,
    );

    return true;
  }

  Future<bool> _unCancelLessonForEntry(WeekClientInfo info) async {
    final clientId = info.client.id;
    final periodId = info.periodId;
    if (clientId == null || periodId == null || !mounted) return false;

    final l = AppLocalizations.of(context);
    final dateStr =
        '${info.lessonDate.day.toString().padLeft(2, '0')}.${info.lessonDate.month.toString().padLeft(2, '0')}.${info.lessonDate.year}';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l.undoCancel),
          content: Text(l.undoCancelBody(dateStr)),
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
      lessonDate: info.lessonDate,
      lessonWeekdays: info.lessonWeekdays,
    );

    return true;
  }

  Future<bool> _resetEntry(WeekClientInfo info) async {
    final clientId = info.client.id;
    final periodId = info.periodId;
    final att = info.attendanceRecord;
    if (clientId == null || periodId == null || att == null || !mounted) {
      return false;
    }
    if (!await _confirmPastPeriodUpdateIfNeeded(info)) return false;

    final l = AppLocalizations.of(context);
    final dateStr =
        '${info.lessonDate.day.toString().padLeft(2, '0')}.${info.lessonDate.month.toString().padLeft(2, '0')}.${info.lessonDate.year}';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l.resetAction),
          content: Text(l.resetActionBody(dateStr)),
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
      lessonDate: info.lessonDate,
      existingAttendance: att,
      lessonWeekdays: info.lessonWeekdays,
    );

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.actionReset)));
    }

    return true;
  }

  String _formatDayLabel(DateTime day, BuildContext context) {
    final weekdayLabel = TrainerWeekday.fromDate(day)?.localized(context) ?? '';
    final dayText = day.day.toString().padLeft(2, '0');
    final monthText = day.month.toString().padLeft(2, '0');
    return '$weekdayLabel $dayText/$monthText';
  }

  Future<void> _openDayAttendanceSheet(DateTime day) async {
    final l = AppLocalizations.of(context);
    final dayKey = _dayKeyFor(day);
    final dayEntries = _weekData[dayKey] ?? const <WeekClientInfo>[];
    if (dayEntries.isEmpty || !mounted) return;

    var localEntries = List<WeekClientInfo>.from(dayEntries);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 16,
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDayLabel(day, sheetContext),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l.weeklyAttendanceListTitle,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: localEntries.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final entry = localEntries[index];
                          final currentAttendance = entry.attendanceRecord;
                          final isCancelled =
                              currentAttendance?.cancelled == true ||
                              entry.status == LessonAttendanceStatus.cancelled;
                          final isAttended =
                              entry.status == LessonAttendanceStatus.attended;
                          final canReset = currentAttendance != null;

                          Future<void> refreshDayEntries() async {
                            await _loadWeekData(recenterToday: false);
                            if (!mounted) return;
                            setSheetState(() {
                              localEntries = List<WeekClientInfo>.from(
                                _weekData[dayKey] ?? const <WeekClientInfo>[],
                              );
                            });
                          }

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Text(
                              entry.time,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            title: Text(
                              entry.client.fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: isCancelled ? Text(l.cancelled) : null,
                            trailing: PopupMenuButton<_DayEntryAction>(
                              tooltip: l.settings,
                              icon: const Icon(Icons.more_vert),
                              onSelected: (_DayEntryAction action) async {
                                switch (action) {
                                  case _DayEntryAction.toggleAttendance:
                                    if (isCancelled) return;
                                    final changed =
                                        await _toggleAttendanceForEntry(entry);
                                    if (!changed) return;
                                    await refreshDayEntries();
                                    return;
                                  case _DayEntryAction.setMakeup:
                                    if (isCancelled) return;
                                    final changed = await _setMakeupForEntry(
                                      entry,
                                    );
                                    if (!changed) return;
                                    await refreshDayEntries();
                                    return;
                                  case _DayEntryAction.cancelOrUndo:
                                    final changed = await _cancelLessonForEntry(
                                      entry,
                                    );
                                    if (!changed) return;
                                    await refreshDayEntries();
                                    return;
                                  case _DayEntryAction.reset:
                                    if (!canReset) return;
                                    final changed = await _resetEntry(entry);
                                    if (!changed) return;
                                    await refreshDayEntries();
                                    return;
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem<_DayEntryAction>(
                                  value: _DayEntryAction.toggleAttendance,
                                  enabled: !isCancelled,
                                  child: Text(
                                    isAttended
                                        ? l.resetAction
                                        : l.markAttendanceDone,
                                  ),
                                ),
                                PopupMenuItem<_DayEntryAction>(
                                  value: _DayEntryAction.setMakeup,
                                  enabled: !isCancelled,
                                  child: Text(l.selectMakeupDate),
                                ),
                                PopupMenuItem<_DayEntryAction>(
                                  value: _DayEntryAction.cancelOrUndo,
                                  child: Text(
                                    isCancelled
                                        ? l.undoCancelTooltip
                                        : l.cancelAndPostpone,
                                  ),
                                ),
                                PopupMenuItem<_DayEntryAction>(
                                  value: _DayEntryAction.reset,
                                  enabled: canReset,
                                  child: Text(l.resetAction),
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

    return GestureDetector(
      onDoubleTap: clients.isEmpty ? null : () => _openDayAttendanceSheet(day),
      child: Container(
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

class _ReasonSelection {
  final LessonReason reason;
  final String? note;

  const _ReasonSelection({required this.reason, this.note});
}

class _ReasonPickerDialog extends StatefulWidget {
  final AppLocalizations l;
  final List<LessonReason> reasonOptions;

  const _ReasonPickerDialog({required this.l, required this.reasonOptions});

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
                onChanged: (val) {
                  if (val == null) return;
                  setState(() => selected = val);
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
