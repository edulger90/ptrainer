import '../../models/attendance_record.dart';
import '../../models/query_plan_debug_entry.dart';
import 'base_repository.dart';

class AttendanceRepository extends BaseRepository {
  const AttendanceRepository(super.databaseProvider);

  Future<void> upsertAttendance({
    required int clientId,
    required int periodId,
    required DateTime lessonDate,
    required bool attended,
    bool cancelled = false,
    bool isPostponed = false,
    DateTime? attendedDate,
    DateTime? makeupDate,
    int? reason,
  }) async {
    final db = await database;
    final normalizedLessonDate = _normalizeLessonDay(lessonDate);
    final lessonDateStr = normalizedLessonDate.toIso8601String();
    final attendedDateStr = attendedDate?.toIso8601String();
    final makeupDateStr = makeupDate?.toIso8601String();

    final existing = await _findAttendanceRowsForLessonDay(
      db,
      clientId: clientId,
      periodId: periodId,
      lessonDate: normalizedLessonDate,
    );
    if (existing.isNotEmpty) {
      await db.update(
        'attendances',
        {
          'lessonDate': lessonDateStr,
          'attended': attended ? 1 : 0,
          'cancelled': cancelled ? 1 : 0,
          'isPostponed': isPostponed ? 1 : 0,
          'attendedDate': attendedDateStr,
          'makeupDate': makeupDateStr,
          'reason': reason,
        },
        where: 'id = ?',
        whereArgs: [existing.first['id']],
      );
      if (existing.length > 1) {
        await _deleteDuplicateAttendanceRows(db, existing.skip(1));
      }
      return;
    }

    await db.insert('attendances', {
      'clientId': clientId,
      'periodId': periodId,
      'lessonDate': lessonDateStr,
      'attended': attended ? 1 : 0,
      'cancelled': cancelled ? 1 : 0,
      'isPostponed': isPostponed ? 1 : 0,
      'attendedDate': attendedDateStr,
      'makeupDate': makeupDateStr,
      'reason': reason,
    });
  }

  Future<int> deleteAttendance({
    required int clientId,
    required int periodId,
    required DateTime lessonDate,
  }) async {
    final db = await database;
    final bounds = _lessonDayBounds(lessonDate);
    return db.delete(
      'attendances',
      where:
          'clientId = ? AND periodId = ? AND lessonDate >= ? AND lessonDate <= ?',
      whereArgs: [
        clientId,
        periodId,
        bounds.start.toIso8601String(),
        bounds.end.toIso8601String(),
      ],
    );
  }

  Future<List<AttendanceRecord>> getAttendanceRecordsForPeriod(
    int clientId,
    int periodId,
  ) async {
    final db = await database;
    final records = await db.query(
      'attendances',
      where: 'clientId = ? AND periodId = ?',
      whereArgs: [clientId, periodId],
      orderBy: 'lessonDate ASC, makeupDate ASC, id ASC',
    );
    return _dedupeAttendanceRecords(records.map(AttendanceRecord.fromMap));
  }

  Future<List<AttendanceRecord>> getAttendanceRecordsForPeriodIds(
    List<int> periodIds,
  ) async {
    if (periodIds.isEmpty) return const [];
    final db = await database;
    final records = await db.query(
      'attendances',
      where: 'periodId IN (${placeholders(periodIds.length)})',
      whereArgs: periodIds,
      orderBy: 'periodId ASC, lessonDate ASC, makeupDate ASC, id ASC',
    );
    return _dedupeAttendanceRecords(records.map(AttendanceRecord.fromMap));
  }

  Future<List<AttendanceRecord>> getAttendanceRecordsForClientInRange({
    required int clientId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final db = await database;
    final normalizedStart = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    ).toIso8601String();
    final normalizedEnd = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      23,
      59,
      59,
      999,
    ).toIso8601String();

    final records = await db.query(
      'attendances',
      where:
          'clientId = ? AND '
          '((lessonDate >= ? AND lessonDate <= ?) '
          'OR (makeupDate IS NOT NULL AND makeupDate != "" AND makeupDate >= ? AND makeupDate <= ?))',
      whereArgs: [
        clientId,
        normalizedStart,
        normalizedEnd,
        normalizedStart,
        normalizedEnd,
      ],
      orderBy: 'lessonDate ASC, makeupDate ASC, id ASC',
    );
    return _dedupeAttendanceRecords(records.map(AttendanceRecord.fromMap));
  }

  Future<List<AttendanceRecord>> getAttendanceRecordsForClientIdsInRange({
    required List<int> clientIds,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (clientIds.isEmpty) return const [];
    final db = await database;
    final normalizedStart = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    ).toIso8601String();
    final normalizedEnd = DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
      23,
      59,
      59,
      999,
    ).toIso8601String();

    final records = await db.query(
      'attendances',
      where:
          'clientId IN (${placeholders(clientIds.length)}) AND '
          '((lessonDate >= ? AND lessonDate <= ?) '
          'OR (makeupDate IS NOT NULL AND makeupDate != "" AND makeupDate >= ? AND makeupDate <= ?))',
      whereArgs: [
        ...clientIds,
        normalizedStart,
        normalizedEnd,
        normalizedStart,
        normalizedEnd,
      ],
      orderBy: 'clientId ASC, lessonDate ASC, makeupDate ASC, id ASC',
    );
    return _dedupeAttendanceRecords(records.map(AttendanceRecord.fromMap));
  }

  Future<List<QueryPlanDebugEntry>> getQueryPlanDiagnostics() async {
    final db = await database;
    final sampleClientIds = _padIds(await _sampleIds(db, 'clients'));
    final samplePeriodIds = _padIds(await _sampleIds(db, 'periods'));
    final sampleClientId = sampleClientIds.first;
    final samplePeriodId = samplePeriodIds.first;
    final now = DateTime.now();
    final startDate = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 7)).toIso8601String();
    final endDate = DateTime(
      now.year,
      now.month,
      now.day,
      23,
      59,
      59,
      999,
    ).add(const Duration(days: 7)).toIso8601String();
    final lessonDate = DateTime(now.year, now.month, now.day).toIso8601String();

    return [
      await _explain(
        db,
        label: 'Attendance existence check',
        sql:
            'SELECT * FROM attendances WHERE clientId = ? AND periodId = ? AND lessonDate = ?',
        arguments: [sampleClientId, samplePeriodId, lessonDate],
      ),
      await _explain(
        db,
        label: 'Attendance by client and period',
        sql:
            'SELECT * FROM attendances WHERE clientId = ? AND periodId = ? ORDER BY lessonDate ASC, makeupDate ASC',
        arguments: [sampleClientId, samplePeriodId],
      ),
      await _explain(
        db,
        label: 'Attendance by period ids',
        sql:
            'SELECT * FROM attendances WHERE periodId IN (?, ?, ?) ORDER BY periodId ASC, lessonDate ASC, makeupDate ASC',
        arguments: samplePeriodIds,
      ),
      await _explain(
        db,
        label: 'Attendance by client ids in range',
        sql:
            'SELECT * FROM attendances WHERE clientId IN (?, ?, ?) AND ((lessonDate >= ? AND lessonDate <= ?) OR (makeupDate IS NOT NULL AND makeupDate != "" AND makeupDate >= ? AND makeupDate <= ?)) ORDER BY clientId ASC, lessonDate ASC, makeupDate ASC',
        arguments: [...sampleClientIds, startDate, endDate, startDate, endDate],
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

  DateTime _normalizeLessonDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  ({DateTime start, DateTime end}) _lessonDayBounds(DateTime date) {
    final start = _normalizeLessonDay(date);
    final end = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
    return (start: start, end: end);
  }

  Future<List<Map<String, Object?>>> _findAttendanceRowsForLessonDay(
    dynamic db, {
    required int clientId,
    required int periodId,
    required DateTime lessonDate,
  }) async {
    final bounds = _lessonDayBounds(lessonDate);
    final rows = await db.query(
      'attendances',
      where:
          'clientId = ? AND periodId = ? AND lessonDate >= ? AND lessonDate <= ?',
      whereArgs: [
        clientId,
        periodId,
        bounds.start.toIso8601String(),
        bounds.end.toIso8601String(),
      ],
      orderBy: 'id ASC',
    );
    return rows.cast<Map<String, Object?>>();
  }

  Future<void> _deleteDuplicateAttendanceRows(
    dynamic db,
    Iterable<Map<String, Object?>> rows,
  ) async {
    final duplicateIds = rows.map((row) => row['id']).whereType<int>().toList();
    if (duplicateIds.isEmpty) return;
    await db.delete(
      'attendances',
      where: 'id IN (${placeholders(duplicateIds.length)})',
      whereArgs: duplicateIds,
    );
  }

  List<AttendanceRecord> _dedupeAttendanceRecords(
    Iterable<AttendanceRecord> records,
  ) {
    final deduped = <String, AttendanceRecord>{};
    for (final record in records) {
      final lessonDate = record.lessonDate;
      if (lessonDate == null) continue;
      final normalizedLessonDate = _normalizeLessonDay(lessonDate);
      final key =
          '${record.clientId ?? 0}:${record.periodId ?? 0}:${normalizedLessonDate.toIso8601String()}';
      deduped[key] = record.copyWith(lessonDate: normalizedLessonDate);
    }
    return deduped.values.toList();
  }
}
