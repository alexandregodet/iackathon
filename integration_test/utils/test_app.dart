import 'package:flutter/material.dart';
import 'package:drift/native.dart';

import 'package:iackathon/core/di/injection.dart';
import 'package:iackathon/core/theme/app_theme.dart';
import 'package:iackathon/data/datasources/database.dart';
import 'package:iackathon/data/datasources/gemma_service.dart';
import 'package:iackathon/data/datasources/rag_service.dart';
import 'package:iackathon/data/datasources/settings_service.dart';
import 'package:iackathon/data/datasources/tts_service.dart';
import 'package:iackathon/presentation/pages/home_page.dart';

import '../mocks/mock_gemma_service.dart';
import '../mocks/mock_rag_service.dart';
import '../mocks/mock_settings_service.dart';
import '../mocks/mock_tts_service.dart';

/// Test app configuration for integration tests
class TestApp {
  static late MockGemmaService mockGemmaService;
  static late MockRagService mockRagService;
  static late MockTtsService mockTtsService;
  static late MockSettingsService mockSettingsService;
  static late AppDatabase testDatabase;

  /// Initialize all mocks and register them with GetIt
  static Future<void> initialize() async {
    await resetGetIt();

    // Create mocks
    mockGemmaService = MockGemmaService();
    mockRagService = MockRagService();
    mockTtsService = MockTtsService();
    mockSettingsService = MockSettingsService();

    // Create in-memory database for tests
    testDatabase = AppDatabase.forTesting(NativeDatabase.memory());

    // Register mocks with GetIt
    getIt.registerSingleton<GemmaService>(mockGemmaService);
    getIt.registerSingleton<RagService>(mockRagService);
    getIt.registerSingleton<TtsService>(mockTtsService);
    getIt.registerSingleton<SettingsService>(mockSettingsService);
    getIt.registerSingleton<AppDatabase>(testDatabase);

    // Initialize services
    await mockSettingsService.init();
    await mockTtsService.init();
  }

  /// Clean up after tests
  static Future<void> tearDown() async {
    await testDatabase.close();
    await resetGetIt();
  }

  /// Build the test app widget
  static Widget buildApp({Widget? home}) {
    return MaterialApp(
      title: 'IAckathon Test',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: home ?? const HomePage(),
    );
  }

  /// Build the test app with theme notifier support
  static Widget buildAppWithTheme({Widget? home}) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: mockSettingsService.themeModeNotifier,
      builder: (context, themeMode, child) {
        return MaterialApp(
          title: 'IAckathon Test',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          home: home ?? const HomePage(),
        );
      },
    );
  }
}
