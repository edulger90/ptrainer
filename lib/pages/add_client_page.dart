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

  static const List<TrainerWeekday> _scheduleDays = TrainerWeekday.values;

  // ...existing code...

  final Map<String, String> _selectedSchedules = {};

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
    for (final entry in _selectedSchedules.entries) {
      final schedule = SessionSchedule(
        clientId: clientId,
        dayOfWeek: entry.key,
        time: entry.value,
      );
      await _db.insertSessionSchedule(schedule);
    }

    if (!mounted) return;
    final createdClient = client.copyWith(id: clientId);
    Navigator.of(context).pop(createdClient);
  }

  Future<void> _showBulkScheduleDialog() async {
    final draft = <String, String>{..._selectedSchedules};

    final updatedSchedules = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final l = AppLocalizations.of(context);
            final dialogWidth = MediaQuery.sizeOf(context).width;
            final useCompactLayout = dialogWidth < 380;
            return AlertDialog(
              title: Text(l.addLessonTimeTitle),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: dialogWidth > 520 ? 460 : dialogWidth * 0.9,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _scheduleDays.map((day) {
                      final dayKey = day.storageKey;
                      final selectedTime = draft[dayKey];
                      final timeButton = OutlinedButton(
                        onPressed: () async {
                          final time = await _selectTime(
                            initial: _parseTime(selectedTime),
                          );
                          if (time == null) return;
                          setStateDialog(() {
                            draft[dayKey] = time;
                          });
                        },
                        child: Text(selectedTime ?? l.selectTime),
                      );

                      final deleteButton = selectedTime != null
                          ? IconButton(
                              onPressed: () {
                                setStateDialog(() {
                                  draft.remove(dayKey);
                                });
                              },
                              icon: const Icon(Icons.close, size: 18),
                              tooltip: l.delete,
                            )
                          : null;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: useCompactLayout
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    day.localized(context),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(child: timeButton),
                                      if (deleteButton != null) ...[
                                        const SizedBox(width: 8),
                                        deleteButton,
                                      ],
                                    ],
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      day.localized(context),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  timeButton,
                                  if (deleteButton != null) deleteButton,
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

    if (updatedSchedules == null) return;
    setState(() {
      _selectedSchedules
        ..clear()
        ..addAll(updatedSchedules);
    });
  }

  Future<String?> _selectTime({TimeOfDay? initial}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initial ?? TimeOfDay.now(),
    );
    if (picked != null) {
      return '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    }
    return null;
  }

  TimeOfDay _parseTime(String? timeStr) {
    if (timeStr == null) return const TimeOfDay(hour: 10, minute: 0);
    final parts = timeStr.split(':');
    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]) ?? 10;
      final minute = int.tryParse(parts[1]) ?? 0;
      return TimeOfDay(hour: hour, minute: minute);
    }
    return const TimeOfDay(hour: 10, minute: 0);
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
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: PackageType.values.map((type) {
                          final label = type == PackageType.daily
                              ? l.packageTypeDaily
                              : l.packageTypeMonthly;
                          final selected = _selectedPackageType == type;
                          return ChoiceChip(
                            label: Text(label),
                            selected: selected,
                            onSelected: (_) {
                              setState(() {
                                _selectedPackageType = type;
                              });
                            },
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
                  onPressed: _showBulkScheduleDialog,
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
                      final time = _selectedSchedules[day]!;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8.0),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _localizedDay(context, day),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                time,
                                style: TextStyle(color: Colors.grey[700]),
                              ),
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
