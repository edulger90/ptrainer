enum LessonAttendanceStatus { pending, attended, cancelled, absent }

class AttendanceRecord {
  final int? id;
  final int? clientId;
  final int? periodId;
  final DateTime? lessonDate;
  final bool attended;
  final bool cancelled;
  final bool isPostponed;
  final DateTime? attendedDate;
  final DateTime? makeupDate;
  final int? reason;

  const AttendanceRecord({
    this.id,
    this.clientId,
    this.periodId,
    this.lessonDate,
    required this.attended,
    this.cancelled = false,
    this.isPostponed = false,
    this.attendedDate,
    this.makeupDate,
    this.reason,
  });

  bool get absent => !attended;

  factory AttendanceRecord.fromMap(Map<String, dynamic> map) {
    return AttendanceRecord(
      id: map['id'] as int?,
      clientId: map['clientId'] as int?,
      periodId: map['periodId'] as int?,
      lessonDate: _parseOptionalDate(map['lessonDate']),
      attended: _asBool(map['attended']),
      cancelled: _asBool(map['cancelled']),
      isPostponed: _asBool(map['isPostponed']),
      attendedDate: _parseOptionalDate(map['attendedDate']),
      makeupDate: _parseOptionalDate(map['makeupDate']),
      reason: map['reason'] is int
          ? map['reason'] as int
          : int.tryParse(map['reason']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'periodId': periodId,
      'lessonDate': lessonDate?.toIso8601String(),
      'attended': attended ? 1 : 0,
      'cancelled': cancelled ? 1 : 0,
      'isPostponed': isPostponed ? 1 : 0,
      'attendedDate': attendedDate?.toIso8601String(),
      'makeupDate': makeupDate?.toIso8601String(),
      'reason': reason,
    };
  }

  AttendanceRecord copyWith({
    int? id,
    int? clientId,
    int? periodId,
    DateTime? lessonDate,
    bool? attended,
    bool? cancelled,
    bool? isPostponed,
    DateTime? attendedDate,
    DateTime? makeupDate,
    int? reason,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      periodId: periodId ?? this.periodId,
      lessonDate: lessonDate ?? this.lessonDate,
      attended: attended ?? this.attended,
      cancelled: cancelled ?? this.cancelled,
      isPostponed: isPostponed ?? this.isPostponed,
      attendedDate: attendedDate ?? this.attendedDate,
      makeupDate: makeupDate ?? this.makeupDate,
      reason: reason ?? this.reason,
    );
  }

  static bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value == 1;
    return value?.toString() == '1';
  }

  static DateTime? _parseOptionalDate(dynamic value) {
    final text = value as String?;
    if (text == null || text.isEmpty) return null;
    return DateTime.tryParse(text);
  }
}

class AttendancePlacement {
  final DateTime showDate;
  final String showTime;
  final bool isMakeup;
  final LessonAttendanceStatus status;

  const AttendancePlacement({
    required this.showDate,
    required this.showTime,
    required this.isMakeup,
    required this.status,
  });
}
