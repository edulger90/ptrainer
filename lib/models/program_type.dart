enum ProgramType {
  sport,
  course,
  personal;

  static ProgramType fromString(String? value) {
    switch (value) {
      case 'course':
        return ProgramType.course;
      case 'personal':
        return ProgramType.personal;
      default:
        return ProgramType.sport;
    }
  }

  String toStorageString() => name;
}
