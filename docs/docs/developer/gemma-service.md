---
sidebar_position: 4
title: GemmaService
description: Service d'inference IA avec les modeles Gemma
---

# GemmaService

Le `GemmaService` est le composant central qui gere l'inference des modeles Gemma localement sur l'appareil.

## Vue d'ensemble

```dart
@singleton
class GemmaService {
  // Etat du modele
  GemmaModelState get state;
  bool get isReady;
  GemmaModelInfo? get currentModel;

  // Gestion du cycle de vie
  Future<void> checkModelStatus(GemmaModelInfo modelInfo);
  Future<void> downloadModel(GemmaModelInfo modelInfo, {...});
  Future<void> loadModel([GemmaModelInfo? modelInfo]);
  Future<void> unloadModel();

  // Generation
  Stream<String> generateResponse(String userMessage, {Uint8List? imageBytes});
  Stream<GemmaStreamResponse> generateResponseWithThinking(String userMessage);
}
```

## Etats du modele

Le service gere plusieurs etats du modele :

```dart
enum GemmaModelState {
  notDownloaded,  // Modele non telecharge
  downloading,    // Telechargement en cours
  installed,      // Telecharge mais non charge
  loading,        // Chargement en cours
  ready,          // Pret pour l'inference
  error,          // Erreur
}
```

### Diagramme d'etat

```
                    +----------------+
                    | notDownloaded  |
                    +----------------+
                           |
                           v  downloadModel()
                    +----------------+
                    |  downloading   |
                    +----------------+
                           |
                           v  (complete)
                    +----------------+
                    |   installed    |<----+
                    +----------------+     |
                           |               |
                           v  loadModel()  | unloadModel()
                    +----------------+     |
                    |    loading     |     |
                    +----------------+     |
                           |               |
                           v  (complete)   |
                    +----------------+     |
                    |     ready      |-----+
                    +----------------+
```

## Methodes principales

### checkModelStatus

Verifie si le modele est telecharge sur l'appareil :

```dart
Future<void> checkModelStatus(GemmaModelInfo modelInfo) async {
  _currentModel = modelInfo;

  final modelPath = await _getModelPath(modelInfo);
  final file = File(modelPath);

  if (await file.exists()) {
    _state = GemmaModelState.installed;
  } else {
    _state = GemmaModelState.notDownloaded;
  }

  _stateController.add(_state);
}
```

### downloadModel

Telecharge le modele depuis le CDN :

```dart
Future<void> downloadModel(
  GemmaModelInfo modelInfo, {
  void Function(double)? onProgress,
  String? token, // Pour les modeles HuggingFace proteges
}) async {
  _state = GemmaModelState.downloading;
  _stateController.add(_state);

  try {
    await FlutterGemma.instance.downloadModel(
      modelInfo.url,
      modelInfo.filename,
      onProgress: (progress) {
        _downloadProgress = progress;
        onProgress?.call(progress);
        _progressController.add(progress);
      },
    );

    _state = GemmaModelState.installed;
    _stateController.add(_state);
  } catch (e) {
    _state = GemmaModelState.error;
    _errorMessage = e.toString();
    _stateController.add(_state);
  }
}
```

### loadModel

Charge le modele en memoire pour l'inference :

```dart
Future<void> loadModel([GemmaModelInfo? modelInfo]) async {
  if (modelInfo != null) {
    _currentModel = modelInfo;
  }

  if (_currentModel == null) {
    throw StateError('No model selected');
  }

  _state = GemmaModelState.loading;
  _stateController.add(_state);

  try {
    await FlutterGemma.instance.loadModel(
      modelType: _currentModel!.modelType,
      fileType: _currentModel!.fileType,
      modelPath: _currentModel!.filename,
    );

    _state = GemmaModelState.ready;
    _stateController.add(_state);
  } catch (e) {
    _state = GemmaModelState.error;
    _errorMessage = e.toString();
    _stateController.add(_state);
  }
}
```

### generateResponse

Genere une reponse en streaming :

```dart
Stream<String> generateResponse(
  String userMessage, {
  Uint8List? imageBytes,
}) async* {
  if (!isReady) {
    throw StateError('Model not ready');
  }

  final request = GemmaRequest(
    prompt: userMessage,
    maxTokens: _maxTokens,
    temperature: _temperature,
    topK: _topK,
    topP: _topP,
  );

  if (imageBytes != null && isMultimodal) {
    request.images = [imageBytes];
  }

  await for (final chunk in FlutterGemma.instance.generateStream(request)) {
    yield chunk;
  }
}
```

### generateResponseWithThinking

Pour les modeles avec mode reflexion (DeepSeek R1) :

```dart
Stream<GemmaStreamResponse> generateResponseWithThinking(
  String userMessage, {
  Uint8List? imageBytes,
}) async* {
  if (!supportsThinking) {
    throw StateError('Model does not support thinking mode');
  }

  await for (final chunk in FlutterGemma.instance.generateStreamWithThinking(
    GemmaRequest(prompt: userMessage, ...),
  )) {
    yield GemmaStreamResponse(
      textChunk: chunk.text,
      thinkingChunk: chunk.thinking,
      isThinkingPhase: chunk.isThinking,
    );
  }
}
```

## Gestion du prompt systeme

```dart
String? _systemPrompt;

void setSystemPrompt(String? prompt) {
  _systemPrompt = prompt?.trim().isEmpty == true ? null : prompt?.trim();
}

// Utilisation interne
String _buildPrompt(String userMessage) {
  if (_systemPrompt != null) {
    return '$_systemPrompt\n\nUser: $userMessage';
  }
  return userMessage;
}
```

## Streams reactifs

Le service expose des streams pour observer les changements :

```dart
// Stream d'etat
final _stateController = StreamController<GemmaModelState>.broadcast();
Stream<GemmaModelState> get stateStream => _stateController.stream;

// Stream de progression
final _progressController = StreamController<double>.broadcast();
Stream<double> get progressStream => _progressController.stream;
```

### Usage dans un BLoC

```dart
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  late final StreamSubscription<GemmaModelState> _stateSubscription;

  ChatBloc(this._gemmaService, ...) : super(const ChatState()) {
    // Ecouter les changements d'etat du modele
    _stateSubscription = _gemmaService.stateStream.listen((state) {
      add(ChatModelStateChanged(state));
    });
  }

  @override
  Future<void> close() {
    _stateSubscription.cancel();
    return super.close();
  }
}
```

## Parametres de generation

Les parametres sont configurables via le service :

```dart
int _maxTokens = 1024;
double _temperature = 0.8;
int _topK = 40;
double _topP = 0.95;

void setGenerationParams({
  int? maxTokens,
  double? temperature,
  int? topK,
  double? topP,
}) {
  if (maxTokens != null) _maxTokens = maxTokens;
  if (temperature != null) _temperature = temperature;
  if (topK != null) _topK = topK;
  if (topP != null) _topP = topP;
}
```

## Gestion des erreurs

```dart
String? _errorMessage;
String? get errorMessage => _errorMessage;

Future<void> _handleError(dynamic error, String operation) async {
  _errorMessage = 'Error during $operation: $error';
  _state = GemmaModelState.error;
  _stateController.add(_state);

  // Log pour debug
  debugPrint(_errorMessage);
}
```

## Cycle de vie

```dart
void dispose() {
  _stateController.close();
  _progressController.close();
  _responseSubscription?.cancel();
}
```

## Tests et mocking

```dart
class MockGemmaService extends Mock implements GemmaService {
  GemmaModelState _state = GemmaModelState.ready;
  final List<String> _mockResponses = [];

  @override
  GemmaModelState get state => _state;

  @override
  bool get isReady => _state == GemmaModelState.ready;

  void setModelState(GemmaModelState newState) {
    _state = newState;
  }

  void setMockResponses(List<String> responses) {
    _mockResponses.clear();
    _mockResponses.addAll(responses);
  }

  @override
  Stream<String> generateResponse(String message, {Uint8List? imageBytes}) async* {
    final response = _mockResponses.removeAt(0);
    for (final word in response.split(' ')) {
      await Future.delayed(const Duration(milliseconds: 10));
      yield '$word ';
    }
  }
}
```
