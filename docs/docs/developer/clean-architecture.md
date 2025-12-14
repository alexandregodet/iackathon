---
sidebar_position: 3
title: Clean Architecture
description: Principes de Clean Architecture appliques au projet
---

# Clean Architecture

IAckathon suit les principes de Clean Architecture pour garantir une base de code maintenable, testable et evolutive.

## Principes fondamentaux

### Separation des responsabilites

Chaque couche a une responsabilite unique et bien definie :

```
+------------------------+
|    Presentation        |  UI, Widgets, BLoCs
+------------------------+
           |
           v
+------------------------+
|       Domain           |  Entities, Use Cases
+------------------------+
           |
           v
+------------------------+
|        Data            |  Repositories, Data Sources
+------------------------+
           |
           v
+------------------------+
|    Infrastructure      |  Frameworks, Drivers
+------------------------+
```

### Regle de dependance

Les dependances pointent toujours vers l'interieur :

- **Presentation** depend de **Domain**
- **Data** depend de **Domain**
- **Domain** ne depend de rien d'externe

## Les couches en detail

### 1. Couche Presentation

**Localisation** : `/lib/presentation/`

**Responsabilites** :
- Affichage de l'interface utilisateur
- Gestion des interactions utilisateur
- Coordination via les BLoCs

**Composants** :

```dart
// Pages (ecrans)
class ChatPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ChatBloc>(),
      child: _ChatPageContent(),
    );
  }
}

// BLoC (logique de presentation)
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc(this._gemmaService, this._ragService, this._database);

  Future<void> _onSendMessage(
    ChatSendMessage event,
    Emitter<ChatState> emit,
  ) async {
    // Logique de presentation
  }
}
```

### 2. Couche Domain

**Localisation** : `/lib/domain/`

**Responsabilites** :
- Definition des entites metier
- Regles de validation
- Interfaces des repositories (si necessaire)

**Composants** :

```dart
// Entite pure (aucune dependance externe)
class ChatMessage {
  final String id;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final bool isStreaming;
  final Uint8List? imageBytes;
  final String? thinkingContent;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isStreaming = false,
    this.imageBytes,
    this.thinkingContent,
  });

  // Methodes de transformation
  ChatMessage copyWith({...}) => ChatMessage(...);
}

enum MessageRole { user, assistant, system }
```

```dart
// Entite avec logique metier
class GemmaModelInfo {
  final String id;
  final String name;
  final int sizeInMb;
  final bool isMultimodal;

  // Logique metier
  String get sizeLabel {
    if (sizeInMb >= 1000) {
      return '${(sizeInMb / 1000).toStringAsFixed(1)} Go';
    }
    return '$sizeInMb Mo';
  }
}
```

### 3. Couche Data

**Localisation** : `/lib/data/`

**Responsabilites** :
- Implementation des sources de donnees
- Transformation des donnees
- Cache et persistance

**Composants** :

```dart
// Service (Data Source)
@singleton
class GemmaService {
  GemmaModelState _state = GemmaModelState.notDownloaded;
  GemmaModelInfo? _currentModel;

  // Exposition de l'etat
  GemmaModelState get state => _state;
  bool get isReady => _state == GemmaModelState.ready;

  // Operations sur les donnees
  Future<void> loadModel([GemmaModelInfo? modelInfo]) async {
    _state = GemmaModelState.loading;
    // ... implementation
    _state = GemmaModelState.ready;
  }

  Stream<String> generateResponse(String userMessage) async* {
    // ... implementation
  }
}
```

```dart
// Database (Drift)
@DriftDatabase(tables: [Conversations, Messages, Documents])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // Queries typees
  Future<List<Conversation>> getAllConversations() {
    return select(conversations).get();
  }
}
```

## Pattern BLoC

Le pattern BLoC (Business Logic Component) est utilise pour la gestion d'etat :

### Structure d'un BLoC

```dart
// chat_event.dart - Evenements entrants
abstract class ChatEvent extends Equatable {
  const ChatEvent();
}

class ChatSendMessage extends ChatEvent {
  final String message;
  final Uint8List? imageBytes;

  const ChatSendMessage({required this.message, this.imageBytes});

  @override
  List<Object?> get props => [message, imageBytes];
}

class ChatStreamChunk extends ChatEvent {
  final String chunk;
  const ChatStreamChunk(this.chunk);

  @override
  List<Object> get props => [chunk];
}
```

```dart
// chat_state.dart - Etat immutable
class ChatState extends Equatable {
  final List<ChatMessage> messages;
  final bool isGenerating;
  final GemmaModelState modelState;
  // ...

  const ChatState({
    this.messages = const [],
    this.isGenerating = false,
    this.modelState = GemmaModelState.notDownloaded,
    // ...
  });

  ChatState copyWith({...}) => ChatState(...);

  @override
  List<Object?> get props => [messages, isGenerating, modelState, ...];
}
```

```dart
// chat_bloc.dart - Logique metier
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GemmaService _gemmaService;
  final RagService _ragService;
  final AppDatabase _database;

  ChatBloc(this._gemmaService, this._ragService, this._database)
      : super(const ChatState()) {
    on<ChatSendMessage>(_onSendMessage);
    on<ChatStreamChunk>(_onStreamChunk);
    // ...
  }

  Future<void> _onSendMessage(
    ChatSendMessage event,
    Emitter<ChatState> emit,
  ) async {
    if (!_gemmaService.isReady || state.isGenerating) return;

    // 1. Ajouter le message utilisateur
    final userMessage = ChatMessage(...);
    emit(state.copyWith(
      messages: [...state.messages, userMessage],
      isGenerating: true,
    ));

    // 2. Appeler le service
    _responseSubscription = _gemmaService
        .generateResponse(event.message)
        .listen((chunk) => add(ChatStreamChunk(chunk)));
  }
}
```

## Injection de dependances

L'injection de dependances permet de decoupler les composants :

### Configuration

```dart
// lib/core/di/injection.dart
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

final getIt = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies() async {
  getIt.init();
}
```

### Annotations

```dart
// Singleton - une instance pour toute l'app
@singleton
class GemmaService { ... }

// LazySingleton - instanciation tardive
@lazySingleton
class RagService { ... }

// Factory - nouvelle instance a chaque fois
@injectable
class ChatBloc { ... }
```

### Usage

```dart
// Recuperer une instance
final gemmaService = getIt<GemmaService>();

// Dans un widget
BlocProvider(
  create: (_) => getIt<ChatBloc>(),
  child: ChatPage(),
);
```

## Testabilite

Cette architecture facilite les tests :

### Tests unitaires

```dart
test('ChatBloc emits correct states on send message', () {
  final mockGemmaService = MockGemmaService();
  final mockRagService = MockRagService();
  final mockDatabase = MockAppDatabase();

  when(() => mockGemmaService.isReady).thenReturn(true);
  when(() => mockGemmaService.generateResponse(any()))
      .thenAnswer((_) => Stream.value('Response'));

  final bloc = ChatBloc(mockGemmaService, mockRagService, mockDatabase);

  expectLater(
    bloc.stream,
    emitsInOrder([
      isA<ChatState>().having((s) => s.isGenerating, 'isGenerating', true),
      isA<ChatState>().having((s) => s.messages.length, 'messages', 2),
    ]),
  );

  bloc.add(const ChatSendMessage(message: 'Hello'));
});
```

### Tests d'integration

```dart
testWidgets('Send message and receive response', (tester) async {
  await TestApp.initialize();
  TestApp.mockGemmaService.setModelState(GemmaModelState.ready);

  await tester.pumpWidget(TestApp.buildApp());
  // ... test navigation et interaction
});
```

## Avantages de cette architecture

| Avantage | Description |
|----------|-------------|
| **Maintenabilite** | Code organise et facile a naviguer |
| **Testabilite** | Chaque composant peut etre teste isolement |
| **Flexibilite** | Facile de changer une implementation |
| **Scalabilite** | Structure qui supporte la croissance |
| **Separation** | Chaque couche a une responsabilite claire |
