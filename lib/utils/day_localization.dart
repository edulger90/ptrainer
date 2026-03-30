import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class DayLocalizationHelper {
  static String localizedDay(BuildContext context, String dayKey) {
    final l = AppLocalizations.of(context);
    switch (dayKey) {
      case 'Pazartesi':
        return l.monday;
      case 'Salı':
        return l.tuesday;
      case 'Çarşamba':
        return l.wednesday;
      case 'Perşembe':
        return l.thursday;
      case 'Cuma':
        return l.friday;
      case 'Cumartesi':
        return l.saturday;
      case 'Pazar':
        return l.sunday;
      default:
        return dayKey;
    }
  }
}
