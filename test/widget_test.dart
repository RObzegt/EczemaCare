import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gezondheids_tracker/main.dart';

void main() {
  testWidgets('App starts smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TriggerTraceApp(hasSubscription: true));

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
