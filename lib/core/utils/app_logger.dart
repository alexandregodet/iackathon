import 'package:flutter/foundation.dart';

import '../errors/app_errors.dart';

enum LogLevel { debug, info, warning, error }

/// Logger simple pour l'application
class AppLogger {
  static LogLevel _minLevel = kDebugMode ? LogLevel.debug : LogLevel.info;

  static void setMinLevel(LogLevel level) => _minLevel = level;

  static void debug(String message, [String? tag]) {
    _log(LogLevel.debug, message, tag);
  }

  static void info(String message, [String? tag]) {
    _log(LogLevel.info, message, tag);
  }

  static void warning(String message, [String? tag]) {
    _log(LogLevel.warning, message, tag);
  }

  static void error(
    String message, {
    String? tag,
    dynamic error,
    StackTrace? stackTrace,
  }) {
    _log(LogLevel.error, message, tag);
    if (error != null) {
      debugPrint('  Error: $error');
    }
    if (stackTrace != null && kDebugMode) {
      debugPrint('  Stack: $stackTrace');
    }
  }

  static void logAppError(AppError appError, [String? tag]) {
    error(
      '[${appError.code}] ${appError.message}',
      tag: tag,
      error: appError.originalError,
      stackTrace: appError.stackTrace,
    );
  }

  static void _log(LogLevel level, String message, String? tag) {
    if (level.index < _minLevel.index) return;

    final prefix = switch (level) {
      LogLevel.debug => '[DEBUG]',
      LogLevel.info => '[INFO]',
      LogLevel.warning => '[WARN]',
      LogLevel.error => '[ERROR]',
    };

    final tagStr = tag != null ? '[$tag] ' : '';
    final timestamp = DateTime.now().toIso8601String().substring(11, 23);
    debugPrint('$timestamp $prefix $tagStr$message');
  }
}
