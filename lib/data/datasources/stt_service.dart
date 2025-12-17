import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../core/utils/app_logger.dart';

@singleton
class SttService {
  final SpeechToText _speechToText = SpeechToText();
  bool _isListening = false;
  bool _isAvailable = false;
  String _lastRecognizedText = '';

  // Event streams
  final _partialResultController = StreamController<String>.broadcast();
  final _finalResultController = StreamController<String>.broadcast();
  final _stateController = StreamController<bool>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  Stream<String> get partialResultStream => _partialResultController.stream;
  Stream<String> get finalResultStream => _finalResultController.stream;
  Stream<bool> get isListeningStream => _stateController.stream;
  Stream<String> get errorStream => _errorController.stream;

  bool get isListening => _isListening;
  bool get isAvailable => _isAvailable;
  String get lastRecognizedText => _lastRecognizedText;

  Future<void> init() async {
    try {
      AppLogger.info('Initializing SttService', 'SttService');
      _isAvailable = await _speechToText.initialize(
        onError: (error) {
          AppLogger.error('Speech recognition error: $error', tag: 'SttService');

          // Don't treat "no match" as a critical error - it's normal
          if (error.errorMsg != 'error_no_match') {
            _errorController.add(error.errorMsg);
          }

          _isListening = false;
          _stateController.add(false);
        },
        onStatus: (status) {
          AppLogger.info('Speech recognition status: $status', 'SttService');
          if (status == 'done' || status == 'notListening') {
            if (_isListening) {
              _isListening = false;
              _stateController.add(false);
            }
          } else if (status == 'listening') {
            if (!_isListening) {
              _isListening = true;
              _stateController.add(true);
            }
          }
        },
      );

      if (_isAvailable) {
        AppLogger.info('Speech recognition is available', 'SttService');
      } else {
        AppLogger.warning(
          'Speech recognition is not available on this device',
          'SttService',
        );
        _errorController.add('Speech recognition not available');
      }
    } catch (e) {
      AppLogger.error('Failed to initialize SttService: $e', tag: 'SttService');
      _isAvailable = false;
      _errorController.add('Failed to initialize speech recognition');
    }
  }

  Future<bool> checkPermission() async {
    final status = await Permission.microphone.status;
    AppLogger.info('Microphone permission status: $status', 'SttService');
    return status.isGranted;
  }

  Future<bool> requestPermission() async {
    AppLogger.info('Requesting microphone permission', 'SttService');
    final status = await Permission.microphone.request();

    if (status.isGranted) {
      AppLogger.info('Microphone permission granted', 'SttService');
      return true;
    } else if (status.isDenied) {
      AppLogger.warning('Microphone permission denied', 'SttService');
      _errorController.add('Microphone permission denied');
      return false;
    } else if (status.isPermanentlyDenied) {
      AppLogger.warning('Microphone permission permanently denied', 'SttService');
      _errorController.add('Please enable microphone in settings');
      return false;
    }

    return false;
  }

  Future<void> startListening() async {
    if (!_isAvailable) {
      AppLogger.warning('Cannot start listening: not available', 'SttService');
      _errorController.add('Speech recognition not available');
      return;
    }

    if (_isListening) {
      AppLogger.warning('Already listening', 'SttService');
      return;
    }

    final hasPermission = await checkPermission();
    if (!hasPermission) {
      final granted = await requestPermission();
      if (!granted) {
        return;
      }
    }

    try {
      AppLogger.info('Starting continuous listening', 'SttService');
      _isListening = true;
      _stateController.add(true);

      await _speechToText.listen(
        onResult: (result) {
          _lastRecognizedText = result.recognizedWords;

          if (result.recognizedWords.isNotEmpty) {
            AppLogger.info(
              'Recognized: "${result.recognizedWords}" (final: ${result.finalResult})',
              'SttService',
            );

            // Stream partial results in real-time
            if (!result.finalResult) {
              _partialResultController.add(result.recognizedWords);
            } else {
              // Stream final result when user stops speaking
              _finalResultController.add(result.recognizedWords);
              _lastRecognizedText = '';
            }
          }
        },
        localeId: 'fr-FR',
        // Pause detection - 5 seconds of silence indicates user finished
        pauseFor: const Duration(seconds: 5),
        // Listen for a long time (continuous mode)
        listenFor: const Duration(minutes: 10),
        listenOptions: SpeechListenOptions(
          // Continuous listening mode
          listenMode: ListenMode.confirmation,
          // Enable partial results for real-time feedback
          partialResults: true,
          // Use on-device recognition when available (offline)
          onDevice: true,
          // Recognize speech even if user pauses
          cancelOnError: false,
        ),
      );
    } catch (e) {
      AppLogger.error('Failed to start listening: $e', tag: 'SttService');
      _isListening = false;
      _stateController.add(false);
      _errorController.add('Failed to start speech recognition');
    }
  }

  Future<void> stopListening() async {
    if (!_isListening) {
      return;
    }

    try {
      AppLogger.info('Stopping listening', 'SttService');
      await _speechToText.stop();
      _isListening = false;
      _stateController.add(false);
    } catch (e) {
      AppLogger.error('Failed to stop listening: $e', tag: 'SttService');
      _errorController.add('Failed to stop speech recognition');
    }
  }

  Future<void> restartListening() async {
    AppLogger.info('Restarting listening', 'SttService');
    await stopListening();
    // Small delay to ensure clean state transition
    await Future.delayed(const Duration(milliseconds: 500));
    await startListening();
  }

  void dispose() {
    AppLogger.info('Disposing SttService', 'SttService');
    _speechToText.stop();
    _partialResultController.close();
    _finalResultController.close();
    _stateController.close();
    _errorController.close();
  }
}
