enum PackageType {
  daily,
  monthly;

  static PackageType fromString(String? value) {
    if (value == 'monthly') return PackageType.monthly;
    return PackageType.daily;
  }

  String toStorageString() => name;
}
