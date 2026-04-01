import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ptrainer/widgets/app_background.dart';

void main() {
  testWidgets('AppBackground renders child content', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AppBackground(child: Text('content'))),
      ),
    );

    expect(find.text('content'), findsOneWidget);
    expect(find.byType(AppBackground), findsOneWidget);
    expect(find.byType(Opacity), findsOneWidget);
  });
}
