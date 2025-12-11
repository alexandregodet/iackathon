import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:iackathon/presentation/pages/home_page.dart';

void main() {
  testWidgets('HomePage displays welcome message', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomePage(),
      ),
    );

    expect(find.text('Bienvenue sur IAckathon'), findsOneWidget);
    expect(find.text('Demarrer une conversation'), findsOneWidget);
  });
}
