import 'package:flutter/material.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

@singleton
class SettingsService {
  static const String _maxTokensKey = 'max_tokens';
  static const String _temperatureKey = 'temperature';
  static const String _systemPromptKey = 'system_prompt';
  static const String _themeKey = 'theme_mode';

  SharedPreferences? _prefs;

  // Theme notifier for reactive updates
  final ValueNotifier<ThemeMode> themeModeNotifier =
      ValueNotifier(ThemeMode.system);

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    // Initialize theme notifier with saved value
    themeModeNotifier.value = _getThemeModeFromInt(themeMode);
  }

  ThemeMode _getThemeModeFromInt(int value) {
    switch (value) {
      case 1:
        return ThemeMode.light;
      case 2:
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  // Max Tokens
  int get maxTokens => _prefs?.getInt(_maxTokensKey) ?? 1024;
  Future<void> setMaxTokens(int value) async {
    await _prefs?.setInt(_maxTokensKey, value);
  }

  // Temperature (stored as int, 0-100, represents 0.0-1.0)
  double get temperature => (_prefs?.getInt(_temperatureKey) ?? 70) / 100.0;
  Future<void> setTemperature(double value) async {
    await _prefs?.setInt(_temperatureKey, (value * 100).round());
  }

  // System Prompt
  String? get systemPrompt => _prefs?.getString(_systemPromptKey);
  Future<void> setSystemPrompt(String? value) async {
    if (value == null || value.isEmpty) {
      await _prefs?.remove(_systemPromptKey);
    } else {
      await _prefs?.setString(_systemPromptKey, value);
    }
  }

  // Theme Mode (0: system, 1: light, 2: dark)
  int get themeMode => _prefs?.getInt(_themeKey) ?? 0;
  Future<void> setThemeMode(int value) async {
    await _prefs?.setInt(_themeKey, value);
    themeModeNotifier.value = _getThemeModeFromInt(value);
  }
}
