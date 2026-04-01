import '../../models/period.dart';
import '../../models/query_plan_debug_entry.dart';
import 'base_repository.dart';

class PeriodRepository extends BaseRepository {
  const PeriodRepository(super.databaseProvider);

  Future<int> insertPeriod(Period period) async {
    final db = await database;
    return db.insert('periods', period.toMap());
  }

  Future<int> updatePeriod(Period period) async {
    final db = await database;
    return db.update(
      'periods',
      period.toMap(),
      where: 'id = ?',
      whereArgs: [period.id],
    );
  }

  Future<int> updatePeriodPostponedEndDate(
    int periodId,
    String? postponedEndDate,
  ) async {
    final db = await database;
    return db.update(
      'periods',
      {'postponedEndDate': postponedEndDate},
      where: 'id = ?',
      whereArgs: [periodId],
    );
  }

  Future<Period?> getLatestPeriodForClient(int clientId) async {
    final db = await database;
    final maps = await db.query(
      'periods',
      where: 'clientId = ?',
      whereArgs: [clientId],
      orderBy: 'startDate DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Period.fromMap(maps.first);
  }

  Future<Period?> getPeriodById(int periodId) async {
    final db = await database;
    final maps = await db.query(
      'periods',
      where: 'id = ?',
      whereArgs: [periodId],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Period.fromMap(maps.first);
  }

  Future<List<Period>> getPeriodsByClient(int clientId) async {
    final db = await database;
    final maps = await db.query(
      'periods',
      where: 'clientId = ?',
      whereArgs: [clientId],
      orderBy: 'startDate DESC',
    );
    return maps.map((map) => Period.fromMap(map)).toList();
  }

  Future<List<Period>> getPeriodsByClientIds(List<int> clientIds) async {
    if (clientIds.isEmpty) return const [];
    final db = await database;
    final maps = await db.query(
      'periods',
      where: 'clientId IN (${placeholders(clientIds.length)})',
      whereArgs: clientIds,
      orderBy: 'clientId ASC, startDate DESC',
    );
    return maps.map((map) => Period.fromMap(map)).toList();
  }

  Future<List<QueryPlanDebugEntry>> getQueryPlanDiagnostics() async {
    final db = await database;
    final sampleClientIds = _padIds(await _sampleIds(db));

    return [
      await _explain(
        db,
        label: 'Periods by client ids',
        sql:
            'SELECT * FROM periods WHERE clientId IN (?, ?, ?) ORDER BY clientId ASC, startDate DESC',
        arguments: sampleClientIds,
      ),
    ];
  }

  Future<QueryPlanDebugEntry> _explain(
    dynamic db, {
    required String label,
    required String sql,
    required List<Object?> arguments,
  }) async {
    final result = await db.rawQuery('EXPLAIN QUERY PLAN $sql', arguments);
    return QueryPlanDebugEntry(
      label: label,
      sql: sql,
      arguments: arguments,
      details: result.map<String>((row) => row['detail'].toString()).toList(),
    );
  }

  Future<List<int>> _sampleIds(dynamic db) async {
    final result = await db.query('clients', columns: ['id'], limit: 3);
    return result.map<int>((row) => row['id'] as int).toList();
  }

  List<int> _padIds(List<int> ids) {
    final values = List<int>.from(ids);
    while (values.length < 3) {
      values.add(values.isEmpty ? 1 : values.last);
    }
    return values.take(3).toList();
  }
}
