/// Represents a single session schedule entry for a client.
class SessionSchedule {
  final int? id;
  final int? clientId;
  final String dayOfWeek; // Monday, Tuesday, etc.
  final String time; // HH:MM format

  SessionSchedule({
    this.id,
    this.clientId,
    required this.dayOfWeek,
    required this.time,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'dayOfWeek': dayOfWeek,
      'time': time,
    };
  }

  factory SessionSchedule.fromMap(Map<String, dynamic> map) {
    return SessionSchedule(
      id: map['id'] as int?,
      clientId: map['clientId'] as int?,
      dayOfWeek: map['dayOfWeek'] as String,
      time: map['time'] as String,
    );
  }
}

class DuplicateSessionScheduleDayException implements Exception {
  final String dayOfWeek;

  const DuplicateSessionScheduleDayException(this.dayOfWeek);
}
