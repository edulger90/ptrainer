import 'package:flutter/material.dart';
import '../models/client.dart';
import '../models/user.dart';
import '../models/session_schedule.dart';
import '../services/database.dart';
import '../main.dart';
import '../widgets/app_background.dart';
import '../l10n/app_localizations.dart';
import '../utils/day_localization.dart';

class AddClientPage extends StatefulWidget {
  final User currentUser;
  const AddClientPage({super.key, required this.currentUser});

  @override
  State<AddClientPage> createState() => _AddClientPageState();
}

class _AddClientPageState extends State<AddClientPage> {
  final _nameController = TextEditingController();
  final _db = AppDatabase();

  int _selectedPackage = 8;
  DateTime _registrationDate = DateTime.now();
  String? _error;
  String? _selectedDay; // Internal key (Turkish for DB compat)
  String? _selectedTime;

  // Internal day keys for DB storage (must remain consistent)
  static const List<String> _dayKeys = [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar',
  ];

  // ...existing code...

  final Map<String, List<String>> _selectedSchedules = {};

  Future<void> _saveClient() async {
    final fullName = _nameController.text.trim();
    final l = AppLocalizations.of(context);

    if (fullName.isEmpty) {
      setState(() {
        _error = l.nameEmpty;
      });
      return;
    }

    if (_selectedSchedules.isEmpty) {
      setState(() {
        _error = l.atLeastOneSchedule;
      });
      return;
    }

    final client = Client(
      userId: widget.currentUser.id,
      fullName: fullName,
      sessionPackage: _selectedPackage,
      createdAt: DateTime.now().toIso8601String(),
      registrationDate: _registrationDate.toIso8601String(),
    );

    final clientId = await _db.insertClient(client);

    // Save schedules
    for (final day in _selectedSchedules.keys) {
      for (final time in _selectedSchedules[day]!) {
        final schedule = SessionSchedule(
          clientId: clientId,
          dayOfWeek: day,
          time: time,
        );
        await _db.insertSessionSchedule(schedule);
      }
    }

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  void _showAddScheduleDialog() {
    setState(() {
      _selectedDay = null;
      _selectedTime = null;
    });

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          final l = AppLocalizations.of(context);
          return AlertDialog(
            title: Text(l.addLessonTimeTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.selectDay,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: _dayKeys.map((dayKey) {
                    final isSelected = _selectedDay == dayKey;
                    return FilterChip(
                      label: Text(
                        DayLocalizationHelper.localizedDay(context, dayKey),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        setStateDialog(() {
                          _selectedDay = selected ? dayKey : null;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                Text(
                  l.selectTime,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                if (_selectedDay != null)
                  ElevatedButton.icon(
                    onPressed: () async {
                      final time = await _selectTime();
                      if (time != null) {
                        setStateDialog(() {
                          _selectedTime = time;
                        });
                      }
                    },
                    icon: const Icon(Icons.schedule),
                    label: Text(
                      _selectedTime ?? l.selectTime,
                      style: const TextStyle(fontSize: 14),
                    ),
                  )
                else
                  Text(
                    l.selectDayFirst,
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l.cancel),
              ),
              ElevatedButton(
                onPressed: (_selectedDay != null && _selectedTime != null)
                    ? () {
                        setState(() {
                          if (!_selectedSchedules.containsKey(_selectedDay)) {
                            _selectedSchedules[_selectedDay!] = [];
                          }
                          _selectedSchedules[_selectedDay!]!.add(
                            _selectedTime!,
                          );
                        });
                        Navigator.pop(context);
                      }
                    : null,
                child: Text(l.add),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<String?> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      return '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(l.addNewAthlete),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: l.logout,
            onPressed: _logout,
          ),
        ],
      ),
      body: AppBackground(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: l.fullName,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _registrationDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => _registrationDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: l.registrationDate,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      '${_registrationDate.day.toString().padLeft(2, '0')}.${_registrationDate.month.toString().padLeft(2, '0')}.${_registrationDate.year}',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: _selectedPackage,
                  decoration: InputDecoration(
                    labelText: l.packageSize,
                    border: const OutlineInputBorder(),
                  ),
                  items: [8, 10, 12, 16].map((value) {
                    return DropdownMenuItem<int>(
                      value: value,
                      child: Text(l.packageOption(value)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedPackage = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  l.lessonSchedules,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _showAddScheduleDialog,
                  icon: const Icon(Icons.add),
                  label: Text(l.addLessonTime),
                ),
                const SizedBox(height: 12),
                if (_selectedSchedules.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      l.noScheduleYet,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _selectedSchedules.length,
                    itemBuilder: (context, index) {
                      final day = _selectedSchedules.keys.toList()[index];
                      final times = _selectedSchedules[day]!;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DayLocalizationHelper.localizedDay(
                                  context,
                                  day,
                                ),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...times.asMap().entries.map((e) {
                                final timeIndex = e.key;
                                final time = e.value;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 4.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(time),
                                      IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _selectedSchedules[day]!.removeAt(
                                              timeIndex,
                                            );
                                            if (_selectedSchedules[day]!
                                                .isEmpty) {
                                              _selectedSchedules.remove(day);
                                            }
                                          });
                                        },
                                        icon: const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                          size: 18,
                                        ),
                                        padding: const EdgeInsets.all(0),
                                        constraints: const BoxConstraints(),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saveClient,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(l.saveAthlete),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthPage()),
      (route) => false,
    );
  }
}
