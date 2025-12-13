import 'dart:async';
import 'dart:typed_data';

import 'package:mocktail/mocktail.dart';

import 'package:iackathon/data/datasources/gemma_service.dart';
import 'package:iackathon/domain/entities/gemma_model_info.dart';

class MockGemmaService extends Mock implements GemmaService {
  GemmaModelState _state = GemmaModelState.ready;
  GemmaModelInfo? _currentModel;
  String? _systemPrompt;
  final List<String> _mockResponses = [];
  int _responseIndex = 0;

  final _stateController = StreamController<GemmaModelState>.broadcast();
  final _progressController = StreamController<double>.broadcast();

  @override
  GemmaModelState get state => _state;

  @override
  double get downloadProgress => 1.0;

  @override
  String? get errorMessage => null;

  @override
  bool get isReady => _state == GemmaModelState.ready;

  @override
  GemmaModelInfo? get currentModel => _currentModel;

  @override
  bool get isMultimodal => _currentModel?.isMultimodal ?? false;

  @override
  bool get supportsThinking => _currentModel?.supportsThinking ?? false;

  @override
  String? get systemPrompt => _systemPrompt;

  @override
  Stream<GemmaModelState> get stateStream => _stateController.stream;

  @override
  Stream<double> get progressStream => _progressController.stream;

  /// Configure mock responses for tests
  void setMockResponses(List<String> responses) {
    _mockResponses.clear();
    _mockResponses.addAll(responses);
    _responseIndex = 0;
  }

  /// Set the model state
  void setModelState(GemmaModelState newState) {
    _state = newState;
    _stateController.add(_state);
  }

  /// Set the current model
  void setCurrentModel(GemmaModelInfo model) {
    _currentModel = model;
  }

  @override
  void setSystemPrompt(String? prompt) {
    _systemPrompt = prompt?.trim().isEmpty == true ? null : prompt?.trim();
  }

  @override
  void setHuggingFaceToken(String? token) {
    // No-op for mock
  }

  @override
  Future<void> checkModelStatus(GemmaModelInfo modelInfo) async {
    _currentModel = modelInfo;
    // Simulate model is already installed
    _state = GemmaModelState.installed;
    _stateController.add(_state);
  }

  @override
  Future<void> downloadModel(
    GemmaModelInfo modelInfo, {
    void Function(double)? onProgress,
    String? token,
  }) async {
    _currentModel = modelInfo;
    _state = GemmaModelState.downloading;
    _stateController.add(_state);

    // Simulate quick download
    for (var i = 0; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 10));
      onProgress?.call(i / 10);
    }

    _state = GemmaModelState.installed;
    _stateController.add(_state);
  }

  @override
  Future<void> loadModel([GemmaModelInfo? modelInfo]) async {
    if (modelInfo != null) {
      _currentModel = modelInfo;
    }

    _state = GemmaModelState.loading;
    _stateController.add(_state);

    await Future.delayed(const Duration(milliseconds: 50));

    _state = GemmaModelState.ready;
    _stateController.add(_state);
  }

  @override
  Stream<String> generateResponse(String userMessage, {Uint8List? imageBytes}) async* {
    // Return mock response token by token
    final response = _getNextResponse();
    final words = response.split(' ');

    for (final word in words) {
      await Future.delayed(const Duration(milliseconds: 10));
      yield '$word ';
    }
  }

  @override
  Stream<GemmaStreamResponse> generateResponseWithThinking(
    String userMessage, {
    Uint8List? imageBytes,
  }) async* {
    // Simulate thinking phase
    yield const GemmaStreamResponse(
      thinkingChunk: 'Analyzing the question...',
      isThinkingPhase: true,
    );

    await Future.delayed(const Duration(milliseconds: 50));

    yield const GemmaStreamResponse(
      thinkingChunk: 'Formulating response...',
      isThinkingPhase: true,
    );

    await Future.delayed(const Duration(milliseconds: 50));

    // Return mock response
    final response = _getNextResponse();
    final words = response.split(' ');

    for (final word in words) {
      await Future.delayed(const Duration(milliseconds: 10));
      yield GemmaStreamResponse(
        textChunk: '$word ',
        isThinkingPhase: false,
      );
    }
  }

  @override
  Future<String> generateResponseSync(String userMessage) async {
    await Future.delayed(const Duration(milliseconds: 50));
    return _getNextResponse();
  }

  @override
  Future<void> clearChat() async {
    // Reset response index
    _responseIndex = 0;
  }

  @override
  Future<void> unloadModel() async {
    _state = GemmaModelState.installed;
    _stateController.add(_state);
  }

  @override
  void dispose() {
    _stateController.close();
    _progressController.close();
  }

  String _getNextResponse() {
    if (_mockResponses.isEmpty) {
      return 'This is a mock response from the AI model.';
    }
    final response = _mockResponses[_responseIndex % _mockResponses.length];
    _responseIndex++;
    return response;
  }
}
