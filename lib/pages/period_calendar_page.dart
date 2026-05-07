import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/attendance_record.dart';
import '../models/period.dart';
import '../models/session_schedule.dart';
import '../models/client.dart';
import '../models/program_type.dart';
import '../models/trainer_weekday.dart';
import '../services/attendance_actions_service.dart';
import '../services/attendance_service.dart';
import '../services/error_logger.dart';
import '../services/screen_preload_service.dart';
import '../widgets/app_background.dart';
import '../l10n/app_localizations.dart';
import '../models/lesson_reason.dart';

class PeriodCalendarPage extends StatefulWidget {
  final Period period;
  final Client client;
  final List<SessionSchedule> schedules;
  final VoidCallback? onAttendanceChanged;
  const PeriodCalendarPage({
    super.key,
    required this.period,
    required this.client,
    required this.schedules,
    this.onAttendanceChanged,
  });

  @override
  State<PeriodCalendarPage> createState() => _PeriodCalendarPageState();
}

class _PeriodCalendarPageState extends State<PeriodCalendarPage> {
  final _attendanceService = AttendanceService();
  final _attendanceActionsService = AttendanceActionsService();
  late int _completedLessonCountCache;

  DateTime _normalizeDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  void _updateCompletedLessonCount() {
    final records = _attendance.entries.map(
      (entry) => _attendanceToRecord(entry.value, lessonDate: entry.key),
    );
    _completedLessonCountCache = _attendanceService.completedLessonCount(
      records,
    );
  }

  int _completedLessonCount() {
    return _completedLessonCountCache;
  }

  final _screenPreloadService = ScreenPreloadService();
  late Period _currentPeriod;
  late DateTime _start;
  late DateTime _end;
  late Set<int> _lessonWeekdays;
  Map<DateTime, _Attendance> _attendance = {};
  List<DateTime>? _cachedLessonDays;

  @override
  void initState() {
    super.initState();
    _currentPeriod = widget.period;
    _start = _normalizeDay(DateTime.parse(_currentPeriod.startDate));
    _end = _normalizeDay(
      DateTime.parse(_currentPeriod.postponedEndDate ?? _currentPeriod.endDate),
    );
    _lessonWeekdays = widget.schedules
        .map((s) => _weekdayNumber(s.dayOfWeek))
        .toSet();
    _completedLessonCountCache = 0;
    _reloadData();
  }

  Future<void> _reloadData() async {
    try {
      final clientId = widget.client.id;
      final periodId = _currentPeriod.id;
      if (clientId == null || periodId == null) {
        if (!mounted) return;
        setState(() {
          _attendance = {};
        });
        return;
      }

      final preload = await _screenPreloadService.loadPeriodCalendarPreload(
        clientId: clientId,
        periodId: periodId,
      );
      if (preload == null) return;

      if (!mounted) return;
      setState(() {
        _currentPeriod = preload.period;
        _start = _normalizeDay(DateTime.parse(preload.period.startDate));
        _end = _normalizeDay(
          DateTime.parse(
            preload.period.postponedEndDate ?? preload.period.endDate,
          ),
        );
        _cachedLessonDays = null;
        _attendance = {
          for (final record in preload.attendanceRecords)
            if (record.lessonDate != null)
              _normalizeDay(record.lessonDate!): _Attendance(
                absent: record.absent,
                cancelled: record.cancelled,
                isPostponed: record.isPostponed,
                makeup: record.makeupDate,
                attendedDate: record.attendedDate,
                reason: record.reason,
                reasonNote: record.reasonNote,
              ),
        };
        _updateCompletedLessonCount();
      });
    } catch (e, stack) {
      ErrorLogger().logError(
        error: e.toString(),
        stackTrace: stack.toString(),
        extra: '_PeriodCalendarPageState._reloadData',
      );
      if (!mounted) return;
      setState(() {
        _attendance = {};
      });
    }
  }

  int _weekdayNumber(String turkishDay) {
    return TrainerWeekday.fromStorageKey(turkishDay)?.weekdayNumber ??
        DateTime.monday;
  }

  String _localizedWeekday(int weekday) {
    if (!mounted) return '';
    final l = AppLocalizations.of(context);
    return l.dayOfWeekByIndex(weekday);
  }

  Future<bool> _confirmPastPeriodUpdateIfNeeded(DateTime day) async {
    final clientId = widget.client.id;
    final currentPeriodId = _currentPeriod.id;
    if (clientId == null || currentPeriodId == null) return true;

    final hasLaterPeriod = await _attendanceActionsService
        .requiresPastPeriodConfirmation(
          clientId: clientId,
          currentPeriodId: currentPeriodId,
        );

    if (!hasLaterPeriod) return true;
    if (!mounted) return false;

    final l = AppLocalizations.of(context);
    final dateStr =
        '${day.day.toString().padLeft(2, '0')}.${day.month.toString().padLeft(2, '0')}.${day.year}';

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

  List<DateTime> _getLessonDays() {
    if (_cachedLessonDays != null) return _cachedLessonDays!;
    final days = <DateTime>[];
    final effectiveEnd = DateTime.parse(
      _currentPeriod.postponedEndDate ?? _currentPeriod.endDate,
    );
    for (
      var d = _start;
      !d.isAfter(effectiveEnd);
      d = d.add(const Duration(days: 1))
    ) {
      if (_lessonWeekdays.contains(d.weekday)) {
        days.add(d);
      }
    }
    _cachedLessonDays = days;
    return days;
  }

  AttendanceRecord _attendanceToRecord(
    _Attendance att, {
    DateTime? lessonDate,
  }) {
    return AttendanceRecord(
      lessonDate: lessonDate,
      attended: !att.absent,
      cancelled: att.cancelled,
      isPostponed: att.isPostponed,
      attendedDate: att.attendedDate,
      makeupDate: att.makeup,
      reason: att.reason,
      reasonNote: att.reasonNote,
    );
  }

  bool _isEffectivelyAbsent(_Attendance? att) {
    if (att == null) return true;
    return !_attendanceService.isEffectivelyAttended(_attendanceToRecord(att));
  }

  List<LessonReason> _reasonOptionsForClient() {
    if (widget.client.programType == ProgramType.personal) {
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

  LessonReason? _reasonFromStoredIndex(int? index) {
    if (index == null) return null;
    if (index < 0 || index >= LessonReason.values.length) return null;
    return LessonReason.values[index];
  }

  String _buildReasonSubtitle(_Attendance att, AppLocalizations l) {
    final parts = <String>[];
    final reason = _reasonFromStoredIndex(att.reason);
    if (reason != null) {
      parts.add(l.lessonReasonLabel(reason));
    }
    final note = att.reasonNote?.trim();
    if (note != null && note.isNotEmpty) {
      parts.add(note);
    }
    return parts.join('\n');
  }

  void _toggleAttendance(DateTime day) async {
    final clientId = widget.client.id;
    final periodId = _currentPeriod.id;
    if (clientId == null || periodId == null) return;
    if (!await _confirmPastPeriodUpdateIfNeeded(day)) return;

    final att = _attendance[day];
    if (att != null && att.cancelled) {
      return;
    }

    await _attendanceActionsService.toggleAttendance(
      clientId: clientId,
      periodId: periodId,
      lessonDate: day,
      existingAttendance: att == null
          ? null
          : _attendanceToRecord(att, lessonDate: day),
    );

    await _reloadData();
    widget.onAttendanceChanged?.call();
  }

  Future<_ReasonSelection?> _pickReasonDialog() async {
    final l = AppLocalizations.of(context);
    final reasonOptions = _reasonOptionsForClient();

    return showDialog<_ReasonSelection>(
      context: context,
      builder: (context) {
        return _ReasonPickerDialog(l: l, reasonOptions: reasonOptions);
      },
    );
  }

  void _setMakeup(DateTime day) async {
    final clientId = widget.client.id;
    final periodId = _currentPeriod.id;
    if (clientId == null || periodId == null) return;
    if (!await _confirmPastPeriodUpdateIfNeeded(day)) return;
    if (!mounted) return;
    final today = _normalizeDay(DateTime.now());
    final periodStart = _normalizeDay(_start);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: day,
      firstDate: today.isBefore(periodStart) ? today : periodStart,
      lastDate: _end.add(const Duration(days: 60)),
      selectableDayPredicate: (candidate) {
        final normalizedCandidate = _normalizeDay(candidate);
        if (normalizedCandidate == today) return true;
        return !normalizedCandidate.isBefore(periodStart);
      },
    );
    if (pickedDate != null) {
      if (!mounted) return;
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (pickedTime == null) return;
      if (!mounted) return;
      final selection = await _pickReasonDialog();
      if (selection == null) return;
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
        lessonDate: day,
        makeupDateTime: makeupDateTime,
        reason: selection.reason.index,
        reasonNote: selection.note,
      );
      await _reloadData();
      widget.onAttendanceChanged?.call();
    }
  }

  Future<void> _showIconLegend() async {
    if (!mounted) return;

    final l = AppLocalizations.of(context);

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l.periodCalendarLegendTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LegendRow(
                  icon: Icons.check,
                  color: Colors.green,
                  text: l.periodCalendarLegendDone,
                ),
                const SizedBox(height: 10),
                _LegendRow(
                  icon: Icons.close,
                  color: Colors.red,
                  text: l.periodCalendarLegendAbsent,
                ),
                const SizedBox(height: 10),
                _LegendRow(
                  icon: Icons.event_available,
                  color: Colors.teal,
                  text: l.periodCalendarLegendMakeup,
                ),
                const SizedBox(height: 10),
                _LegendRow(
                  icon: Icons.event_busy,
                  color: Color(0xFFC8A415),
                  text: l.periodCalendarLegendCancel,
                ),
                const SizedBox(height: 10),
                _LegendRow(
                  icon: Icons.undo,
                  color: Colors.blue,
                  text: l.periodCalendarLegendUndo,
                ),
                const SizedBox(height: 10),
                _LegendRow(
                  icon: Icons.block,
                  color: Color(0xFFC8A415),
                  text: l.periodCalendarLegendBlocked,
                ),
                const SizedBox(height: 10),
                _LegendRow(
                  icon: Icons.add_circle,
                  color: Color(0xFFC8A415),
                  text: l.periodCalendarLegendPostponed,
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

  void _cancelLesson(DateTime day) async {
    final clientId = widget.client.id;
    final periodId = _currentPeriod.id;
    if (clientId == null || periodId == null) return;
    if (!await _confirmPastPeriodUpdateIfNeeded(day)) return;

    final att = _attendance[day];
    if (att != null && att.cancelled) {
      await _unCancelLesson(day);
      return;
    }

    final selection = await _pickReasonDialog();
    if (selection == null) return;

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l = AppLocalizations.of(context);
        final dateStr =
            '${day.day.toString().padLeft(2, '0')}.${day.month.toString().padLeft(2, '0')}.${day.year}';
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
              child: Text(
                l.confirmCancel,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    // Kullanıcıya period sonuna yeni ders eklemek ister misiniz diye sor
    if (!mounted) return;
    final addToEnd = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l = AppLocalizations.of(context);
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
              child: Text(l.yes, style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );

    await _attendanceActionsService.cancelLesson(
      clientId: clientId,
      periodId: periodId,
      lessonDate: day,
      addToEnd: addToEnd == true,
      reason: selection.reason.index,
      reasonNote: selection.note,
      lessonWeekdays: _lessonWeekdays,
    );

    await _reloadData();
    widget.onAttendanceChanged?.call();
  }

  Future<void> _unCancelLesson(DateTime day) async {
    final clientId = widget.client.id;
    final periodId = _currentPeriod.id;
    if (clientId == null || periodId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final l = AppLocalizations.of(context);
        final dateStr =
            '${day.day.toString().padLeft(2, '0')}.${day.month.toString().padLeft(2, '0')}.${day.year}';
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

    if (confirmed != true) return;

    await _attendanceActionsService.undoCancelledLesson(
      clientId: clientId,
      periodId: periodId,
      lessonDate: day,
      lessonWeekdays: _lessonWeekdays,
    );

    await _reloadData();
    widget.onAttendanceChanged?.call();
  }

  Future<void> _resetAttendance(DateTime day) async {
    final clientId = widget.client.id;
    final periodId = _currentPeriod.id;
    if (clientId == null || periodId == null) return;
    if (!await _confirmPastPeriodUpdateIfNeeded(day)) return;
    if (!mounted) return;

    final att = _attendance[day];
    // Henüz bir işlem yapılmamışsa geri alınacak bir şey yok
    if (att == null) return;

    final l = AppLocalizations.of(context);
    final dateStr =
        '${day.day.toString().padLeft(2, '0')}.${day.month.toString().padLeft(2, '0')}.${day.year}';

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
              child: Text(
                l.resetActionConfirm,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await _attendanceActionsService.resetAttendance(
      clientId: clientId,
      periodId: periodId,
      lessonDate: day,
      existingAttendance: _attendanceToRecord(att, lessonDate: day),
      lessonWeekdays: _lessonWeekdays,
    );

    await _reloadData();
    widget.onAttendanceChanged?.call();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l.actionReset),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final days = _getLessonDays();
    final originalEnd = DateTime.parse(_currentPeriod.endDate);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.periodCalendar),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: l.periodCalendarLegendTooltip,
            onPressed: _showIconLegend,
          ),
          if (_currentPeriod.postponedEndDate != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  l.postponedBadge,
                  style: TextStyle(
                    color: const Color(0xFFC8A415),
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              l.completedLessonCount(_completedLessonCount()),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          Expanded(
            child: AppBackground(
              child: ListView.builder(
                itemCount: days.length,
                itemBuilder: (context, index) {
                  final day = days[index];
                  final att = _attendance[day];
                  final isCancelled = att != null && att.cancelled;
                  final isAbsent = _isEffectivelyAbsent(att);
                  final isPostponedDay = day.isAfter(originalEnd);
                  Color cardColor;
                  if (isCancelled) {
                    cardColor = const Color(0xFFC8A415).withValues(alpha: 0.35);
                  } else if (isAbsent) {
                    cardColor = Colors.grey.shade300;
                  } else {
                    cardColor = Colors.green.shade200;
                  }
                  final hasAction =
                      att != null &&
                      (!att.absent || att.cancelled || att.makeup != null);
                  return Dismissible(
                    key: ValueKey('lesson_${day.toIso8601String()}'),
                    direction: hasAction
                        ? DismissDirection.endToStart
                        : DismissDirection.none,
                    confirmDismiss: (_) async {
                      await _resetAttendance(day);
                      return false; // Card'ı listeden kaldırma
                    },
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 24),
                      margin: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade400,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.undo, color: Colors.white),
                          const SizedBox(width: 8),
                          Text(
                            l.resetAction,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    child: Card(
                      color: cardColor,
                      margin: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 12,
                      ),
                      child: ListTile(
                        leading: isPostponedDay
                            ? const Icon(
                                Icons.add_circle,
                                color: Color(0xFFC8A415),
                                size: 20,
                              )
                            : null,
                        title: Text(
                          '${day.day.toString().padLeft(2, '0')}.${day.month.toString().padLeft(2, '0')}.${day.year} (${_localizedWeekday(day.weekday)})',
                          style: TextStyle(
                            decoration: isCancelled
                                ? TextDecoration.lineThrough
                                : null,
                            color: isCancelled ? Colors.brown : null,
                          ),
                        ),
                        subtitle: () {
                          String? subtitleText;
                          if (isCancelled) {
                            subtitleText = l.cancelled;
                            final reasonDetail = _buildReasonSubtitle(att, l);
                            if (reasonDetail.isNotEmpty) {
                              subtitleText += '\n$reasonDetail';
                            }
                          } else if (att?.makeup != null) {
                            subtitleText = l.makeupLabel(
                              '${att!.makeup!.day.toString().padLeft(2, '0')}.${att.makeup!.month.toString().padLeft(2, '0')}.${att.makeup!.year}',
                            );
                            final reasonDetail = _buildReasonSubtitle(att, l);
                            if (reasonDetail.isNotEmpty) {
                              subtitleText += '\n$reasonDetail';
                            }
                          } else if (isPostponedDay) {
                            subtitleText = l.postponedLesson;
                          }
                          return subtitleText != null
                              ? Text(
                                  subtitleText,
                                  style: isCancelled
                                      ? const TextStyle(
                                          color: Color(0xFF8B6914),
                                          fontWeight: FontWeight.w600,
                                        )
                                      : null,
                                )
                              : null;
                        }(),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                isCancelled
                                    ? Icons.block
                                    : (isAbsent ? Icons.close : Icons.check),
                              ),
                              color: isCancelled
                                  ? const Color(0xFFC8A415)
                                  : (att == null
                                        ? Colors.grey
                                        : (isAbsent
                                              ? Colors.red
                                              : Colors.green)),
                              onPressed: isCancelled
                                  ? null
                                  : () => _toggleAttendance(day),
                            ),
                            IconButton(
                              icon: const Icon(Icons.event_available),
                              tooltip: l.selectMakeupDate,
                              onPressed: isCancelled
                                  ? null
                                  : () => _setMakeup(day),
                            ),
                            IconButton(
                              icon: Icon(
                                isCancelled ? Icons.undo : Icons.event_busy,
                                size: 22,
                              ),
                              color: isCancelled
                                  ? Colors.blue
                                  : const Color(0xFFC8A415),
                              tooltip: isCancelled
                                  ? l.undoCancelTooltip
                                  : l.cancelAndPostpone,
                              onPressed: () => _cancelLesson(day),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Attendance {
  final bool absent;
  final bool cancelled;
  final bool isPostponed;
  final DateTime? makeup;
  final DateTime? attendedDate;
  final int? reason;
  final String? reasonNote;
  _Attendance({
    required this.absent,
    this.cancelled = false,
    this.isPostponed = false,
    this.makeup,
    this.attendedDate,
    this.reason,
    this.reasonNote,
  });
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

class _ReasonSelection {
  final LessonReason reason;
  final String? note;

  const _ReasonSelection({required this.reason, this.note});
}

class _LegendRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _LegendRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
      ],
    );
  }
}
