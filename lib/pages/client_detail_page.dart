import 'package:flutter/material.dart';
import '../models/client.dart';
import '../models/period.dart';
import '../models/session_schedule.dart';
import '../models/body_measurement.dart';
import '../services/database.dart';
import '../services/error_logger.dart';
import '../widgets/app_background.dart';
import '../widgets/period_list_section.dart';
import '../l10n/app_localizations.dart';

class ClientDetailPage extends StatefulWidget {
  final Client client;
  const ClientDetailPage({super.key, required this.client});

  @override
  State<ClientDetailPage> createState() => _ClientDetailPageState();
}

class _ClientDetailPageState extends State<ClientDetailPage> {
  final _db = AppDatabase();
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

  Future<void> _loadAllData() async {
    try {
      final clientId = _client.id;
      if (clientId == null) return;
      final periods = await _db.getPeriodsByClient(clientId);
      final schedules = await _db.getSessionSchedulesByClient(clientId);
      final measurements = await _db.getBodyMeasurementsByClient(clientId);
      // Load attended counts for each period
      // Green tick (attended) + Red X (not attended, not cancelled) = completed
      // Cancelled/postponed lessons do NOT count as completed
      final attendedCounts = <int, int>{};
      for (final period in periods) {
        if (period.id != null) {
          final attendanceRecords = await _db.getAttendanceForPeriod(
            clientId,
            period.id!,
          );
          final attended = attendanceRecords.values
              .where((r) => (r['cancelled'] as int? ?? 0) == 0)
              .length;
          attendedCounts[period.id!] = attended;
        }
      }
      if (!mounted) return;
      setState(() {
        _periods = periods;
        _schedules = schedules;
        _measurements = measurements;
        _attendedCounts = attendedCounts;
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

  Future<void> _showAddMeasurementDialog(BuildContext context) async {
    final clientId = widget.client.id;
    if (clientId == null) return;
    DateTime date = DateTime.now();
    final chestController = TextEditingController();
    final waistController = TextEditingController();
    final hipsController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final l = AppLocalizations.of(context);
            return AlertDialog(
              title: Text(l.addMeasurement),
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
                    final measurement = BodyMeasurement(
                      clientId: clientId,
                      date: date,
                      chest: chest,
                      waist: waist,
                      hips: hips,
                    );
                    await _db.insertBodyMeasurement(measurement);
                    await _loadAllData();
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

  Future<void> _showAddScheduleDialog(BuildContext context) async {
    const days = [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar',
    ];
    String selectedDay = days[0];
    TimeOfDay selectedTime = const TimeOfDay(hour: 10, minute: 0);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final l = AppLocalizations.of(context);
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(l.addLessonTimeTitle),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedDay,
                    decoration: InputDecoration(labelText: l.day),
                    items: days
                        .map(
                          (d) => DropdownMenuItem(
                            value: d,
                            child: Text(_localizedDay(context, d)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setStateDialog(() => selectedDay = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (picked != null) {
                        setStateDialog(() => selectedTime = picked);
                      }
                    },
                    child: Text(
                      l.timeLabel(
                        '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
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
                    final newSchedule = SessionSchedule(
                      clientId: widget.client.id,
                      dayOfWeek: selectedDay,
                      time:
                          '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                    );
                    await _db.insertSessionSchedule(newSchedule);
                    await _loadAllData();
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

  Future<void> _deleteSchedule(SessionSchedule schedule) async {
    final l = AppLocalizations.of(context);
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
      await _loadAllData();
    }
  }

  Future<void> _showEditScheduleDialog(
    BuildContext context,
    SessionSchedule schedule,
  ) async {
    final scheduleId = schedule.id;
    if (scheduleId == null) return;

    String selectedDay = schedule.dayOfWeek;
    TimeOfDay selectedTime = _parseTime(schedule.time);

    const days = [
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar',
    ];

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final l = AppLocalizations.of(context);
            return AlertDialog(
              title: Text(l.editLessonTime),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedDay,
                    decoration: InputDecoration(labelText: l.day),
                    items: days
                        .map(
                          (d) => DropdownMenuItem(
                            value: d,
                            child: Text(_localizedDay(context, d)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setStateDialog(() => selectedDay = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (picked != null) {
                        setStateDialog(() => selectedTime = picked);
                      }
                    },
                    child: Text(
                      l.timeLabel(
                        '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
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
                    final updatedSchedule = SessionSchedule(
                      id: scheduleId,
                      clientId: schedule.clientId,
                      dayOfWeek: selectedDay,
                      time:
                          '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                    );
                    await _db.updateSessionSchedule(updatedSchedule);
                    await _loadAllData();
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

  TimeOfDay _parseTime(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      return TimeOfDay(hour: hour, minute: minute);
    }
    return const TimeOfDay(hour: 9, minute: 0);
  }

  DateTime? _calculateEndDate(DateTime startDate) {
    // Paket adedi (kaç ders olacak)
    final sessionCount = widget.client.sessionPackage;
    // Gelinecek günler (schedule'dan al)
    final scheduleDays = _schedules.map((s) => s.dayOfWeek).toSet();
    if (scheduleDays.isEmpty || sessionCount <= 0) return null;

    // Gün isimlerini weekday'e çevir (Pazartesi=1, Salı=2, ...)
    int? dayNameToWeekday(String dayName) {
      const dayMap = {
        'Pazartesi': 1,
        'Salı': 2,
        'Çarşamba': 3,
        'Perşembe': 4,
        'Cuma': 5,
        'Cumartesi': 6,
        'Pazar': 7,
      };
      return dayMap[dayName];
    }

    final weekdays = scheduleDays
        .map((d) => dayNameToWeekday(d))
        .whereType<int>()
        .toSet();

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

  // Seçilen tarihten itibaren ilk ders gününü bul
  DateTime _findFirstLessonDay(DateTime selectedDate) {
    final scheduleDays = _schedules.map((s) => s.dayOfWeek).toSet();
    if (scheduleDays.isEmpty) return selectedDate;

    int? dayNameToWeekday(String dayName) {
      const dayMap = {
        'Pazartesi': 1,
        'Salı': 2,
        'Çarşamba': 3,
        'Perşembe': 4,
        'Cuma': 5,
        'Cumartesi': 6,
        'Pazar': 7,
      };
      return dayMap[dayName];
    }

    final weekdays = scheduleDays
        .map((d) => dayNameToWeekday(d))
        .whereType<int>()
        .toSet();

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
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  l.startInfo(
                                    period.startDate.substring(0, 10),
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.event, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  l.endInfo(period.endDate.substring(0, 10)),
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
                      paymentAmount: paymentAmount,
                      isPaid: isPaid,
                    );
                    await _db.updatePeriod(updatedPeriod);
                    await _loadAllData();
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
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.7)),
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
                                    child: Text(
                                      client.fullName,
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
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
                                            '${client.sessionPackage}',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            l.lessonPackage,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.white70,
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
                                          Text(
                                            _formatRegistrationDate(
                                              client.registrationDate,
                                            ),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            l.firstRegistration,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.white70,
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
                                          Text(
                                            l.period,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.white70,
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
                              onTap: () => _showAddScheduleDialog(context),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF43A047,
                                  ).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: Color(0xFF43A047),
                                  size: 22,
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
                                          // Düzenle ikonu
                                          GestureDetector(
                                            onTap: () =>
                                                _showEditScheduleDialog(
                                                  context,
                                                  schedule,
                                                ),
                                            child: Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: accentColor.withValues(
                                                  alpha: 0.1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Icon(
                                                Icons.edit_outlined,
                                                size: 18,
                                                color: accentColor,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
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
                      const SizedBox(height: 24),
                      // ── Beden Ölçüleri Başlık ──
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
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: () => _showAddMeasurementDialog(context),
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
                                border: Border.all(color: Colors.grey[300]!),
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
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFCE4EC),
                                      borderRadius: BorderRadius.circular(14),
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
                                                  color: const Color(
                                                    0xFFE91E63,
                                                  ).withValues(alpha: 0.12),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.calendar_today,
                                                      size: 14,
                                                      color: Color(0xFFAD1457),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      dateStr,
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w600,
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
                                                  icon: Icons.accessibility_new,
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
                                                  icon: Icons.circle_outlined,
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
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
