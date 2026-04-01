import '../models/attendance_record.dart';
import '../models/client.dart';
import '../models/period.dart';
import '../models/screen_preload.dart';
import '../models/session_schedule.dart';
import 'attendance_service.dart';
import 'db/database_connection.dart';
import 'period_service.dart';
import 'repositories/attendance_repository.dart';
import 'repositories/client_repository.dart';
import 'repositories/period_repository.dart';

class ScreenPreloadService {
  static final ScreenPreloadService _instance = ScreenPreloadService._internal(
    clientRepository: ClientRepository(sharedDatabaseProvider),
    periodRepository: PeriodRepository(sharedDatabaseProvider),
    attendanceRepository: AttendanceRepository(sharedDatabaseProvider),
  );

  factory ScreenPreloadService({
    ClientRepository? clientRepository,
    PeriodRepository? periodRepository,
    AttendanceRepository? attendanceRepository,
    AttendanceService? attendanceService,
    PeriodService? periodService,
  }) {
    if (clientRepository == null &&
        periodRepository == null &&
        attendanceRepository == null &&
        attendanceService == null &&
        periodService == null) {
      return _instance;
    }

    return ScreenPreloadService._internal(
      clientRepository:
          clientRepository ?? ClientRepository(sharedDatabaseProvider),
      periodRepository:
          periodRepository ?? PeriodRepository(sharedDatabaseProvider),
      attendanceRepository:
          attendanceRepository ?? AttendanceRepository(sharedDatabaseProvider),
      attendanceService: attendanceService,
      periodService: periodService,
    );
  }

  ScreenPreloadService._internal({
    required ClientRepository clientRepository,
    required PeriodRepository periodRepository,
    required AttendanceRepository attendanceRepository,
    AttendanceService? attendanceService,
    PeriodService? periodService,
  }) : _clientRepository = clientRepository,
       _periodRepository = periodRepository,
       _attendanceRepository = attendanceRepository,
       _attendanceService = attendanceService ?? AttendanceService(),
       _periodService = periodService ?? PeriodService();

  final ClientRepository _clientRepository;
  final PeriodRepository _periodRepository;
  final AttendanceRepository _attendanceRepository;
  final AttendanceService _attendanceService;
  final PeriodService _periodService;

  Future<List<WeeklyClientPreload>> loadWeeklyClientPreloads({
    required int userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final clients = await _clientRepository.getClientsByUser(userId);
    final clientIds = clients
        .map((client) => client.id)
        .whereType<int>()
        .toList();
    if (clientIds.isEmpty) return const [];

    final schedulesFuture = _clientRepository.getSessionSchedulesByClientIds(
      clientIds,
    );
    final periodsFuture = _periodRepository.getPeriodsByClientIds(clientIds);
    final weeklyAttendanceFuture = _attendanceRepository
        .getAttendanceRecordsForClientIdsInRange(
          clientIds: clientIds,
          startDate: startDate,
          endDate: endDate,
        );

    final schedules = await schedulesFuture;
    final periods = await periodsFuture;
    final weeklyAttendance = await weeklyAttendanceFuture;

    final schedulesByClientId = <int, List<SessionSchedule>>{};
    for (final schedule in schedules) {
      final clientId = schedule.clientId;
      if (clientId == null) continue;
      schedulesByClientId.putIfAbsent(clientId, () => []).add(schedule);
    }

    final periodsByClientId = <int, List<Period>>{};
    for (final period in periods) {
      final clientId = period.clientId;
      if (clientId == null) continue;
      periodsByClientId.putIfAbsent(clientId, () => []).add(period);
    }

    final weeklyAttendanceByClientId = <int, List<AttendanceRecord>>{};
    for (final attendance in weeklyAttendance) {
      final clientId = attendance.clientId;
      if (clientId == null) continue;
      weeklyAttendanceByClientId
          .putIfAbsent(clientId, () => [])
          .add(attendance);
    }

    final relevantPeriodIdsByClientId = <int, int>{};
    for (final client in clients) {
      final clientId = client.id;
      if (clientId == null) continue;
      final clientPeriods = periodsByClientId[clientId] ?? const <Period>[];
      final active = _periodService.findActivePeriod(clientPeriods);
      final last = _periodService.findLastPeriod(clientPeriods);
      final relevantPeriodId = active.period?.id ?? last.period?.id;
      if (relevantPeriodId != null) {
        relevantPeriodIdsByClientId[clientId] = relevantPeriodId;
      }
    }

    final relevantPeriodIds = relevantPeriodIdsByClientId.values
        .toSet()
        .toList();
    final relevantPeriodAttendance = relevantPeriodIds.isEmpty
        ? const <AttendanceRecord>[]
        : await _attendanceRepository.getAttendanceRecordsForPeriodIds(
            relevantPeriodIds,
          );

    final relevantAttendanceByPeriodId = <int, List<AttendanceRecord>>{};
    for (final attendance in relevantPeriodAttendance) {
      final periodId = attendance.periodId;
      if (periodId == null) continue;
      relevantAttendanceByPeriodId
          .putIfAbsent(periodId, () => [])
          .add(attendance);
    }

    return clients.where((client) => client.id != null).map((client) {
      final clientId = client.id!;
      final relevantPeriodId = relevantPeriodIdsByClientId[clientId];
      return WeeklyClientPreload(
        client: client,
        schedules: schedulesByClientId[clientId] ?? const <SessionSchedule>[],
        periods: periodsByClientId[clientId] ?? const <Period>[],
        weeklyAttendance:
            weeklyAttendanceByClientId[clientId] ?? const <AttendanceRecord>[],
        relevantPeriodAttendance: relevantPeriodId == null
            ? const <AttendanceRecord>[]
            : (relevantAttendanceByPeriodId[relevantPeriodId] ??
                  const <AttendanceRecord>[]),
      );
    }).toList();
  }

  Future<ClientDetailPreload> loadClientDetailPreload({
    required Client client,
  }) async {
    final clientId = client.id;
    if (clientId == null) {
      return ClientDetailPreload(
        client: client,
        periods: const [],
        schedules: const [],
        measurements: const [],
        completedLessonsByPeriodId: const {},
      );
    }

    final periodsFuture = _periodRepository.getPeriodsByClient(clientId);
    final schedulesFuture = _clientRepository.getSessionSchedulesByClient(
      clientId,
    );
    final measurementsFuture = _clientRepository.getBodyMeasurementsByClient(
      clientId,
    );

    final periods = await periodsFuture;
    final schedules = await schedulesFuture;
    final measurements = await measurementsFuture;

    final periodIds = periods
        .map((period) => period.id)
        .whereType<int>()
        .toList();
    final attendanceRecords = periodIds.isEmpty
        ? const <AttendanceRecord>[]
        : await _attendanceRepository.getAttendanceRecordsForPeriodIds(
            periodIds,
          );

    final attendanceByPeriodId = <int, List<AttendanceRecord>>{};
    for (final attendance in attendanceRecords) {
      final periodId = attendance.periodId;
      if (periodId == null) continue;
      attendanceByPeriodId.putIfAbsent(periodId, () => []).add(attendance);
    }

    final completedLessonsByPeriodId = <int, int>{};
    for (final period in periods) {
      final periodId = period.id;
      if (periodId == null) continue;
      completedLessonsByPeriodId[periodId] = _attendanceService
          .completedLessonCount(attendanceByPeriodId[periodId] ?? const []);
    }

    return ClientDetailPreload(
      client: client,
      periods: periods,
      schedules: schedules,
      measurements: measurements,
      completedLessonsByPeriodId: completedLessonsByPeriodId,
    );
  }

  Future<List<ClientListItemPreload>> loadClientListPreloads({
    required int userId,
  }) async {
    final clients = await _clientRepository.getClientsByUser(userId);
    final clientIds = clients
        .map((client) => client.id)
        .whereType<int>()
        .toList();
    if (clientIds.isEmpty) return const [];

    final periods = await _periodRepository.getPeriodsByClientIds(clientIds);
    final periodsByClientId = <int, List<Period>>{};
    for (final period in periods) {
      final clientId = period.clientId;
      if (clientId == null) continue;
      periodsByClientId.putIfAbsent(clientId, () => []).add(period);
    }

    final latestPeriodByClientId = <int, Period>{};
    for (final client in clients) {
      final clientId = client.id;
      if (clientId == null) continue;
      final clientPeriods = periodsByClientId[clientId] ?? const <Period>[];
      final last = _periodService.findLastPeriod(clientPeriods);
      if (last.period != null && last.period!.id != null) {
        latestPeriodByClientId[clientId] = last.period!;
      }
    }

    final latestPeriodIds = latestPeriodByClientId.values
        .map((period) => period.id)
        .whereType<int>()
        .toList();
    final attendanceRecords = latestPeriodIds.isEmpty
        ? const <AttendanceRecord>[]
        : await _attendanceRepository.getAttendanceRecordsForPeriodIds(
            latestPeriodIds,
          );

    final attendanceByPeriodId = <int, List<AttendanceRecord>>{};
    for (final attendance in attendanceRecords) {
      final periodId = attendance.periodId;
      if (periodId == null) continue;
      attendanceByPeriodId.putIfAbsent(periodId, () => []).add(attendance);
    }

    return clients.where((client) => client.id != null).map((client) {
      final clientId = client.id!;
      final latestPeriod = latestPeriodByClientId[clientId];
      final completedLessons = latestPeriod?.id == null
          ? 0
          : _attendanceService.completedLessonCount(
              attendanceByPeriodId[latestPeriod!.id!] ?? const [],
            );
      return ClientListItemPreload(
        client: client,
        latestPeriod: latestPeriod,
        completedLessons: completedLessons,
      );
    }).toList();
  }

  Future<PeriodCalendarPreload?> loadPeriodCalendarPreload({
    required int clientId,
    required int periodId,
  }) async {
    final periodFuture = _periodRepository.getPeriodById(periodId);
    final attendanceFuture = _attendanceRepository
        .getAttendanceRecordsForPeriod(clientId, periodId);

    final period = await periodFuture;
    if (period == null) return null;

    final attendanceRecords = await attendanceFuture;
    return PeriodCalendarPreload(
      period: period,
      attendanceRecords: attendanceRecords,
    );
  }
}
