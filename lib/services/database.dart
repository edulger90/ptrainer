import 'package:sqflite/sqflite.dart';
import 'dart:async';

import '../models/attendance_record.dart';
import '../models/body_measurement.dart';
import '../models/client.dart';
import '../models/period.dart';
import '../models/query_plan_debug_entry.dart';
import '../models/session_schedule.dart';
import '../models/user.dart';
import 'db/database_connection.dart';
import 'notification_service.dart';
import 'repositories/attendance_repository.dart';
import 'repositories/client_repository.dart';
import 'repositories/period_repository.dart';
import 'repositories/user_repository.dart';

class AppDatabase {
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal();

  final _connection = AppDatabaseConnection();

  late final UserRepository _users = UserRepository(sharedDatabaseProvider);
  late final ClientRepository _clients = ClientRepository(
    sharedDatabaseProvider,
  );
  late final PeriodRepository _periods = PeriodRepository(
    sharedDatabaseProvider,
  );
  late final AttendanceRepository _attendances = AttendanceRepository(
    sharedDatabaseProvider,
  );

  Future<Database> get database => _connection.database;

  static (String hash, String salt) hashPassword(String password) {
    return UserRepository.hashPassword(password);
  }

  void _triggerNotificationReschedule() {
    unawaited(_rescheduleNotificationsSafely());
  }

  Future<void> _rescheduleNotificationsSafely() async {
    try {
      await NotificationService.instance.rescheduleFromSavedSettings();
    } catch (_) {
      // Notification update failures should never block data writes.
    }
  }

  Future<int> insertUser(User user) => _users.insertUser(user);

  Future<List<User>> getUsers() => _users.getUsers();

  Future<User?> authenticate(String username, String password) {
    return _users.authenticate(username, password);
  }

  Future<bool> userExists() => _users.userExists();

  Future<int> insertClient(Client client) async {
    final id = await _clients.insertClient(client);
    _triggerNotificationReschedule();
    return id;
  }

  Future<int> updateClient(Client client) async {
    final updated = await _clients.updateClient(client);
    _triggerNotificationReschedule();
    return updated;
  }

  Future<List<Client>> getClientsByUser(int userId) {
    return _clients.getClientsByUser(userId);
  }

  Future<int> insertBodyMeasurement(BodyMeasurement measurement) {
    return _clients.insertBodyMeasurement(measurement);
  }

  Future<int> updateBodyMeasurement(BodyMeasurement measurement) {
    return _clients.updateBodyMeasurement(measurement);
  }

  Future<List<BodyMeasurement>> getBodyMeasurementsByClient(int clientId) {
    return _clients.getBodyMeasurementsByClient(clientId);
  }

  Future<BodyMeasurement?> getLatestBodyMeasurement(int clientId) {
    return _clients.getLatestBodyMeasurement(clientId);
  }

  Future<int> insertSessionSchedule(SessionSchedule schedule) {
    return _clients.insertSessionSchedule(schedule).then((id) {
      _triggerNotificationReschedule();
      return id;
    });
  }

  Future<List<SessionSchedule>> getSessionSchedulesByClient(int clientId) {
    return _clients.getSessionSchedulesByClient(clientId);
  }

  Future<List<SessionSchedule>> getSessionSchedulesByClientIds(
    List<int> clientIds,
  ) {
    return _clients.getSessionSchedulesByClientIds(clientIds);
  }

  Future<int> updateSessionSchedule(SessionSchedule schedule) {
    return _clients.updateSessionSchedule(schedule).then((updated) {
      _triggerNotificationReschedule();
      return updated;
    });
  }

  Future<int> deleteSessionSchedule(int scheduleId) {
    return _clients.deleteSessionSchedule(scheduleId).then((deleted) {
      _triggerNotificationReschedule();
      return deleted;
    });
  }

  Future<void> toggleClientActive(int clientId, bool isActive) async {
    await _clients.toggleClientActive(clientId, isActive);
    _triggerNotificationReschedule();
  }

  Future<int> deleteClient(int clientId) async {
    final deleted = await _clients.deleteClient(clientId);
    _triggerNotificationReschedule();
    return deleted;
  }

  Future<int> insertPeriod(Period period) async {
    final id = await _periods.insertPeriod(period);
    _triggerNotificationReschedule();
    return id;
  }

  Future<int> updatePeriod(Period period) async {
    final updated = await _periods.updatePeriod(period);
    _triggerNotificationReschedule();
    return updated;
  }

  Future<int> updatePeriodPostponedEndDate(
    int periodId,
    String? postponedEndDate,
  ) async {
    final updated = await _periods.updatePeriodPostponedEndDate(
      periodId,
      postponedEndDate,
    );
    _triggerNotificationReschedule();
    return updated;
  }

  Future<Period?> getLatestPeriodForClient(int clientId) {
    return _periods.getLatestPeriodForClient(clientId);
  }

  Future<Period?> getPeriodById(int periodId) =>
      _periods.getPeriodById(periodId);

  Future<List<Period>> getPeriodsByClient(int clientId) {
    return _periods.getPeriodsByClient(clientId);
  }

  Future<List<Period>> getPeriodsByClientIds(List<int> clientIds) {
    return _periods.getPeriodsByClientIds(clientIds);
  }

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
    String? reasonNote,
  }) async {
    await _attendances.upsertAttendance(
      clientId: clientId,
      periodId: periodId,
      lessonDate: lessonDate,
      attended: attended,
      cancelled: cancelled,
      isPostponed: isPostponed,
      attendedDate: attendedDate,
      makeupDate: makeupDate,
      reason: reason,
      reasonNote: reasonNote,
    );
    _triggerNotificationReschedule();
  }

  Future<int> deleteAttendance({
    required int clientId,
    required int periodId,
    required DateTime lessonDate,
  }) async {
    final deleted = await _attendances.deleteAttendance(
      clientId: clientId,
      periodId: periodId,
      lessonDate: lessonDate,
    );
    _triggerNotificationReschedule();
    return deleted;
  }

  @Deprecated(
    'Use getAttendanceRecordsForPeriod instead. Map-based attendance access is legacy.',
  )
  Future<Map<DateTime, Map<String, dynamic>>> getAttendanceForPeriod(
    int clientId,
    int periodId,
  ) async {
    final records = await getAttendanceRecordsForPeriod(clientId, periodId);
    final result = <DateTime, Map<String, dynamic>>{};
    for (final record in records) {
      final lessonDate = record.lessonDate;
      if (lessonDate == null) continue;
      result[lessonDate] = record.toMap();
    }
    return result;
  }

  Future<List<AttendanceRecord>> getAttendanceRecordsForPeriod(
    int clientId,
    int periodId,
  ) {
    return _attendances.getAttendanceRecordsForPeriod(clientId, periodId);
  }

  Future<List<AttendanceRecord>> getAttendanceRecordsForPeriodIds(
    List<int> periodIds,
  ) {
    return _attendances.getAttendanceRecordsForPeriodIds(periodIds);
  }

  @Deprecated(
    'Use getAttendanceRecordsForClientInRange instead. Map-based attendance access is legacy.',
  )
  Future<List<Map<String, dynamic>>> getAttendanceForClientInRange({
    required int clientId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final records = await getAttendanceRecordsForClientInRange(
      clientId: clientId,
      startDate: startDate,
      endDate: endDate,
    );
    return records.map((record) => record.toMap()).toList();
  }

  Future<List<AttendanceRecord>> getAttendanceRecordsForClientInRange({
    required int clientId,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _attendances.getAttendanceRecordsForClientInRange(
      clientId: clientId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<List<AttendanceRecord>> getAttendanceRecordsForClientIdsInRange({
    required List<int> clientIds,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _attendances.getAttendanceRecordsForClientIdsInRange(
      clientIds: clientIds,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<List<QueryPlanDebugEntry>> getQueryPlanDiagnostics() async {
    return [
      ...await _clients.getQueryPlanDiagnostics(),
      ...await _periods.getQueryPlanDiagnostics(),
      ...await _attendances.getQueryPlanDiagnostics(),
    ];
  }

  Future<void> deleteAllData() async {
    await _connection.deleteAllData();
    _triggerNotificationReschedule();
  }
}
