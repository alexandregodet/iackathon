import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:iackathon/presentation/pages/home_page.dart';

void main() {
  testWidgets('HomePage displays app title and start button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomePage()));

    // App title in AppBar
    expect(find.text('IAckathon'), findsOneWidget);

    // Terminal header
    expect(find.text('# IAckathon - Local AI Assistant'), findsOneWidget);

    // Features section
    expect(find.text('# Features'), findsOneWidget);

    // Start button
    expect(find.text('SELECT_MODEL'), findsOneWidget);

    // Settings icon
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
  });

  testWidgets('HomePage has working settings button', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: HomePage()));

    // Find settings icon
    final settingsButton = find.byIcon(Icons.settings_outlined);
    expect(settingsButton, findsOneWidget);
  });

  testWidgets('HomePage displays system info', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomePage()));

    // System section
    expect(find.text('# System'), findsOneWidget);
    expect(find.text('engine: Gemma 2/3'), findsOneWidget);
  });
}
