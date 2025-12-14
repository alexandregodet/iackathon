import 'package:flutter_tts/flutter_tts.dart';
import 'package:injectable/injectable.dart';

@singleton
class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isPlaying = false;
  String? _currentMessageId;

  bool get isPlaying => _isPlaying;
  String? get currentMessageId => _currentMessageId;

  Future<void> init() async {
    await _flutterTts.setLanguage('fr-FR');
    await _flutterTts.setSpeechRate(0.8);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setCompletionHandler(() {
      _isPlaying = false;
      _currentMessageId = null;
    });

    _flutterTts.setCancelHandler(() {
      _isPlaying = false;
      _currentMessageId = null;
    });

    _flutterTts.setErrorHandler((msg) {
      _isPlaying = false;
      _currentMessageId = null;
    });
  }

  Future<void> speak(String text, String messageId) async {
    if (_isPlaying) {
      await stop();
    }

    _isPlaying = true;
    _currentMessageId = messageId;
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
    _isPlaying = false;
    _currentMessageId = null;
  }

  bool isPlayingMessage(String messageId) {
    return _isPlaying && _currentMessageId == messageId;
  }

  void dispose() {
    _flutterTts.stop();
  }
}
