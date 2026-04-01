import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/query_plan_debug_entry.dart';
import '../services/database.dart';

class QueryPlanDebugPage extends StatefulWidget {
  const QueryPlanDebugPage({super.key});

  @override
  State<QueryPlanDebugPage> createState() => _QueryPlanDebugPageState();
}

class _QueryPlanDebugPageState extends State<QueryPlanDebugPage> {
  final _db = AppDatabase();
  List<QueryPlanDebugEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    setState(() => _loading = true);
    try {
      final entries = await _db.getQueryPlanDiagnostics();
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _entries = [];
        _loading = false;
      });
    }
  }

  Future<void> _copyReport() async {
    final buffer = StringBuffer();
    for (final entry in _entries) {
      buffer.writeln('## ${entry.label}');
      buffer.writeln(entry.sql);
      buffer.writeln('args: ${entry.arguments}');
      for (final detail in entry.details) {
        buffer.writeln('- $detail');
      }
      buffer.writeln();
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Query plan report copied')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Query Plan Debug'),
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_all_outlined),
            onPressed: _entries.isEmpty ? null : _copyReport,
            tooltip: 'Copy report',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPlans,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
          ? const Center(child: Text('No query plan data available'))
          : RefreshIndicator(
              onRefresh: _loadPlans,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _entries.length,
                itemBuilder: (context, index) {
                  final entry = _entries[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  entry.label,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: entry.usesIndex
                                      ? Colors.green.withValues(alpha: 0.12)
                                      : Colors.orange.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  entry.usesIndex ? 'INDEX' : 'SCAN',
                                  style: TextStyle(
                                    color: entry.usesIndex
                                        ? Colors.green[700]
                                        : Colors.orange[800],
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          SelectableText(
                            entry.sql,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[800],
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 6),
                          SelectableText(
                            'args: ${entry.arguments}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...entry.details.map(
                            (detail) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: SelectableText(
                                detail,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: detail.toUpperCase().contains('INDEX')
                                      ? Colors.green[800]
                                      : Colors.grey[700],
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
