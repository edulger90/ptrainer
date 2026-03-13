/// Represents a single body measurement record taken on a specific date.
class BodyMeasurement {
  final int? id;
  final int? clientId;
  final DateTime date;
  final double? chest;
  final double? waist;
  final double? hips;

  BodyMeasurement({
    this.id,
    this.clientId,
    required this.date,
    this.chest,
    this.waist,
    this.hips,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'date': date.toIso8601String(),
      'chest': chest,
      'waist': waist,
      'hips': hips,
    };
  }

  factory BodyMeasurement.fromMap(Map<String, dynamic> map) {
    return BodyMeasurement(
      id: map['id'] as int?,
      clientId: map['clientId'] as int?,
      date: DateTime.parse(map['date'] as String),
      chest: map['chest'] as double?,
      waist: map['waist'] as double?,
      hips: map['hips'] as double?,
    );
  }
}
