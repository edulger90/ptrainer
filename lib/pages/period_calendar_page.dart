import 'package:flutter/material.dart';
import '../models/period.dart';
import '../models/session_schedule.dart';
import '../models/client.dart';
import '../services/database.dart';
import '../services/error_logger.dart';
import '../widgets/app_background.dart';
import '../l10n/app_localizations.dart';
import '../models/lesson_reason.dart';
import '../utils/lesson_utils.dart';

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
  int _completedLessonCount() {
    // Convert _Attendance objects to Map<String, dynamic> for the helper
    Iterable<Map<String, dynamic>> attendanceMaps = _attendance.entries.map((
      entry,
    ) {
      final att = entry.value;
      final attended = !att.absent && !att.cancelled;
      return {
        'attended': attended ? 1 : 0,
        'cancelled': att.cancelled ? 1 : 0,
        'isPostponed': att.isPostponed ? 1 : 0,
      };
    });
    return LessonUtils.completedLessonCount(attendanceMaps, _currentPeriod);
  }

  final _db = AppDatabase();
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
    _start = DateTime.parse(_currentPeriod.startDate);
    _end = DateTime.parse(
      _currentPeriod.postponedEndDate ?? _currentPeriod.endDate,
    );
    _lessonWeekdays = widget.schedules
        .map((s) => _weekdayNumber(s.dayOfWeek))
        .toSet();
    _loadAttendance();
  }

  Future<void> _refreshPeriod() async {
    try {
      final clientId = widget.client.id;
      if (clientId == null) return;
      final periods = await _db.getPeriodsByClient(clientId);
      final updated = periods
          .where((p) => p.id == _currentPeriod.id)
          .firstOrNull;
      if (updated != null) {
        if (!mounted) return;
        setState(() {
          _currentPeriod = updated;
          _end = DateTime.parse(updated.postponedEndDate ?? updated.endDate);
          _cachedLessonDays = null; // Cache'i invalidate et
        });
      }
    } catch (e, stack) {
      ErrorLogger().logError(
        error: e.toString(),
        stackTrace: stack.toString(),
        extra: '_PeriodCalendarPageState._refreshPeriod',
      );
    }
  }

  Future<void> _loadAttendance() async {
    try {
      final clientId = widget.client.id;
      final periodId = _currentPeriod.id;
      if (clientId == null || periodId == null) {
        setState(() {
          _attendance = {};
        });
        return;
      }
      final records = await _db.getAttendanceForPeriod(clientId, periodId);
      debugPrint(
        '[DEBUG] _loadAttendance: records = ${records.map((k, v) => MapEntry(k.toString(), v.toString()))}',
      );
      if (!mounted) return;
      setState(() {
        _attendance = {
          for (final entry in records.entries)
            entry.key: _Attendance(
              absent: (entry.value['attended'] as int? ?? 0) == 0,
              cancelled: (entry.value['cancelled'] as int? ?? 0) == 1,
              isPostponed: (entry.value['isPostponed'] as int? ?? 0) == 1,
              makeup:
                  entry.value['makeupDate'] != null &&
                      entry.value['makeupDate'] != ''
                  ? DateTime.tryParse(entry.value['makeupDate'] as String)
                  : null,
              attendedDate:
                  entry.value['attendedDate'] != null &&
                      entry.value['attendedDate'] != ''
                  ? DateTime.tryParse(entry.value['attendedDate'] as String)
                  : null,
            ),
        };
      });
    } catch (e, stack) {
      ErrorLogger().logError(
        error: e.toString(),
        stackTrace: stack.toString(),
        extra: '_PeriodCalendarPageState._loadAttendance',
      );
      if (!mounted) return;
      setState(() {
        _attendance = {};
      });
    }
  }

  int _weekdayNumber(String turkishDay) {
    switch (turkishDay) {
      case 'Pazartesi':
        return DateTime.monday;
      case 'Salı':
        return DateTime.tuesday;
      case 'Çarşamba':
        return DateTime.wednesday;
      case 'Perşembe':
        return DateTime.thursday;
      case 'Cuma':
        return DateTime.friday;
      case 'Cumartesi':
        return DateTime.saturday;
      case 'Pazar':
        return DateTime.sunday;
      default:
        return DateTime.monday;
    }
  }

  String _localizedWeekday(int weekday) {
    if (!mounted) return '';
    final l = AppLocalizations.of(context);
    return l.dayOfWeekByIndex(weekday);
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

  void _toggleAttendance(DateTime day) async {
    final clientId = widget.client.id;
    final periodId = _currentPeriod.id;
    if (clientId == null || periodId == null) return;

    final att = _attendance[day];
    if (att != null && att.cancelled) {
      return;
    }

    bool newAttended = att == null || att.absent;
    DateTime? attendedDate = newAttended ? day : null;

    await _db.upsertAttendance(
      clientId: clientId,
      periodId: periodId,
      lessonDate: day,
      attended: newAttended,
      cancelled: false,
      isPostponed: false,
      attendedDate: attendedDate,
      makeupDate: att?.makeup,
      reason: null,
    );
    await _loadAttendance();
    widget.onAttendanceChanged?.call();
  }

  Future<LessonReason?> _pickReasonDialog() async {
    final l = AppLocalizations.of(context);
    return showDialog<LessonReason>(
      context: context,
      builder: (context) {
        LessonReason? selected = LessonReason.resmiTatil;
        return AlertDialog(
          title: Text(l.selectReason),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: LessonReason.values.map((reason) {
                  return RadioListTile<LessonReason>(
                    title: Text(l.lessonReasonLabel(reason)),
                    value: reason,
                    // ignore: deprecated_member_use
                    groupValue: selected,
                    // ignore: deprecated_member_use
                    onChanged: (val) => setState(() => selected = val),
                    visualDensity: VisualDensity.compact,
                    selected: selected == reason,
                  );
                }).toList(),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, null),
              child: Text(l.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, selected),
              child: Text(l.save),
            ),
          ],
        );
      },
    );
  }

  void _setMakeup(DateTime day) async {
    final clientId = widget.client.id;
    final periodId = _currentPeriod.id;
    if (clientId == null || periodId == null) return;
    final picked = await showDatePicker(
      context: context,
      initialDate: day,
      firstDate: _start,
      lastDate: _end.add(const Duration(days: 60)),
    );
    if (picked != null) {
      final reason = await _pickReasonDialog();
      if (reason == null) return;
      await _db.upsertAttendance(
        clientId: clientId,
        periodId: periodId,
        lessonDate: day,
        attended: false, // Telafi günü eklerken yapılmadı olarak kaydet
        cancelled: false,
        isPostponed: false,
        attendedDate: null, // Yapıldı tarihi boş
        makeupDate: picked, // Sadece telafi günü kaydedilsin
        reason: reason.index,
      );
      await _loadAttendance();
      widget.onAttendanceChanged?.call();
    }
  }

  void _cancelLesson(DateTime day) async {
    final clientId = widget.client.id;
    final periodId = _currentPeriod.id;
    if (clientId == null || periodId == null) return;

    final att = _attendance[day];
    if (att != null && att.cancelled) {
      await _unCancelLesson(day);
      return;
    }

    final reason = await _pickReasonDialog();
    if (reason == null) return;

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

    // Cancelled attendance kaydı: isPostponed, period uzatılacak mı?
    await _db.upsertAttendance(
      clientId: clientId,
      periodId: periodId,
      lessonDate: day,
      attended: false,
      cancelled: true,
      isPostponed: addToEnd == true,
      attendedDate: null,
      makeupDate: null,
      reason: reason.index,
    );

    if (addToEnd == true) {
      final currentEffectiveEnd = DateTime.parse(
        _currentPeriod.postponedEndDate ?? _currentPeriod.endDate,
      );
      final nextLessonDay = _findNextLessonDay(currentEffectiveEnd);
      final updatedPeriod = _currentPeriod.copyWith(
        postponedEndDate: nextLessonDay.toIso8601String(),
      );
      await _db.updatePeriod(updatedPeriod);
    }

    await _refreshPeriod();
    await _loadAttendance();
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

    await _db.upsertAttendance(
      clientId: clientId,
      periodId: periodId,
      lessonDate: day,
      attended: false,
      cancelled: false,
      isPostponed: false,
      attendedDate: null,
      makeupDate: null,
      reason: null,
    );

    final currentPostponed = _currentPeriod.postponedEndDate;
    if (currentPostponed != null) {
      final currentEnd = DateTime.parse(currentPostponed);
      final originalEnd = DateTime.parse(_currentPeriod.endDate);
      final previousEnd = _findPreviousLessonDay(currentEnd);

      String? newPostponed;
      if (!previousEnd.isAfter(originalEnd)) {
        newPostponed = null;
      } else {
        newPostponed = previousEnd.toIso8601String();
      }

      final db = await _db.database;
      await db.update(
        'periods',
        {'postponedEndDate': newPostponed},
        where: 'id = ?',
        whereArgs: [periodId],
      );
    }

    await _refreshPeriod();
    await _loadAttendance();
    widget.onAttendanceChanged?.call();
  }

  DateTime _findNextLessonDay(DateTime fromDate) {
    var day = fromDate.add(const Duration(days: 1));
    while (!_lessonWeekdays.contains(day.weekday)) {
      day = day.add(const Duration(days: 1));
    }
    return day;
  }

  DateTime _findPreviousLessonDay(DateTime fromDate) {
    var day = fromDate.subtract(const Duration(days: 1));
    while (!_lessonWeekdays.contains(day.weekday)) {
      day = day.subtract(const Duration(days: 1));
    }
    return day;
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
                  final isPostponedDay = day.isAfter(originalEnd);
                  Color cardColor;
                  if (isCancelled) {
                    cardColor = const Color(0xFFC8A415).withValues(alpha: 0.35);
                  } else if (att == null || att.absent) {
                    cardColor = Colors.grey.shade300;
                  } else {
                    cardColor = Colors.green.shade200;
                  }
                  return Card(
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
                      subtitle: isCancelled
                          ? Text(
                              l.cancelled,
                              style: const TextStyle(
                                color: Color(0xFF8B6914),
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : att?.makeup != null
                          ? Text(
                              l.makeupLabel(
                                '${att!.makeup!.day.toString().padLeft(2, '0')}.${att.makeup!.month.toString().padLeft(2, '0')}.${att.makeup!.year}',
                              ),
                            )
                          : isPostponedDay
                          ? Text(
                              l.postponedLesson,
                              style: const TextStyle(
                                color: Color(0xFF8B6914),
                                fontStyle: FontStyle.italic,
                              ),
                            )
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              isCancelled
                                  ? Icons.block
                                  : (att == null || att.absent
                                        ? Icons.close
                                        : Icons.check),
                            ),
                            color: isCancelled
                                ? const Color(0xFFC8A415)
                                : (att == null
                                      ? Colors.grey
                                      : (att.absent
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
  _Attendance({
    required this.absent,
    this.cancelled = false,
    this.isPostponed = false,
    this.makeup,
    this.attendedDate,
  });
}
