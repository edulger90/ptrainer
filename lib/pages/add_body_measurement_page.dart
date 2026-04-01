import 'package:flutter/material.dart';
import '../models/client.dart';
import '../models/body_measurement.dart';
import '../pages/auth_page.dart';
import '../services/database.dart';
import '../widgets/app_background.dart';
import '../l10n/app_localizations.dart';

class AddBodyMeasurementPage extends StatefulWidget {
  final Client client;
  const AddBodyMeasurementPage({super.key, required this.client});

  @override
  State<AddBodyMeasurementPage> createState() => _AddBodyMeasurementPageState();
}

class _AddBodyMeasurementPageState extends State<AddBodyMeasurementPage> {
  final _chestController = TextEditingController();
  final _waistController = TextEditingController();
  final _hipsController = TextEditingController();
  final _db = AppDatabase();

  late DateTime _selectedDate;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveMeasurement() async {
    double? chest, waist, hips;

    if (_chestController.text.isNotEmpty) {
      chest = double.tryParse(_chestController.text);
    }
    if (_waistController.text.isNotEmpty) {
      waist = double.tryParse(_waistController.text);
    }
    if (_hipsController.text.isNotEmpty) {
      hips = double.tryParse(_hipsController.text);
    }

    if (chest == null && waist == null && hips == null) {
      setState(() {
        _error = AppLocalizations.of(context).atLeastOneMeasurement;
      });
      return;
    }

    final measurement = BodyMeasurement(
      clientId: widget.client.id,
      date: _selectedDate,
      chest: chest,
      waist: waist,
      hips: hips,
    );

    await _db.insertBodyMeasurement(measurement);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(l.addMeasurement),
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
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.selectDate,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${_selectedDate.day.toString().padLeft(2, '0')}.'
                                '${_selectedDate.month.toString().padLeft(2, '0')}.'
                                '${_selectedDate.year}',
                                style: const TextStyle(fontSize: 16),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () => _selectDate(context),
                              child: Text(l.selectDate),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l.measurementSection,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _chestController,
                  decoration: InputDecoration(
                    labelText: l.chest,
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _waistController,
                  decoration: InputDecoration(
                    labelText: l.waist,
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _hipsController,
                  decoration: InputDecoration(
                    labelText: l.hips,
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saveMeasurement,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(l.saveMeasurement),
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
