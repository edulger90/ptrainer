import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

enum TrainerWeekday {
  monday(DateTime.monday, 'Pazartesi'),
  tuesday(DateTime.tuesday, 'Salı'),
  wednesday(DateTime.wednesday, 'Çarşamba'),
  thursday(DateTime.thursday, 'Perşembe'),
  friday(DateTime.friday, 'Cuma'),
  saturday(DateTime.saturday, 'Cumartesi'),
  sunday(DateTime.sunday, 'Pazar');

  final int weekdayNumber;
  final String storageKey;

  const TrainerWeekday(this.weekdayNumber, this.storageKey);

  static TrainerWeekday? fromStorageKey(String value) {
    for (final day in values) {
      if (day.storageKey == value) return day;
    }
    return null;
  }

  static TrainerWeekday? fromWeekdayNumber(int value) {
    for (final day in values) {
      if (day.weekdayNumber == value) return day;
    }
    return null;
  }

  static TrainerWeekday? fromDate(DateTime? date) {
    if (date == null) return null;
    return fromWeekdayNumber(date.weekday);
  }

  String localized(BuildContext context) {
    final l = AppLocalizations.of(context);
    switch (this) {
      case TrainerWeekday.monday:
        return l.monday;
      case TrainerWeekday.tuesday:
        return l.tuesday;
      case TrainerWeekday.wednesday:
        return l.wednesday;
      case TrainerWeekday.thursday:
        return l.thursday;
      case TrainerWeekday.friday:
        return l.friday;
      case TrainerWeekday.saturday:
        return l.saturday;
      case TrainerWeekday.sunday:
        return l.sunday;
    }
  }
}
