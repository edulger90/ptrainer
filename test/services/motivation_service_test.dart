import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ptrainer/services/motivation_service.dart';

void main() {
  test('motivation messages are localized by locale', () {
    final turkish = MotivationService.messagesForLocale(const Locale('tr'));
    final english = MotivationService.messagesForLocale(const Locale('en'));

    expect(turkish, isNotEmpty);
    expect(english, isNotEmpty);
    expect(turkish.first, contains('Küçük'));
    expect(english.first, contains('Small'));
  });
}
