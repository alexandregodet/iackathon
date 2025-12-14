import 'package:flutter/material.dart';
import 'package:drift/native.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:iackathon/core/di/injection.dart';
import 'package:iackathon/data/datasources/database.dart';
import 'package:iackathon/data/datasources/gemma_service.dart';
import 'package:iackathon/data/datasources/prompt_template_service.dart';
import 'package:iackathon/data/datasources/rag_service.dart';
import 'package:iackathon/data/datasources/settings_service.dart';
import 'package:iackathon/data/datasources/tts_service.dart';
import 'package:iackathon/presentation/blocs/chat/chat_bloc.dart';
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
    // Disable runtime font fetching for tests
    GoogleFonts.config.allowRuntimeFetching = false;

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

    // Register PromptTemplateService with test database
    getIt.registerSingleton<PromptTemplateService>(
      PromptTemplateService(testDatabase),
    );

    // Register ChatBloc factory
    getIt.registerFactory<ChatBloc>(
      () => ChatBloc(mockGemmaService, mockRagService, testDatabase),
    );

    // Initialize services
    await mockSettingsService.init();
    await mockTtsService.init();
  }

  /// Clean up after tests
  static Future<void> tearDown() async {
    await testDatabase.close();
    await resetGetIt();
  }

  /// Simple test theme without Google Fonts (for faster tests)
  static ThemeData get _testTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: const Color(0xFF00F5D4),
        onPrimary: const Color(0xFF0A0A0F),
        secondary: const Color(0xFFFF00FF),
        tertiary: const Color(0xFFFFB800),
        surface: const Color(0xFF0A0A0F),
        onSurface: const Color(0xFFE0E0E0),
        error: const Color(0xFFFF5252),
      ),
    );
  }

  static ThemeData get _testLightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: const Color(0xFF00897B),
        secondary: const Color(0xFF5E35B1),
        tertiary: const Color(0xFFFFB800),
        surface: const Color(0xFFF8F8F2),
        onSurface: const Color(0xFF1A1A1A),
        error: const Color(0xFFD32F2F),
      ),
    );
  }

  /// Build the test app widget
  static Widget buildApp({Widget? home}) {
    return MaterialApp(
      title: 'IAckathon Test',
      debugShowCheckedModeBanner: false,
      theme: _testLightTheme,
      darkTheme: _testTheme,
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
          theme: _testLightTheme,
          darkTheme: _testTheme,
          themeMode: themeMode,
          home: home ?? const HomePage(),
        );
      },
    );
  }
}
