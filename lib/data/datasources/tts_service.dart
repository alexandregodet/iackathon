import 'dart:async';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:injectable/injectable.dart';

import '../../core/utils/app_logger.dart';

@singleton
class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isPlaying = false;
  String? _currentMessageId;
  final List<String> _speechQueue = [];
  bool _isProcessingQueue = false;
  Function? _onAllComplete;

  final _completionController = StreamController<void>.broadcast();
  Stream<void> get completionStream => _completionController.stream;

  bool get isPlaying => _isPlaying;
  String? get currentMessageId => _currentMessageId;

  Future<void> init() async {
    await _flutterTts.setLanguage('fr-FR');
    await _flutterTts.setSpeechRate(0.8);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setCompletionHandler(() {
      AppLogger.info('TTS chunk completed', 'TtsService');
      _isPlaying = false;
      _processQueue();
    });

    _flutterTts.setCancelHandler(() {
      _isPlaying = false;
      _currentMessageId = null;
      _speechQueue.clear();
      _isProcessingQueue = false;
      _onAllComplete = null;
    });

    _flutterTts.setErrorHandler((msg) {
      AppLogger.error('TTS error: $msg', tag: 'TtsService');
      _isPlaying = false;
      _currentMessageId = null;
      _speechQueue.clear();
      _isProcessingQueue = false;
      _onAllComplete = null;
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

  Future<void> speakStreaming(
    String text,
    String messageId, {
    Function? onComplete,
  }) async {
    AppLogger.info('Starting streaming TTS for message: $messageId', 'TtsService');

    if (_currentMessageId != messageId) {
      // New message, clear queue and reset
      await stop();
      _speechQueue.clear();
      _currentMessageId = messageId;
      _onAllComplete = onComplete;
    }

    // Add text to queue
    _speechQueue.add(text);

    // Start processing if not already processing
    if (!_isProcessingQueue && !_isPlaying) {
      _processQueue();
    }
  }

  void _processQueue() {
    if (_speechQueue.isEmpty) {
      AppLogger.info('TTS queue empty, all speech complete', 'TtsService');
      _isProcessingQueue = false;
      _currentMessageId = null;

      // Notify completion
      _completionController.add(null);
      if (_onAllComplete != null) {
        _onAllComplete!();
        _onAllComplete = null;
      }
      return;
    }

    _isProcessingQueue = true;
    final nextText = _speechQueue.removeAt(0);

    AppLogger.info('Speaking queued text: "${nextText.substring(0, nextText.length > 50 ? 50 : nextText.length)}..."', 'TtsService');
    _isPlaying = true;
    _flutterTts.speak(nextText);
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
    _completionController.close();
  }
}
