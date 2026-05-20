import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:royal_shetkari/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Royal Shetkari welcome screen loads', (tester) async {
    await tester.pumpWidget(const RoyalShetkariApp());
    await tester.pumpAndSettle();

    expect(find.text('Royal Shetkari'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
