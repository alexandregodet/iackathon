import 'package:mocktail/mocktail.dart';

import 'package:iackathon/data/datasources/tts_service.dart';

class MockTtsService extends Mock implements TtsService {
  bool _isPlaying = false;
  String? _currentMessageId;

  @override
  bool get isPlaying => _isPlaying;

  @override
  String? get currentMessageId => _currentMessageId;

  @override
  Future<void> init() async {
    // No-op for mock
  }

  @override
  Future<void> speak(String text, String messageId) async {
    if (_isPlaying) {
      await stop();
    }

    _isPlaying = true;
    _currentMessageId = messageId;

    // Simulate speech duration based on text length
    // In real tests, this can be shortened or controlled
    await Future.delayed(const Duration(milliseconds: 100));
  }

  @override
  Future<void> stop() async {
    _isPlaying = false;
    _currentMessageId = null;
  }

  @override
  bool isPlayingMessage(String messageId) {
    return _isPlaying && _currentMessageId == messageId;
  }

  @override
  void dispose() {
    _isPlaying = false;
    _currentMessageId = null;
  }

  /// Simulate speech completion (for tests)
  void simulateCompletion() {
    _isPlaying = false;
    _currentMessageId = null;
  }
}
