import 'dart:async';

import 'package:mocktail/mocktail.dart';

import 'package:iackathon/data/datasources/stt_service.dart';

class MockSttService extends Mock implements SttService {
  bool _isListening = false;
  bool _isAvailable = true;

  final _partialResultController = StreamController<String>.broadcast();
  final _finalResultController = StreamController<String>.broadcast();
  final _stateController = StreamController<bool>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  @override
  bool get isListening => _isListening;

  @override
  bool get isAvailable => _isAvailable;

  @override
  String get lastRecognizedText => '';

  @override
  Stream<String> get partialResultStream => _partialResultController.stream;

  @override
  Stream<String> get finalResultStream => _finalResultController.stream;

  @override
  Stream<bool> get isListeningStream => _stateController.stream;

  @override
  Stream<String> get errorStream => _errorController.stream;

  @override
  Future<void> init() async {
    _isAvailable = true;
  }

  @override
  Future<bool> checkPermission() async => true;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<void> startListening() async {
    _isListening = true;
    _stateController.add(true);
  }

  @override
  Future<void> stopListening() async {
    _isListening = false;
    _stateController.add(false);
  }

  @override
  Future<void> restartListening() async {
    await stopListening();
    await startListening();
  }

  @override
  void dispose() {
    _partialResultController.close();
    _finalResultController.close();
    _stateController.close();
    _errorController.close();
  }

  void simulatePartialResult(String text) {
    _partialResultController.add(text);
  }

  void simulateFinalResult(String text) {
    _finalResultController.add(text);
  }

  void simulateError(String error) {
    _errorController.add(error);
  }
}
