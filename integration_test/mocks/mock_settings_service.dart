import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';

import 'package:iackathon/data/datasources/settings_service.dart';

class MockSettingsService extends Mock implements SettingsService {
  int _maxTokens = 1024;
  double _temperature = 0.7;
  String? _systemPrompt;
  int _themeMode = 0;

  @override
  final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(
    ThemeMode.system,
  );

  @override
  Future<void> init() async {
    // No-op for mock
  }

  @override
  int get maxTokens => _maxTokens;

  @override
  Future<void> setMaxTokens(int value) async {
    _maxTokens = value;
  }

  @override
  double get temperature => _temperature;

  @override
  Future<void> setTemperature(double value) async {
    _temperature = value;
  }

  @override
  String? get systemPrompt => _systemPrompt;

  @override
  Future<void> setSystemPrompt(String? value) async {
    _systemPrompt = value;
  }

  @override
  int get themeMode => _themeMode;

  @override
  Future<void> setThemeMode(int value) async {
    _themeMode = value;
    switch (value) {
      case 1:
        themeModeNotifier.value = ThemeMode.light;
        break;
      case 2:
        themeModeNotifier.value = ThemeMode.dark;
        break;
      default:
        themeModeNotifier.value = ThemeMode.system;
    }
  }
}
