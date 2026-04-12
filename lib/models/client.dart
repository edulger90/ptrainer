import 'package_type.dart';
import 'program_type.dart';

/// Represents a client (sporcu) managed by a user/trainer.
class Client {
  final int? id;
  final int? userId;
  final String fullName;

  /// Number of sessions in a package (only relevant for [PackageType.daily]).
  final int? sessionPackage;
  final PackageType packageType;
  final ProgramType programType;
  final String? createdAt;
  final String? registrationDate;
  final bool isActive;

  Client({
    this.id,
    this.userId,
    required this.fullName,
    this.sessionPackage,
    this.packageType = PackageType.daily,
    this.programType = ProgramType.sport,
    this.createdAt,
    this.registrationDate,
    this.isActive = true,
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
      'sessionPackage': sessionPackage ?? 0,
      'packageType': packageType.toStorageString(),
      'programType': programType.toStorageString(),
      'createdAt': createdAt,
      'registrationDate': registrationDate,
      'isActive': isActive ? 1 : 0,
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    final first = map['firstName'] as String? ?? '';
    final last = map['lastName'] as String? ?? '';
    final combined = last.isEmpty ? first : '$first $last';
    final pkgType = PackageType.fromString(map['packageType'] as String?);
    final programType = ProgramType.fromString(map['programType'] as String?);
    final rawPackage = map['sessionPackage'] as int?;
    return Client(
      id: map['id'] as int?,
      userId: map['userId'] as int?,
      fullName: combined,
      sessionPackage: pkgType == PackageType.monthly ? null : rawPackage,
      packageType: pkgType,
      programType: programType,
      createdAt: map['createdAt'] as String?,
      registrationDate: map['registrationDate'] as String?,
      isActive: (map['isActive'] as int? ?? 1) == 1,
    );
  }

  Client copyWith({
    int? id,
    int? userId,
    String? fullName,
    int? sessionPackage,
    PackageType? packageType,
    ProgramType? programType,
    String? createdAt,
    String? registrationDate,
    bool? isActive,
  }) {
    return Client(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      sessionPackage: sessionPackage ?? this.sessionPackage,
      packageType: packageType ?? this.packageType,
      programType: programType ?? this.programType,
      createdAt: createdAt ?? this.createdAt,
      registrationDate: registrationDate ?? this.registrationDate,
      isActive: isActive ?? this.isActive,
    );
  }
}
