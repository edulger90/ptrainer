import '../../models/body_measurement.dart';
import '../../models/client.dart';
import '../../models/query_plan_debug_entry.dart';
import '../../models/session_schedule.dart';
import 'base_repository.dart';

class ClientRepository extends BaseRepository {
  const ClientRepository(super.databaseProvider);

  Future<int> insertClient(Client client) async {
    final db = await database;
    return db.insert('clients', client.toMap());
  }

  Future<int> updateClient(Client client) async {
    final db = await database;
    return db.update(
      'clients',
      client.toMap(),
      where: 'id = ?',
      whereArgs: [client.id],
    );
  }

  Future<List<Client>> getClientsByUser(int userId) async {
    final db = await database;
    final maps = await db.query(
      'clients',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    return maps.map((map) => Client.fromMap(map)).toList();
  }

  Future<int> insertBodyMeasurement(BodyMeasurement measurement) async {
    final db = await database;
    return db.insert('body_measurements', measurement.toMap());
  }

  Future<int> updateBodyMeasurement(BodyMeasurement measurement) async {
    final db = await database;
    if (measurement.id == null) {
      throw ArgumentError('Measurement id is required for update');
    }
    return db.update(
      'body_measurements',
      measurement.toMap(),
      where: 'id = ?',
      whereArgs: [measurement.id],
    );
  }

  Future<List<BodyMeasurement>> getBodyMeasurementsByClient(
    int clientId,
  ) async {
    final db = await database;
    final maps = await db.query(
      'body_measurements',
      where: 'clientId = ?',
      whereArgs: [clientId],
      orderBy: 'date DESC',
    );
    return maps.map((map) => BodyMeasurement.fromMap(map)).toList();
  }

  Future<BodyMeasurement?> getLatestBodyMeasurement(int clientId) async {
    final db = await database;
    final maps = await db.query(
      'body_measurements',
      where: 'clientId = ?',
      whereArgs: [clientId],
      orderBy: 'date DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return BodyMeasurement.fromMap(maps.first);
  }

  Future<int> insertSessionSchedule(SessionSchedule schedule) async {
    final db = await database;
    return db.insert('session_schedules', schedule.toMap());
  }

  Future<List<SessionSchedule>> getSessionSchedulesByClient(
    int clientId,
  ) async {
    final db = await database;
    final maps = await db.query(
      'session_schedules',
      where: 'clientId = ?',
      whereArgs: [clientId],
    );
    return maps.map((map) => SessionSchedule.fromMap(map)).toList();
  }

  Future<List<SessionSchedule>> getSessionSchedulesByClientIds(
    List<int> clientIds,
  ) async {
    if (clientIds.isEmpty) return const [];
    final db = await database;
    final maps = await db.query(
      'session_schedules',
      where: 'clientId IN (${placeholders(clientIds.length)})',
      whereArgs: clientIds,
      orderBy: 'clientId ASC, dayOfWeek ASC, time ASC',
    );
    return maps.map((map) => SessionSchedule.fromMap(map)).toList();
  }

  Future<int> updateSessionSchedule(SessionSchedule schedule) async {
    final db = await database;
    return db.update(
      'session_schedules',
      schedule.toMap(),
      where: 'id = ?',
      whereArgs: [schedule.id],
    );
  }

  Future<int> deleteSessionSchedule(int scheduleId) async {
    final db = await database;
    return db.delete(
      'session_schedules',
      where: 'id = ?',
      whereArgs: [scheduleId],
    );
  }

  Future<void> toggleClientActive(int clientId, bool isActive) async {
    final db = await database;
    await db.update(
      'clients',
      {'isActive': isActive ? 1 : 0},
      where: 'id = ?',
      whereArgs: [clientId],
    );
  }

  Future<int> deleteClient(int clientId) async {
    final db = await database;
    return db.delete('clients', where: 'id = ?', whereArgs: [clientId]);
  }

  Future<List<QueryPlanDebugEntry>> getQueryPlanDiagnostics() async {
    final db = await database;
    final sampleUserId = await _sampleId(db, 'users');
    final sampleClientId = await _sampleId(db, 'clients');
    final sampleClientIds = _padIds(await _sampleIds(db, 'clients'));

    return [
      await _explain(
        db,
        label: 'Clients by user',
        sql: 'SELECT * FROM clients WHERE userId = ?',
        arguments: [sampleUserId],
      ),
      await _explain(
        db,
        label: 'Latest body measurement',
        sql:
            'SELECT * FROM body_measurements WHERE clientId = ? ORDER BY date DESC LIMIT 1',
        arguments: [sampleClientId],
      ),
      await _explain(
        db,
        label: 'Schedules by client ids',
        sql:
            'SELECT * FROM session_schedules WHERE clientId IN (?, ?, ?) ORDER BY clientId ASC, dayOfWeek ASC, time ASC',
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

  Future<int> _sampleId(dynamic db, String table) async {
    final result = await db.query(table, columns: ['id'], limit: 1);
    return (result.firstOrNull?['id'] as int?) ?? 1;
  }

  Future<List<int>> _sampleIds(dynamic db, String table) async {
    final result = await db.query(table, columns: ['id'], limit: 3);
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
