import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../l10n/app_localizations.dart';
import '../models/attendance_record.dart';
import '../models/screen_preload.dart';
import '../models/session_schedule.dart';
import 'attendance_service.dart';
import 'app_language_service.dart';
import 'db/database_connection.dart';
import 'period_service.dart';
import 'repositories/user_repository.dart';
import 'screen_preload_service.dart';

class NotificationPreferences {
  final bool sessionReminderEnabled;
  final int reminderMinutesBefore;
  final bool morningPlanEnabled;
  final int morningHour;
  final int morningMinute;

  const NotificationPreferences({
    required this.sessionReminderEnabled,
    required this.reminderMinutesBefore,
    required this.morningPlanEnabled,
    required this.morningHour,
    required this.morningMinute,
  });

  const NotificationPreferences.defaults()
    : sessionReminderEnabled = false,
      reminderMinutesBefore = 30,
      morningPlanEnabled = false,
      morningHour = 8,
      morningMinute = 0;

  NotificationPreferences copyWith({
    bool? sessionReminderEnabled,
    int? reminderMinutesBefore,
    bool? morningPlanEnabled,
    int? morningHour,
    int? morningMinute,
  }) {
    return NotificationPreferences(
      sessionReminderEnabled:
          sessionReminderEnabled ?? this.sessionReminderEnabled,
      reminderMinutesBefore:
          reminderMinutesBefore ?? this.reminderMinutesBefore,
      morningPlanEnabled: morningPlanEnabled ?? this.morningPlanEnabled,
      morningHour: morningHour ?? this.morningHour,
      morningMinute: morningMinute ?? this.morningMinute,
    );
  }

  bool get hasAnyEnabled => sessionReminderEnabled || morningPlanEnabled;
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const String _sessionReminderEnabledKey =
      'notification_session_reminder_enabled';
  static const String _sessionReminderMinutesKey =
      'notification_session_reminder_minutes';
  static const String _morningPlanEnabledKey =
      'notification_morning_plan_enabled';
  static const String _morningPlanHourKey = 'notification_morning_plan_hour';
  static const String _morningPlanMinuteKey =
      'notification_morning_plan_minute';

  static const String _channelId = 'ptrainer_schedule_channel';
  static const String _channelName = 'Program notifications';
  static const String _channelDescription =
      'Reminders and daily plan notifications';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final ScreenPreloadService _screenPreloadService = ScreenPreloadService();
  final AttendanceService _attendanceService = AttendanceService();
  final PeriodService _periodService = PeriodService();
  final UserRepository _userRepository = UserRepository(sharedDatabaseProvider);
  final AppLanguageService _appLanguageService = AppLanguageService();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz_data.initializeTimeZones();
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (_) {
      // Keep default timezone if native timezone lookup fails.
    }

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _plugin.initialize(settings: initializationSettings);
    _initialized = true;
  }

  Future<NotificationPreferences> loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    return NotificationPreferences(
      sessionReminderEnabled:
          prefs.getBool(_sessionReminderEnabledKey) ?? false,
      reminderMinutesBefore: prefs.getInt(_sessionReminderMinutesKey) ?? 30,
      morningPlanEnabled: prefs.getBool(_morningPlanEnabledKey) ?? false,
      morningHour: prefs.getInt(_morningPlanHourKey) ?? 8,
      morningMinute: prefs.getInt(_morningPlanMinuteKey) ?? 0,
    );
  }

  Future<void> updatePreferences(NotificationPreferences settings) async {
    await initialize();
    if (settings.hasAnyEnabled) {
      await requestPermissions();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(
      _sessionReminderEnabledKey,
      settings.sessionReminderEnabled,
    );
    await prefs.setInt(
      _sessionReminderMinutesKey,
      settings.reminderMinutesBefore,
    );
    await prefs.setBool(_morningPlanEnabledKey, settings.morningPlanEnabled);
    await prefs.setInt(_morningPlanHourKey, settings.morningHour);
    await prefs.setInt(_morningPlanMinuteKey, settings.morningMinute);
    await rescheduleFromSavedSettings();
  }

  Future<void> requestPermissions() async {
    final androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();

    final iosPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await iosPlugin?.requestPermissions(alert: true, badge: true, sound: true);

    final macPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    await macPlugin?.requestPermissions(alert: true, badge: true, sound: true);
  }

  Future<void> rescheduleFromSavedSettings() async {
    await initialize();
    final settings = await loadPreferences();
    final userId = await _resolveUserId();

    await _plugin.cancelAll();
    if (!settings.hasAnyEnabled || userId == null) return;

    final now = DateTime.now();
    final rangeStart = DateTime(now.year, now.month, now.day);
    final rangeEnd = rangeStart.add(const Duration(days: 13));
    final preloads = await _screenPreloadService.loadWeeklyClientPreloads(
      userId: userId,
      startDate: rangeStart,
      endDate: rangeEnd,
    );
    final scheduledEvents = _buildEventsFromThisWeekLogic(
      preloads: preloads,
      startDate: rangeStart,
      endDate: rangeEnd,
    );
    if (scheduledEvents.isEmpty) return;

    final l = AppLocalizations(
      _appLanguageService.selectedLocale ?? const Locale('en'),
    );
    final notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: const DarwinNotificationDetails(),
    );

    if (settings.sessionReminderEnabled) {
      await _scheduleSessionReminders(
        now: now,
        settings: settings,
        l: l,
        scheduledEvents: scheduledEvents,
        notificationDetails: notificationDetails,
      );
    }

    if (settings.morningPlanEnabled) {
      await _scheduleMorningPlans(
        now: now,
        settings: settings,
        l: l,
        scheduledEvents: scheduledEvents,
        notificationDetails: notificationDetails,
      );
    }
  }

  Future<void> clearAllSettingsAndNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionReminderEnabledKey);
    await prefs.remove(_sessionReminderMinutesKey);
    await prefs.remove(_morningPlanEnabledKey);
    await prefs.remove(_morningPlanHourKey);
    await prefs.remove(_morningPlanMinuteKey);
    await _plugin.cancelAll();
  }

  Future<int?> _resolveUserId() async {
    final users = await _userRepository.getUsers();
    if (users.isEmpty) return null;

    final savedUsername = await SharedPreferences.getInstance().then(
      (prefs) => prefs.getString('saved_username'),
    );
    if (savedUsername == null || savedUsername.trim().isEmpty) {
      return users.first.id;
    }

    final user = users.firstWhere(
      (u) => u.username == savedUsername,
      orElse: () => users.first,
    );
    return user.id;
  }

  Future<void> _scheduleSessionReminders({
    required DateTime now,
    required NotificationPreferences settings,
    required AppLocalizations l,
    required List<_ScheduledEvent> scheduledEvents,
    required NotificationDetails notificationDetails,
  }) async {
    var nextNotificationId = 10000;
    final endDate = now.add(const Duration(days: 14));
    final reminderEvents =
        scheduledEvents
            .where((event) => event.status == LessonAttendanceStatus.pending)
            .toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));

    for (final event in reminderEvents) {
      final reminderAt = event.startTime.subtract(
        Duration(minutes: settings.reminderMinutesBefore),
      );
      if (!reminderAt.isAfter(now) || reminderAt.isAfter(endDate)) continue;

      final timeLabel = _formatHourMinute(event.startTime);
      await _plugin.zonedSchedule(
        id: nextNotificationId,
        title: l.notificationSessionReminderTitle,
        body: l.notificationSessionReminderBody(
          event.clientName,
          timeLabel,
          settings.reminderMinutesBefore,
        ),
        scheduledDate: tz.TZDateTime.from(reminderAt, tz.local),
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
      nextNotificationId++;
    }
  }

  Future<void> _scheduleMorningPlans({
    required DateTime now,
    required NotificationPreferences settings,
    required AppLocalizations l,
    required List<_ScheduledEvent> scheduledEvents,
    required NotificationDetails notificationDetails,
  }) async {
    final plannedCountByDay = <String, int>{};
    for (final event in scheduledEvents) {
      if (event.status != LessonAttendanceStatus.pending) continue;
      final key = _dayKey(event.startTime);
      plannedCountByDay[key] = (plannedCountByDay[key] ?? 0) + 1;
    }

    final baseDate = DateTime(now.year, now.month, now.day);

    for (var dayOffset = 0; dayOffset < 14; dayOffset++) {
      final day = baseDate.add(Duration(days: dayOffset));
      final fireAt = DateTime(
        day.year,
        day.month,
        day.day,
        settings.morningHour,
        settings.morningMinute,
      );
      if (!fireAt.isAfter(now)) continue;

      final sessionCount = plannedCountByDay[_dayKey(day)] ?? 0;

      final body = sessionCount == 0
          ? l.notificationMorningPlanBodyNoSessions
          : l.notificationMorningPlanBody(sessionCount);

      await _plugin.zonedSchedule(
        id: 20000 + dayOffset,
        title: l.notificationMorningPlanTitle,
        body: body,
        scheduledDate: tz.TZDateTime.from(fireAt, tz.local),
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  List<_ScheduledEvent> _buildEventsFromThisWeekLogic({
    required List<WeeklyClientPreload> preloads,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final events = <_ScheduledEvent>[];

    for (final preload in preloads) {
      final client = preload.client;
      if (!client.isActive) continue;

      final schedules = preload.schedules;
      final attendanceRecords = preload.weeklyAttendance;
      final handledLessonDays = <String>{};

      for (final attendance in attendanceRecords) {
        final lessonDate = attendance.lessonDate;
        if (_isWithinRange(
          lessonDate,
          startDate: startDate,
          endDate: endDate,
        )) {
          handledLessonDays.add(_dayKey(lessonDate!));
        }

        final placement = _resolvePlacementForRange(
          attendance: attendance,
          schedules: schedules,
          startDate: startDate,
          endDate: endDate,
        );
        if (placement == null) continue;

        final parsed = _parseTime(placement.showTime);
        if (parsed == null) continue;
        events.add(
          _ScheduledEvent(
            clientName: client.fullName,
            startTime: DateTime(
              placement.showDate.year,
              placement.showDate.month,
              placement.showDate.day,
              parsed.$1,
              parsed.$2,
            ),
            status: placement.status,
          ),
        );
      }

      for (final schedule in schedules) {
        for (final lessonDate in _lessonDatesForScheduleInRange(
          schedule: schedule,
          startDate: startDate,
          endDate: endDate,
        )) {
          final hasCoveringPeriod = preload.periods.any((period) {
            final start = DateTime.parse(period.startDate);
            final end = _periodService.effectiveEnd(period);
            return !start.isAfter(lessonDate) && !end.isBefore(lessonDate);
          });
          if (!hasCoveringPeriod) continue;

          final lessonDayKey = _dayKey(lessonDate);
          if (handledLessonDays.contains(lessonDayKey)) continue;

          final parsed = _parseTime(schedule.time);
          if (parsed == null) continue;
          events.add(
            _ScheduledEvent(
              clientName: client.fullName,
              startTime: DateTime(
                lessonDate.year,
                lessonDate.month,
                lessonDate.day,
                parsed.$1,
                parsed.$2,
              ),
              status: LessonAttendanceStatus.pending,
            ),
          );
        }
      }
    }

    return events;
  }

  AttendancePlacement? _resolvePlacementForRange({
    required AttendanceRecord attendance,
    required List<SessionSchedule> schedules,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final status = _attendanceService.resolveAttendanceStatus(attendance);
    final makeupDate = attendance.makeupDate;
    if (status == LessonAttendanceStatus.pending &&
        _isWithinRange(makeupDate, startDate: startDate, endDate: endDate)) {
      return AttendancePlacement(
        showDate: makeupDate!,
        showTime: _formatHourMinute(makeupDate),
        isMakeup: true,
        status: status,
      );
    }

    final lessonDate = attendance.lessonDate;
    if (!_isWithinRange(lessonDate, startDate: startDate, endDate: endDate)) {
      return null;
    }

    return AttendancePlacement(
      showDate: lessonDate!,
      showTime: _attendanceService.resolveScheduledTime(
        schedules: schedules,
        lessonDate: lessonDate,
      ),
      isMakeup: false,
      status: status,
    );
  }

  List<DateTime> _lessonDatesForScheduleInRange({
    required SessionSchedule schedule,
    required DateTime startDate,
    required DateTime endDate,
  }) {
    final weekday = _weekdayFromStoredValue(schedule.dayOfWeek);
    if (weekday == null) return const [];

    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day);
    final offset = (weekday - start.weekday + 7) % 7;
    var current = start.add(Duration(days: offset));

    final result = <DateTime>[];
    while (!current.isAfter(end)) {
      result.add(current);
      current = current.add(const Duration(days: 7));
    }
    return result;
  }

  bool _isWithinRange(
    DateTime? date, {
    required DateTime startDate,
    required DateTime endDate,
  }) {
    if (date == null) return false;
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
    return !date.isBefore(start) && !date.isAfter(end);
  }

  String _dayKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  int? _weekdayFromStoredValue(String value) {
    final normalized = value.trim().toLowerCase();
    const weekdayMap = <String, int>{
      'monday': DateTime.monday,
      'tuesday': DateTime.tuesday,
      'wednesday': DateTime.wednesday,
      'thursday': DateTime.thursday,
      'friday': DateTime.friday,
      'saturday': DateTime.saturday,
      'sunday': DateTime.sunday,
      'pazartesi': DateTime.monday,
      'sali': DateTime.tuesday,
      'salı': DateTime.tuesday,
      'carsamba': DateTime.wednesday,
      'çarşamba': DateTime.wednesday,
      'persembe': DateTime.thursday,
      'perşembe': DateTime.thursday,
      'cuma': DateTime.friday,
      'cumartesi': DateTime.saturday,
      'pazar': DateTime.sunday,
      'lunes': DateTime.monday,
      'martes': DateTime.tuesday,
      'miercoles': DateTime.wednesday,
      'miércoles': DateTime.wednesday,
      'jueves': DateTime.thursday,
      'viernes': DateTime.friday,
      'sabado': DateTime.saturday,
      'sábado': DateTime.saturday,
      'domingo': DateTime.sunday,
      'maandag': DateTime.monday,
      'dinsdag': DateTime.tuesday,
      'woensdag': DateTime.wednesday,
      'donderdag': DateTime.thursday,
      'vrijdag': DateTime.friday,
      'zaterdag': DateTime.saturday,
      'zondag': DateTime.sunday,
    };
    return weekdayMap[normalized];
  }

  (int, int)? _parseTime(String value) {
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
    return (hour, minute);
  }

  String _formatHourMinute(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _ScheduledEvent {
  final String clientName;
  final DateTime startTime;
  final LessonAttendanceStatus status;

  const _ScheduledEvent({
    required this.clientName,
    required this.startTime,
    required this.status,
  });
}
