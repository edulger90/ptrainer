import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/client.dart';
import '../models/program_type.dart';
import '../models/user.dart';
import '../models/session_schedule.dart';
import '../models/package_type.dart';
import '../services/database.dart';
import '../services/session_timeout_service.dart';
import '../widgets/app_background.dart';
import '../l10n/app_localizations.dart';
import '../models/trainer_weekday.dart';

class AddClientPage extends StatefulWidget {
  final User currentUser;
  const AddClientPage({super.key, required this.currentUser});

  @override
  State<AddClientPage> createState() => _AddClientPageState();
}

class _AddClientPageState extends State<AddClientPage> {
  final _nameController = TextEditingController();
  final _packageCountController = TextEditingController(text: '8');
  final _db = AppDatabase();

  int _selectedPackage = 8;
  ProgramType _selectedProgramType = ProgramType.sport;
  PackageType _selectedPackageType = PackageType.daily;
  DateTime _registrationDate = DateTime.now();
  String? _error;
  String? _selectedDay; // Internal key (Turkish for DB compat)
  String? _selectedTime;

  static const List<TrainerWeekday> _scheduleDays = TrainerWeekday.values;

  // ...existing code...

  final Map<String, List<String>> _selectedSchedules = {};

  @override
  void dispose() {
    _nameController.dispose();
    _packageCountController.dispose();
    super.dispose();
  }

  String _localizedDay(BuildContext context, String storageKey) {
    return TrainerWeekday.fromStorageKey(storageKey)?.localized(context) ??
        storageKey;
  }

  void _showScheduleDayExistsMessage() {
    final l = AppLocalizations.of(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l.scheduleDayAlreadyExists)));
  }

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

    if (_selectedPackageType == PackageType.daily) {
      final packageCount = int.tryParse(_packageCountController.text);
      if (packageCount == null || packageCount < 1 || packageCount > 100) {
        setState(() {
          _error = l.packageCountValidation;
        });
        return;
      }
      _selectedPackage = packageCount;
    }

    final client = Client(
      userId: widget.currentUser.id,
      fullName: fullName,
      sessionPackage: _selectedPackageType == PackageType.daily
          ? _selectedPackage
          : null,
      packageType: _selectedPackageType,
      programType: _selectedProgramType,
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
    final createdClient = client.copyWith(id: clientId);
    Navigator.of(context).pop(createdClient);
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
                  children: _scheduleDays.map((day) {
                    final dayKey = day.storageKey;
                    final isSelected = _selectedDay == dayKey;
                    final isUsed =
                        _selectedSchedules.containsKey(dayKey) && !isSelected;
                    return FilterChip(
                      label: Text(day.localized(context)),
                      selected: isSelected,
                      onSelected: isUsed
                          ? null
                          : (selected) {
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
                        if (_selectedSchedules.containsKey(_selectedDay)) {
                          Navigator.pop(context);
                          _showScheduleDayExistsMessage();
                          return;
                        }
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
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: l.programTypeLabel,
                    border: const OutlineInputBorder(),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [ProgramType.sport, ProgramType.personal].map((
                      type,
                    ) {
                      final label = switch (type) {
                        ProgramType.sport => l.programTypeSport,
                        ProgramType.personal => l.programTypePersonal,
                        ProgramType.course => l.programTypeCourse,
                      };
                      return ChoiceChip(
                        label: Text(label),
                        selected: _selectedProgramType == type,
                        onSelected: (_) {
                          setState(() {
                            _selectedProgramType = type;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                // Package type selector
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: l.packageTypeLabel,
                    border: const OutlineInputBorder(),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: PackageType.values.map((type) {
                          final label = type == PackageType.daily
                              ? l.packageTypeDaily
                              : l.packageTypeMonthly;
                          final selected = _selectedPackageType == type;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(label),
                              selected: selected,
                              onSelected: (_) {
                                setState(() {
                                  _selectedPackageType = type;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                      if (_selectedPackageType == PackageType.daily) ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _packageCountController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(3),
                          ],
                          decoration: InputDecoration(
                            labelText: l.packageSize,
                            border: const OutlineInputBorder(),
                            helperText: '1-100',
                          ),
                        ),
                      ],
                    ],
                  ),
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
                                _localizedDay(context, day),
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

  Future<void> _logout() async {
    await SessionTimeoutService.instance.logoutNow();
  }
}
