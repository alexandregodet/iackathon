---
sidebar_position: 7
title: Pattern BLoC
description: Gestion d'etat avec le pattern BLoC
---

# Pattern BLoC

IAckathon utilise le pattern **BLoC** (Business Logic Component) pour la gestion d'etat, implementé avec le package `flutter_bloc`.

## Concepts cles

### Flux unidirectionnel

```
+--------+    Event    +-------+    State    +---------+
|   UI   | ---------> | BLoC  | ---------> |   UI    |
| action |            | logic |            | rebuild |
+--------+            +-------+            +---------+
```

1. L'UI dispatch un **Event**
2. Le BLoC traite l'event et emet un nouveau **State**
3. L'UI se reconstruit avec le nouveau state

### Composants

| Composant | Responsabilite |
|-----------|----------------|
| **Event** | Represente une action utilisateur ou systeme |
| **State** | Represente l'etat de l'UI a un instant T |
| **BLoC** | Contient la logique metier, transforme Events en States |

## ChatBloc en detail

### Events

```dart
// chat_event.dart
abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

// Initialisation
class ChatInitialize extends ChatEvent {
  final GemmaModelInfo modelInfo;
  const ChatInitialize(this.modelInfo);

  @override
  List<Object> get props => [modelInfo];
}

// Envoi de message
class ChatSendMessage extends ChatEvent {
  final String message;
  final Uint8List? imageBytes;

  const ChatSendMessage({
    required this.message,
    this.imageBytes,
  });

  @override
  List<Object?> get props => [message, imageBytes];
}

// Reception d'un chunk de reponse
class ChatStreamChunk extends ChatEvent {
  final String chunk;
  const ChatStreamChunk(this.chunk);

  @override
  List<Object> get props => [chunk];
}

// Fin du stream
class ChatStreamComplete extends ChatEvent {
  const ChatStreamComplete();
}

// Gestion des conversations
class ChatLoadConversation extends ChatEvent {
  final int conversationId;
  const ChatLoadConversation(this.conversationId);

  @override
  List<Object> get props => [conversationId];
}

class ChatClearConversation extends ChatEvent {
  const ChatClearConversation();
}
```

### State

```dart
// chat_state.dart
class ChatState extends Equatable {
  final List<ChatMessage> messages;
  final GemmaModelInfo? selectedModel;
  final GemmaModelState modelState;
  final double downloadProgress;
  final bool isGenerating;
  final bool isThinking;
  final String? currentThinkingContent;
  final String? error;
  final int? currentConversationId;
  final List<DocumentInfo> documents;

  const ChatState({
    this.messages = const [],
    this.selectedModel,
    this.modelState = GemmaModelState.notDownloaded,
    this.downloadProgress = 0.0,
    this.isGenerating = false,
    this.isThinking = false,
    this.currentThinkingContent,
    this.error,
    this.currentConversationId,
    this.documents = const [],
  });

  // Helpers
  bool get isModelReady => modelState == GemmaModelState.ready;
  bool get hasActiveDocuments => documents.any((d) => d.isActive);

  // CopyWith pour l'immutabilite
  ChatState copyWith({
    List<ChatMessage>? messages,
    GemmaModelInfo? selectedModel,
    GemmaModelState? modelState,
    double? downloadProgress,
    bool? isGenerating,
    bool? isThinking,
    String? currentThinkingContent,
    String? error,
    int? currentConversationId,
    List<DocumentInfo>? documents,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      selectedModel: selectedModel ?? this.selectedModel,
      modelState: modelState ?? this.modelState,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      isGenerating: isGenerating ?? this.isGenerating,
      isThinking: isThinking ?? this.isThinking,
      currentThinkingContent: currentThinkingContent ?? this.currentThinkingContent,
      error: error,
      currentConversationId: currentConversationId ?? this.currentConversationId,
      documents: documents ?? this.documents,
    );
  }

  @override
  List<Object?> get props => [
    messages,
    selectedModel,
    modelState,
    downloadProgress,
    isGenerating,
    isThinking,
    currentThinkingContent,
    error,
    currentConversationId,
    documents,
  ];
}
```

### BLoC

```dart
// chat_bloc.dart
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GemmaService _gemmaService;
  final RagService _ragService;
  final AppDatabase _database;

  StreamSubscription<String>? _responseSubscription;

  ChatBloc(this._gemmaService, this._ragService, this._database)
      : super(const ChatState()) {
    // Enregistrer les handlers
    on<ChatInitialize>(_onInitialize);
    on<ChatSendMessage>(_onSendMessage);
    on<ChatStreamChunk>(_onStreamChunk);
    on<ChatStreamComplete>(_onStreamComplete);
    on<ChatLoadConversation>(_onLoadConversation);
    on<ChatClearConversation>(_onClearConversation);
    // ... autres handlers
  }

  Future<void> _onInitialize(
    ChatInitialize event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(selectedModel: event.modelInfo));

    await _gemmaService.checkModelStatus(event.modelInfo);

    emit(state.copyWith(
      modelState: _gemmaService.state,
      selectedModel: event.modelInfo,
    ));
  }

  Future<void> _onSendMessage(
    ChatSendMessage event,
    Emitter<ChatState> emit,
  ) async {
    // Guard clauses
    if (!_gemmaService.isReady || state.isGenerating) return;

    // Creer les messages
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.user,
      content: event.message,
      timestamp: DateTime.now(),
      imageBytes: event.imageBytes,
    );

    final assistantMessage = ChatMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}_assistant',
      role: MessageRole.assistant,
      content: '',
      timestamp: DateTime.now(),
      isStreaming: true,
    );

    // Emettre le nouvel etat
    emit(state.copyWith(
      messages: [...state.messages, userMessage, assistantMessage],
      isGenerating: true,
    ));

    // Construire le prompt (avec RAG si necessaire)
    String promptToSend = event.message;
    if (state.hasActiveDocuments && _ragService.isReady) {
      promptToSend = await _ragService.buildAugmentedPrompt(
        userQuery: event.message,
      );
    }

    // Lancer la generation
    _responseSubscription?.cancel();
    _responseSubscription = _gemmaService
        .generateResponse(promptToSend, imageBytes: event.imageBytes)
        .listen(
          (chunk) => add(ChatStreamChunk(chunk)),
          onDone: () => add(const ChatStreamComplete()),
          onError: (e) => add(ChatStreamError(e.toString())),
        );
  }

  void _onStreamChunk(
    ChatStreamChunk event,
    Emitter<ChatState> emit,
  ) {
    if (state.messages.isEmpty) return;

    final messages = List<ChatMessage>.from(state.messages);
    final lastMessage = messages.last;

    if (lastMessage.role == MessageRole.assistant) {
      messages[messages.length - 1] = lastMessage.copyWith(
        content: lastMessage.content + event.chunk,
      );
      emit(state.copyWith(messages: messages));
    }
  }

  Future<void> _onStreamComplete(
    ChatStreamComplete event,
    Emitter<ChatState> emit,
  ) async {
    if (state.messages.isEmpty) return;

    final messages = List<ChatMessage>.from(state.messages);
    final lastMessage = messages.last;

    if (lastMessage.role == MessageRole.assistant) {
      messages[messages.length - 1] = lastMessage.copyWith(
        isStreaming: false,
      );

      emit(state.copyWith(
        messages: messages,
        isGenerating: false,
      ));
    }
  }

  @override
  Future<void> close() {
    _responseSubscription?.cancel();
    return super.close();
  }
}
```

## Utilisation dans l'UI

### Fournir le BLoC

```dart
class ChatPage extends StatelessWidget {
  final GemmaModelInfo modelInfo;

  const ChatPage({required this.modelInfo});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ChatBloc>()
        ..add(ChatInitialize(modelInfo))
        ..add(const ChatLoadDocuments()),
      child: const _ChatPageContent(),
    );
  }
}
```

### Consommer le state

```dart
class _ChatPageContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        if (!state.isModelReady) {
          return ModelStatusCard(state: state);
        }

        return Column(
          children: [
            Expanded(child: MessageList(messages: state.messages)),
            ChatInputBar(isGenerating: state.isGenerating),
          ],
        );
      },
    );
  }
}
```

### Dispatcher des events

```dart
class ChatInputBar extends StatelessWidget {
  final bool isGenerating;

  const ChatInputBar({required this.isGenerating});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onSubmitted: (text) {
        if (text.isNotEmpty && !isGenerating) {
          context.read<ChatBloc>().add(
            ChatSendMessage(message: text),
          );
        }
      },
    );
  }
}
```

### Ecouter les changements

```dart
BlocListener<ChatBloc, ChatState>(
  listenWhen: (previous, current) => current.error != null,
  listener: (context, state) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(state.error!)),
    );
  },
  child: // ...
)
```

### Combiner Builder et Listener

```dart
BlocConsumer<ChatBloc, ChatState>(
  listenWhen: (previous, current) => current.error != null,
  listener: (context, state) {
    // Effets de bord (snackbar, navigation, etc.)
  },
  buildWhen: (previous, current) => previous.messages != current.messages,
  builder: (context, state) {
    // Construire l'UI
    return MessageList(messages: state.messages);
  },
)
```

## Tests

```dart
group('ChatBloc', () {
  late ChatBloc bloc;
  late MockGemmaService mockGemmaService;
  late MockRagService mockRagService;
  late AppDatabase mockDatabase;

  setUp(() {
    mockGemmaService = MockGemmaService();
    mockRagService = MockRagService();
    mockDatabase = AppDatabase.forTesting(NativeDatabase.memory());

    when(() => mockGemmaService.isReady).thenReturn(true);

    bloc = ChatBloc(mockGemmaService, mockRagService, mockDatabase);
  });

  tearDown(() {
    bloc.close();
    mockDatabase.close();
  });

  blocTest<ChatBloc, ChatState>(
    'emits isGenerating true when sending message',
    build: () {
      when(() => mockGemmaService.generateResponse(any()))
          .thenAnswer((_) => Stream.value('Response'));
      return bloc;
    },
    act: (bloc) => bloc.add(const ChatSendMessage(message: 'Hello')),
    expect: () => [
      isA<ChatState>().having((s) => s.isGenerating, 'isGenerating', true),
      // ... autres etats attendus
    ],
  );
});
```
