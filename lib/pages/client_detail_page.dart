import 'package:flutter/material.dart';
import '../models/client.dart';
import '../models/period.dart';
import '../models/session_schedule.dart';
import '../models/body_measurement.dart';
import '../models/package_type.dart';
import '../models/program_type.dart';
import '../services/database.dart';
import '../services/attendance_actions_service.dart';
import '../services/error_logger.dart';
import '../services/premium_service.dart';
import '../services/screen_preload_service.dart';
import '../widgets/app_background.dart';
import '../widgets/period_list_section.dart';
import '../l10n/app_localizations.dart';
import 'premium_page.dart';
import '../models/trainer_weekday.dart';

class ClientDetailPage extends StatefulWidget {
  final Client client;
  const ClientDetailPage({super.key, required this.client});

  @override
  State<ClientDetailPage> createState() => _ClientDetailPageState();
}

class _ClientDetailPageState extends State<ClientDetailPage> {
  static const List<TrainerWeekday> _scheduleDays = TrainerWeekday.values;

  final _db = AppDatabase();
  final _attendanceActionsService = AttendanceActionsService();
  final _screenPreloadService = ScreenPreloadService();
  late Client _client;
  List<Period> _periods = [];
  List<SessionSchedule> _schedules = [];
  List<BodyMeasurement> _measurements = [];
  Map<int, int> _attendedCounts = {}; // periodId -> attended count
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _client = widget.client;
    _loadAllData();
  }

  String _localizedDay(BuildContext context, String storageKey) {
    return TrainerWeekday.fromStorageKey(storageKey)?.localized(context) ??
        storageKey;
  }

  bool get _showsBodyMeasurements => _client.programType == ProgramType.sport;

  Set<int> _scheduledWeekdays() {
    return _schedules
        .map((schedule) => TrainerWeekday.fromStorageKey(schedule.dayOfWeek))
        .whereType<TrainerWeekday>()
        .map((day) => day.weekdayNumber)
        .toSet();
  }

  Set<int> _scheduledWeekdaysFromDraft(Map<String, String> draft) {
    return draft.keys
        .map(TrainerWeekday.fromStorageKey)
        .whereType<TrainerWeekday>()
        .map((day) => day.weekdayNumber)
        .toSet();
  }

  bool _sameWeekdaySet(Set<int> left, Set<int> right) {
    return left.length == right.length && left.containsAll(right);
  }

  void _showPendingLessonsRealignedSnackBar(int movedCount) {
    if (!mounted || movedCount <= 0) return;
    final l = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l.scheduleRealignedPendingLessons(movedCount)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _loadAllData() async {
    try {
      final clientId = _client.id;
      if (clientId == null) return;
      final preload = await _screenPreloadService.loadClientDetailPreload(
        client: _client,
      );
      if (!mounted) return;
      setState(() {
        _periods = preload.periods;
        _schedules = preload.schedules;
        _measurements = preload.measurements;
        _attendedCounts = preload.completedLessonsByPeriodId;
        _loading = false;
      });
    } catch (e, stack) {
      ErrorLogger().logError(
        error: e.toString(),
        stackTrace: stack.toString(),
        extra: '_ClientDetailPageState._loadAllData',
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _showAddMeasurementDialog(
    BuildContext context, {
    BodyMeasurement? measurement,
  }) async {
    final clientId = widget.client.id;
    if (clientId == null) return;
    DateTime date = measurement?.date ?? DateTime.now();
    final chestController = TextEditingController(
      text: measurement?.chest?.toString() ?? '',
    );
    final waistController = TextEditingController(
      text: measurement?.waist?.toString() ?? '',
    );
    final hipsController = TextEditingController(
      text: measurement?.hips?.toString() ?? '',
    );
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final l = AppLocalizations.of(context);
            return AlertDialog(
              title: Text(
                measurement == null ? l.addMeasurement : l.editMeasurement,
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setStateDialog(() => date = picked);
                      }
                    },
                    child: Text(
                      l.dateLabel('${date.day}.${date.month}.${date.year}'),
                    ),
                  ),
                  TextField(
                    controller: chestController,
                    decoration: InputDecoration(labelText: l.chest),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: waistController,
                    decoration: InputDecoration(labelText: l.waist),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: hipsController,
                    decoration: InputDecoration(labelText: l.hips),
                    keyboardType: TextInputType.number,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l.cancel),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final chest = double.tryParse(chestController.text);
                    final waist = double.tryParse(waistController.text);
                    final hips = double.tryParse(hipsController.text);
                    final updatedMeasurement = BodyMeasurement(
                      id: measurement?.id,
                      clientId: clientId,
                      date: date,
                      chest: chest,
                      waist: waist,
                      hips: hips,
                    );
                    if (measurement == null) {
                      await _db.insertBodyMeasurement(updatedMeasurement);
                    } else {
                      await _db.updateBodyMeasurement(updatedMeasurement);
                    }
                    await _loadAllData();
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
                  child: Text(l.save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showBulkScheduleEditorDialog(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final previousWeekdays = _scheduledWeekdays();
    final draft = <String, String>{
      for (final schedule in _schedules) schedule.dayOfWeek: schedule.time,
    };

    final updatedDraft = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(l.updateLessonTimes),
              content: SizedBox(
                width: 460,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _scheduleDays.map((day) {
                      final dayKey = day.storageKey;
                      final selectedTime = draft[dayKey];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                day.localized(context),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            OutlinedButton(
                              onPressed: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: _parseTime(selectedTime),
                                );
                                if (picked == null) return;
                                final value =
                                    '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                setStateDialog(() {
                                  draft[dayKey] = value;
                                });
                              },
                              child: Text(selectedTime ?? l.selectTime),
                            ),
                            if (selectedTime != null)
                              IconButton(
                                onPressed: () {
                                  setStateDialog(() {
                                    draft.remove(dayKey);
                                  });
                                },
                                icon: const Icon(Icons.close, size: 18),
                                tooltip: l.delete,
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l.cancel),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, draft),
                  child: Text(l.save),
                ),
              ],
            );
          },
        );
      },
    );

    if (updatedDraft == null) return;

    final byDay = <String, SessionSchedule>{
      for (final schedule in _schedules) schedule.dayOfWeek: schedule,
    };

    for (final existing in byDay.values) {
      final scheduleId = existing.id;
      if (scheduleId == null) continue;
      final newTime = updatedDraft[existing.dayOfWeek];
      if (newTime == null) {
        await _db.deleteSessionSchedule(scheduleId);
        continue;
      }
      if (newTime != existing.time) {
        await _db.updateSessionSchedule(
          SessionSchedule(
            id: scheduleId,
            clientId: existing.clientId,
            dayOfWeek: existing.dayOfWeek,
            time: newTime,
          ),
        );
      }
    }

    for (final entry in updatedDraft.entries) {
      if (byDay.containsKey(entry.key)) continue;
      await _db.insertSessionSchedule(
        SessionSchedule(
          clientId: widget.client.id,
          dayOfWeek: entry.key,
          time: entry.value,
        ),
      );
    }

    final newWeekdays = _scheduledWeekdaysFromDraft(updatedDraft);
    final clientId = _client.id;
    var movedCount = 0;
    if (clientId != null &&
        newWeekdays.isNotEmpty &&
        !_sameWeekdaySet(previousWeekdays, newWeekdays)) {
      movedCount = await _attendanceActionsService
          .realignOpenPeriodPendingLessonsToSchedule(
            clientId: clientId,
            newLessonWeekdays: newWeekdays,
          );
    }

    await _loadAllData();
    _showPendingLessonsRealignedSnackBar(movedCount);
  }

  Future<void> _deleteSchedule(SessionSchedule schedule) async {
    final l = AppLocalizations.of(context);
    final previousWeekdays = _scheduledWeekdays();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red[400], size: 28),
            const SizedBox(width: 10),
            Expanded(child: Text(l.confirmDeleteScheduleTitle)),
          ],
        ),
        content: Text(l.confirmDeleteScheduleMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l.delete),
          ),
        ],
      ),
    );
    if (confirmed == true && schedule.id != null) {
      await _db.deleteSessionSchedule(schedule.id!);

      final removedWeekday = TrainerWeekday.fromStorageKey(
        schedule.dayOfWeek,
      )?.weekdayNumber;
      final newWeekdays = Set<int>.from(previousWeekdays);
      if (removedWeekday != null) {
        newWeekdays.remove(removedWeekday);
      }

      final clientId = _client.id;
      var movedCount = 0;
      if (clientId != null &&
          newWeekdays.isNotEmpty &&
          !_sameWeekdaySet(previousWeekdays, newWeekdays)) {
        movedCount = await _attendanceActionsService
            .realignOpenPeriodPendingLessonsToSchedule(
              clientId: clientId,
              newLessonWeekdays: newWeekdays,
            );
      }

      await _loadAllData();
      _showPendingLessonsRealignedSnackBar(movedCount);
    }
  }

  TimeOfDay _parseTime(String? timeStr) {
    if (timeStr == null) return const TimeOfDay(hour: 9, minute: 0);
    final parts = timeStr.split(':');
    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      return TimeOfDay(hour: hour, minute: minute);
    }
    return const TimeOfDay(hour: 9, minute: 0);
  }

  DateTime? _calculateEndDate(DateTime startDate) {
    if (widget.client.packageType == PackageType.monthly) {
      return _calculateMonthlyEndDate(startDate);
    }
    // Paket adedi (kaç ders olacak)
    final sessionCount = widget.client.sessionPackage ?? 8;
    // Gelinecek günler (schedule'dan al)
    final weekdays = _scheduledWeekdays();

    if (weekdays.isEmpty) return null;

    int sessionsRemaining = sessionCount;
    DateTime current = startDate;

    // Başlangıç günü bir ders günü değilse, ilk ders gününe ilerle
    while (!weekdays.contains(current.weekday) && sessionsRemaining > 0) {
      current = current.add(const Duration(days: 1));
    }

    // İlk ders günü sayılır
    if (weekdays.contains(current.weekday)) {
      sessionsRemaining--;
    }

    while (sessionsRemaining > 0) {
      current = current.add(const Duration(days: 1));
      if (weekdays.contains(current.weekday)) {
        sessionsRemaining--;
      }
    }

    return current;
  }

  DateTime _calculateMonthlyEndDate(DateTime startDate) {
    final weekdays = _scheduledWeekdays();
    if (weekdays.isEmpty) return startDate;
    // Ayın son günü
    final lastOfMonth = DateTime(startDate.year, startDate.month + 1, 0);
    DateTime candidate = lastOfMonth;
    while (!candidate.isBefore(startDate) &&
        !weekdays.contains(candidate.weekday)) {
      candidate = candidate.subtract(const Duration(days: 1));
    }
    if (weekdays.contains(candidate.weekday)) return candidate;
    return startDate;
  }

  // Seçilen tarihten itibaren ilk ders gününü bul
  DateTime _findFirstLessonDay(DateTime selectedDate) {
    final weekdays = _scheduledWeekdays();

    if (weekdays.isEmpty) return selectedDate;

    DateTime current = selectedDate;
    // Eğer seçilen gün bir ders günü ise, onu döndür
    if (weekdays.contains(current.weekday)) {
      return current;
    }
    // Değilse, ilk ders gününe ilerle
    while (!weekdays.contains(current.weekday)) {
      current = current.add(const Duration(days: 1));
    }
    return current;
  }

  Future<void> _showAddPeriodDialog(BuildContext context) async {
    final clientId = widget.client.id;
    if (clientId == null) return;

    // Premium kontrolü: ücretsiz planda sporcu başına max 1 periyot
    if (!PremiumService().canAddPeriod(_periods.length)) {
      if (!mounted) return;
      final l = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l.maxPeriodsReached(PremiumService.freeMaxPeriodsPerClient),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          action: SnackBarAction(
            label: 'Premium',
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const PremiumPage()));
            },
          ),
        ),
      );
      return;
    }

    DateTime? startDate;
    DateTime? endDate;
    final paymentController = TextEditingController();
    bool isPaid = false;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final l = AppLocalizations.of(context);
            return AlertDialog(
              title: Text(l.addNewPeriod),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now().add(
                            const Duration(days: 365),
                          ),
                        );
                        if (picked != null) {
                          setStateDialog(() {
                            startDate = _findFirstLessonDay(picked);
                            endDate = _calculateEndDate(startDate!);
                          });
                        }
                      },
                      child: Text(
                        startDate == null
                            ? l.selectStartDate
                            : l.startDateLabel(
                                '${startDate!.day}.${startDate!.month}.${startDate!.year}',
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (widget.client.packageType != PackageType.monthly)
                      ElevatedButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: endDate ?? startDate ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (picked != null) {
                            setStateDialog(() => endDate = picked);
                          }
                        },
                        child: Text(
                          endDate == null
                              ? l.selectEndDate
                              : l.endDateLabel(
                                  '${endDate!.day}.${endDate!.month}.${endDate!.year}',
                                ),
                        ),
                      )
                    else if (endDate != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.calendar_month,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              l.endDateLabel(
                                '${endDate!.day}.${endDate!.month}.${endDate!.year}',
                              ),
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: paymentController,
                      decoration: InputDecoration(
                        labelText: l.paymentAmount,
                        prefixIcon: const Icon(Icons.attach_money),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      title: Text(l.paymentReceived),
                      value: isPaid,
                      onChanged: (value) {
                        setStateDialog(() => isPaid = value ?? false);
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l.cancel),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (startDate != null && endDate != null) {
                      final paymentAmount = double.tryParse(
                        paymentController.text,
                      );
                      final period = Period(
                        clientId: clientId,
                        startDate: startDate!.toIso8601String(),
                        endDate: endDate!.toIso8601String(),
                        paymentAmount: paymentAmount,
                        isPaid: isPaid,
                      );
                      await _db.insertPeriod(period);
                      await _loadAllData();
                      if (!context.mounted) return;
                      Navigator.pop(context);
                    }
                  },
                  child: Text(l.save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showPeriodDetailDialog(
    BuildContext context,
    Period period,
  ) async {
    final paymentController = TextEditingController(
      text: period.paymentAmount?.toStringAsFixed(0) ?? '',
    );
    bool isPaid = period.isPaid;

    // Mutable start/end dates for editing
    DateTime periodStart = DateTime.parse(period.startDate);
    DateTime periodEnd = DateTime.parse(period.endDate);
    // Allow editing if no session has been attended (period not started)
    int attendedCount = 0;
    try {
      if (period.id != null && _attendedCounts.containsKey(period.id!)) {
        attendedCount = _attendedCounts[period.id!] ?? 0;
      }
    } catch (_) {
      attendedCount = 0;
    }
    final bool canEditStart = attendedCount == 0 && period.id != null;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final l = AppLocalizations.of(context);
            return AlertDialog(
              title: Text(l.periodDetail),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      color: Colors.grey[100],
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: canEditStart
                                  ? () async {
                                      final today = DateTime.now();
                                      final safeInitialDate =
                                          periodStart.isBefore(today)
                                          ? today
                                          : periodStart;
                                      final safeFirstDate = today.subtract(
                                        const Duration(days: 7),
                                      );
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: safeInitialDate,
                                        firstDate: safeFirstDate,
                                        lastDate: safeFirstDate.add(
                                          const Duration(days: 365),
                                        ),
                                      );
                                      if (picked != null) {
                                        final newStart = _findFirstLessonDay(
                                          picked,
                                        );
                                        final newEnd = _calculateEndDate(
                                          newStart,
                                        );
                                        setStateDialog(() {
                                          periodStart = newStart;
                                          if (newEnd != null) {
                                            periodEnd = newEnd;
                                          }
                                        });
                                      }
                                    }
                                  : null,
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      l.startInfo(
                                        '${periodStart.day.toString().padLeft(2, '0')}.${periodStart.month.toString().padLeft(2, '0')}.${periodStart.year}',
                                      ),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  if (canEditStart)
                                    const Icon(
                                      Icons.edit_calendar,
                                      size: 18,
                                      color: Color(0xFF00897B),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.event, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  l.endInfo(
                                    '${periodEnd.day.toString().padLeft(2, '0')}.${periodEnd.month.toString().padLeft(2, '0')}.${periodEnd.year}',
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            if (period.postponedEndDate != null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.event_busy,
                                    size: 18,
                                    color: Color(0xFFC8A415),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    l.postponedInfo(
                                      period.postponedEndDate!.substring(0, 10),
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFC8A415),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l.paymentInfo,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: paymentController,
                      decoration: InputDecoration(
                        labelText: l.paymentAmount,
                        prefixIcon: const Icon(Icons.attach_money),
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      title: Text(l.paymentReceived),
                      subtitle: Text(
                        isPaid ? l.paymentCompleted : l.paymentAwaiting,
                        style: TextStyle(
                          color: isPaid ? Colors.green : Colors.orange,
                        ),
                      ),
                      value: isPaid,
                      onChanged: (value) {
                        setStateDialog(() => isPaid = value ?? false);
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      secondary: Icon(
                        isPaid ? Icons.check_circle : Icons.pending,
                        color: isPaid ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l.cancel),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final paymentAmount = double.tryParse(
                      paymentController.text,
                    );
                    final updatedPeriod = period.copyWith(
                      startDate: periodStart.toIso8601String(),
                      endDate: periodEnd.toIso8601String(),
                      paymentAmount: paymentAmount,
                      isPaid: isPaid,
                    );
                    await _db.updatePeriod(updatedPeriod);
                    await _loadAllData();
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
                  child: Text(l.update),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatRegistrationDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    } catch (_) {
      return '-';
    }
  }

  Future<void> _showEditClientInfoDialog(BuildContext context) async {
    final nameController = TextEditingController(text: _client.fullName);
    DateTime? regDate;
    try {
      if (_client.registrationDate != null) {
        regDate = DateTime.parse(_client.registrationDate!);
      }
    } catch (_) {}
    regDate ??= DateTime.now();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final l = AppLocalizations.of(context);
            return AlertDialog(
              title: Text(l.editAthleteInfo),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: l.fullName,
                      prefixIcon: const Icon(Icons.person),
                      border: const OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: regDate!,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setStateDialog(() => regDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: l.registrationDate,
                        prefixIcon: const Icon(Icons.calendar_today),
                        border: const OutlineInputBorder(),
                      ),
                      child: Text(
                        '${regDate!.day.toString().padLeft(2, '0')}.${regDate!.month.toString().padLeft(2, '0')}.${regDate!.year}',
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(l.cancel),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;
                    final updated = _client.copyWith(
                      fullName: name,
                      registrationDate: regDate!.toIso8601String(),
                    );
                    await _db.updateClient(updated);
                    setState(() => _client = updated);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
                  child: Text(l.save),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _measurementTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final client = _client;
    return Scaffold(
      appBar: AppBar(title: Text(l.athleteDetail)),
      body: AppBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Renkli Sporcu Bilgi Kartı ──
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00897B), Color(0xFF00BCD4)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF00BCD4,
                              ).withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // İsim + Düzenle
                              Row(
                                children: [
                                  const CircleAvatar(
                                    radius: 28,
                                    backgroundColor: Colors.white24,
                                    child: Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        client.fullName,
                                        style: const TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.white70,
                                      size: 20,
                                    ),
                                    tooltip: l.editInfo,
                                    onPressed: () =>
                                        _showEditClientInfoDialog(context),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Alt bilgiler
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    // Paket
                                    Expanded(
                                      child: Column(
                                        children: [
                                          const Icon(
                                            Icons.fitness_center,
                                            color: Colors.white70,
                                            size: 22,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            client.packageType ==
                                                    PackageType.monthly
                                                ? l.packageTypeMonthly
                                                : '${client.sessionPackage ?? 8}',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              client.packageType ==
                                                      PackageType.monthly
                                                  ? l.packageTypeLabel
                                                  : l.lessonPackage,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 1,
                                      height: 40,
                                      color: Colors.white24,
                                    ),
                                    // Kayıt Tarihi
                                    Expanded(
                                      child: Column(
                                        children: [
                                          const Icon(
                                            Icons.calendar_today,
                                            color: Colors.white70,
                                            size: 22,
                                          ),
                                          const SizedBox(height: 4),
                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              _formatRegistrationDate(
                                                client.registrationDate,
                                              ),
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              l.firstRegistration,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 1,
                                      height: 40,
                                      color: Colors.white24,
                                    ),
                                    // Aktif Periyot
                                    Expanded(
                                      child: Column(
                                        children: [
                                          Icon(
                                            _periods.isNotEmpty
                                                ? Icons.check_circle
                                                : Icons.cancel,
                                            color: _periods.isNotEmpty
                                                ? Colors.greenAccent
                                                : Colors.redAccent,
                                            size: 22,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${_periods.length}',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: Text(
                                              l.period,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      PeriodListSection(
                        periods: _periods,
                        client: client,
                        schedules: _schedules,
                        attendedCounts: _attendedCounts,
                        onAddPeriod: () => _showAddPeriodDialog(context),
                        onPeriodDetail: (period) =>
                            _showPeriodDetailDialog(context, period),
                        onDataChanged: _loadAllData,
                      ),
                      const SizedBox(height: 24),
                      // ── Ders Günleri Başlık ──
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF00BCD4,
                              ).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.calendar_month,
                              color: Color(0xFF00897B),
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              l.lessonTimes,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () =>
                                  _showBulkScheduleEditorDialog(context),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF43A047,
                                  ).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  l.updateLessonTimes,
                                  style: const TextStyle(
                                    color: Color(0xFF2E7D32),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _schedules.isEmpty
                          ? Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Text(
                                l.noScheduleAdded,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _schedules.length,
                              itemBuilder: (context, index) {
                                final schedule = _schedules[index];
                                // Tüm günler aynı açık soft yeşil renk
                                const bgColor = Color(0xFFE8F5E9);
                                const accentColor = Color(0xFF43A047);

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: bgColor,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: accentColor.withValues(
                                          alpha: 0.3,
                                        ),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: accentColor.withValues(
                                            alpha: 0.1,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 14,
                                      ),
                                      child: Row(
                                        children: [
                                          // Gün rozeti
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              color: accentColor.withValues(
                                                alpha: 0.15,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Center(
                                              child: Text(
                                                _localizedDay(
                                                  context,
                                                  schedule.dayOfWeek,
                                                ).substring(0, 2).toUpperCase(),
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: accentColor,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          // Gün adı + saat
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  _localizedDay(
                                                    context,
                                                    schedule.dayOfWeek,
                                                  ),
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                    color: accentColor
                                                        .withValues(
                                                          alpha: 0.85,
                                                        ),
                                                  ),
                                                ),
                                                const SizedBox(height: 3),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.access_time,
                                                      size: 14,
                                                      color: Colors.grey[600],
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      schedule.time,
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        color: Colors.grey[700],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Sil ikonu
                                          GestureDetector(
                                            onTap: () =>
                                                _deleteSchedule(schedule),
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: Colors.red.withValues(
                                                  alpha: 0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                Icons.delete_outline,
                                                size: 18,
                                                color: Colors.red[400],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                      if (_showsBodyMeasurements) ...[
                        const SizedBox(height: 24),
                        // ── Beden Ölçüleri Başlık ──
                        if (!PremiumService().canAccessBodyMeasurements)
                          _buildPremiumLockedSection(
                            context,
                            icon: Icons.straighten,
                            iconColor: const Color(0xFFAD1457),
                            bgColor: const Color(
                              0xFFE91E63,
                            ).withValues(alpha: 0.12),
                            title: l.bodyMeasurements,
                          )
                        else ...[
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFE91E63,
                                  ).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.straighten,
                                  color: Color(0xFFAD1457),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  l.bodyMeasurements,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              FilledButton.icon(
                                onPressed: () =>
                                    _showAddMeasurementDialog(context),
                                icon: const Icon(Icons.add, size: 18),
                                label: Text(l.add),
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFFE91E63),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _measurements.isEmpty
                              ? Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                    ),
                                  ),
                                  child: Text(
                                    l.noMeasurementYet,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey[500]),
                                  ),
                                )
                              : ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _measurements.length,
                                  itemBuilder: (context, index) {
                                    final m = _measurements[index];
                                    final dateStr =
                                        '${m.date.day.toString().padLeft(2, '0')}.${m.date.month.toString().padLeft(2, '0')}.${m.date.year}';

                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 10,
                                      ),
                                      child: GestureDetector(
                                        onTap: () => _showAddMeasurementDialog(
                                          context,
                                          measurement: m,
                                        ),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFCE4EC),
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            border: Border.all(
                                              color: const Color(
                                                0xFFE91E63,
                                              ).withValues(alpha: 0.2),
                                              width: 1.5,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(
                                                  0xFFE91E63,
                                                ).withValues(alpha: 0.08),
                                                blurRadius: 8,
                                                offset: const Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(14),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // Tarih satırı
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 10,
                                                            vertical: 5,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            const Color(
                                                              0xFFE91E63,
                                                            ).withValues(
                                                              alpha: 0.12,
                                                            ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          const Icon(
                                                            Icons
                                                                .calendar_today,
                                                            size: 14,
                                                            color: Color(
                                                              0xFFAD1457,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 6,
                                                          ),
                                                          Text(
                                                            dateStr,
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 13,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color: Color(
                                                                    0xFFAD1457,
                                                                  ),
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 12),
                                                // Ölçü değerleri
                                                Row(
                                                  children: [
                                                    // Göğüs
                                                    Expanded(
                                                      child: _measurementTile(
                                                        icon: Icons
                                                            .accessibility_new,
                                                        label: l.chest,
                                                        value: m.chest != null
                                                            ? '${m.chest}'
                                                            : '-',
                                                        color: const Color(
                                                          0xFF00897B,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    // Bel
                                                    Expanded(
                                                      child: _measurementTile(
                                                        icon: Icons.straighten,
                                                        label: l.waist,
                                                        value: m.waist != null
                                                            ? '${m.waist}'
                                                            : '-',
                                                        color: const Color(
                                                          0xFF1E88E5,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    // Kalça
                                                    Expanded(
                                                      child: _measurementTile(
                                                        icon: Icons
                                                            .circle_outlined,
                                                        label: l.hips,
                                                        value: m.hips != null
                                                            ? '${m.hips}'
                                                            : '-',
                                                        color: const Color(
                                                          0xFF8E24AA,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ], // end else body measurements premium
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildPremiumLockedSection(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String title,
  }) {
    final l = AppLocalizations.of(context);
    return GestureDetector(
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const PremiumPage()));
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Icon(Icons.lock, color: Color(0xFFFFB300), size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.workspace_premium,
                    color: Color(0xFFFFB300),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l.premiumRequired,
                    style: const TextStyle(
                      color: Color(0xFFFF8F00),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
