/// Represents a client (sporcu) managed by a user/trainer.
class Client {
  final int? id;
  final int? userId;
  final String fullName;
  final int sessionPackage;
  final String? createdAt;
  final String? registrationDate;

  Client({
    this.id,
    this.userId,
    required this.fullName,
    required this.sessionPackage,
    this.createdAt,
    this.registrationDate,
  });

  /// Backward-compatible helper: splits fullName for DB migration
  String get firstName {
    final parts = fullName.split(' ');
    return parts.first;
  }

  String get lastName {
    final parts = fullName.split(' ');
    return parts.length > 1 ? parts.sublist(1).join(' ') : '';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'firstName': firstName,
      'lastName': lastName,
      'sessionPackage': sessionPackage,
      'createdAt': createdAt,
      'registrationDate': registrationDate,
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    final first = map['firstName'] as String? ?? '';
    final last = map['lastName'] as String? ?? '';
    final combined = last.isEmpty ? first : '$first $last';
    return Client(
      id: map['id'] as int?,
      userId: map['userId'] as int?,
      fullName: combined,
      sessionPackage: map['sessionPackage'] as int,
      createdAt: map['createdAt'] as String?,
      registrationDate: map['registrationDate'] as String?,
    );
  }

  Client copyWith({
    int? id,
    int? userId,
    String? fullName,
    int? sessionPackage,
    String? createdAt,
    String? registrationDate,
  }) {
    return Client(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      sessionPackage: sessionPackage ?? this.sessionPackage,
      createdAt: createdAt ?? this.createdAt,
      registrationDate: registrationDate ?? this.registrationDate,
    );
  }
}
