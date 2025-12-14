---
sidebar_position: 3
title: ChatBloc API
description: Reference API du ChatBloc
---

# ChatBloc API

Reference complete de l'API du `ChatBloc` pour la gestion d'etat du chat.

## Classe

```dart
@injectable
class ChatBloc extends Bloc<ChatEvent, ChatState>
```

BLoC principal gerant l'etat du chat et la logique de conversation.

---

## Constructeur

```dart
ChatBloc(
  GemmaService gemmaService,
  RagService ragService,
  AppDatabase database,
)
```

**Parametres** :
- `gemmaService` : Service d'inference IA
- `ragService` : Service RAG pour les documents
- `database` : Base de donnees pour la persistance

---

## Events

### ChatInitialize

```dart
class ChatInitialize extends ChatEvent {
  final GemmaModelInfo modelInfo;

  const ChatInitialize(this.modelInfo);
}
```

Initialise le bloc avec un modele.

**Effet** : Verifie le statut du modele et met a jour l'etat.

---

### ChatDownloadModel

```dart
class ChatDownloadModel extends ChatEvent {
  final String? huggingFaceToken;

  const ChatDownloadModel({this.huggingFaceToken});
}
```

Lance le telechargement du modele selectionne.

---

### ChatLoadModel

```dart
class ChatLoadModel extends ChatEvent {
  const ChatLoadModel();
}
```

Charge le modele en memoire.

---

### ChatSendMessage

```dart
class ChatSendMessage extends ChatEvent {
  final String message;
  final Uint8List? imageBytes;

  const ChatSendMessage({
    required this.message,
    this.imageBytes,
  });
}
```

Envoie un message et lance la generation de reponse.

**Effet** :
1. Ajoute le message utilisateur a l'etat
2. Cree un message assistant vide (streaming)
3. Lance la generation via GemmaService
4. Met a jour le message assistant au fur et a mesure

---

### ChatStreamChunk

```dart
class ChatStreamChunk extends ChatEvent {
  final String chunk;

  const ChatStreamChunk(this.chunk);
}
```

Recoit un chunk de la reponse en streaming.

**Effet** : Ajoute le chunk au message assistant courant.

---

### ChatStreamComplete

```dart
class ChatStreamComplete extends ChatEvent {
  const ChatStreamComplete();
}
```

Marque la fin du streaming.

**Effet** :
- Met `isGenerating` a false
- Marque le message comme non-streaming
- Sauvegarde en base si conversation active

---

### ChatStreamError

```dart
class ChatStreamError extends ChatEvent {
  final String error;

  const ChatStreamError(this.error);
}
```

Gere une erreur de streaming.

---

### ChatClearConversation

```dart
class ChatClearConversation extends ChatEvent {
  const ChatClearConversation();
}
```

Efface tous les messages de la conversation actuelle.

---

### ChatStopGeneration

```dart
class ChatStopGeneration extends ChatEvent {
  const ChatStopGeneration();
}
```

Arrete la generation en cours.

---

### ChatLoadConversation

```dart
class ChatLoadConversation extends ChatEvent {
  final int conversationId;

  const ChatLoadConversation(this.conversationId);
}
```

Charge une conversation depuis la base.

---

### ChatCreateConversation

```dart
class ChatCreateConversation extends ChatEvent {
  final String title;

  const ChatCreateConversation(this.title);
}
```

Cree une nouvelle conversation.

---

### ChatDeleteConversation

```dart
class ChatDeleteConversation extends ChatEvent {
  final int conversationId;

  const ChatDeleteConversation(this.conversationId);
}
```

Supprime une conversation.

---

### ChatDocumentSelected

```dart
class ChatDocumentSelected extends ChatEvent {
  final String filePath;

  const ChatDocumentSelected(this.filePath);
}
```

Lance le traitement d'un document PDF.

---

### ChatToggleDocument

```dart
class ChatToggleDocument extends ChatEvent {
  final int documentId;
  final bool isActive;

  const ChatToggleDocument(this.documentId, this.isActive);
}
```

Active/desactive un document pour le RAG.

---

### ChatThinkingChunk

```dart
class ChatThinkingChunk extends ChatEvent {
  final String chunk;

  const ChatThinkingChunk(this.chunk);
}
```

Recoit un chunk de reflexion (DeepSeek R1).

---

### ChatCopyMessage

```dart
class ChatCopyMessage extends ChatEvent {
  final String content;

  const ChatCopyMessage(this.content);
}
```

Copie le contenu d'un message dans le presse-papiers.

---

### ChatRegenerateMessage

```dart
class ChatRegenerateMessage extends ChatEvent {
  final String originalMessage;

  const ChatRegenerateMessage(this.originalMessage);
}
```

Regenere la reponse pour un message.

---

## State

### ChatState

```dart
class ChatState extends Equatable {
  // Messages
  final List<ChatMessage> messages;

  // Modele
  final GemmaModelInfo? selectedModel;
  final GemmaModelState modelState;
  final double downloadProgress;

  // Generation
  final bool isGenerating;
  final bool isThinking;
  final String? currentThinkingContent;

  // Erreurs
  final String? error;

  // Conversation
  final int? currentConversationId;

  // Documents RAG
  final List<DocumentInfo> documents;
  final bool isProcessingDocument;
  final double documentProgress;

  const ChatState({...});
}
```

### Proprietes helpers

```dart
// Modele pret ?
bool get isModelReady => modelState == GemmaModelState.ready;

// Documents actifs ?
bool get hasActiveDocuments => documents.any((d) => d.isActive);

// Nombre de documents actifs
int get activeDocumentCount => documents.where((d) => d.isActive).length;
```

### copyWith

```dart
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
  bool? isProcessingDocument,
  double? documentProgress,
})
```

Cree une copie de l'etat avec les modifications specifiees.

---

## ChatMessage

```dart
class ChatMessage extends Equatable {
  final String id;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final bool isStreaming;
  final Uint8List? imageBytes;
  final String? thinkingContent;

  const ChatMessage({...});

  ChatMessage copyWith({...});
}

enum MessageRole { user, assistant, system }
```

---

## Usage

### Fournir le BLoC

```dart
BlocProvider(
  create: (_) => getIt<ChatBloc>()
    ..add(ChatInitialize(modelInfo))
    ..add(const ChatLoadDocuments()),
  child: ChatPage(),
)
```

### Dispatcher des events

```dart
context.read<ChatBloc>().add(
  ChatSendMessage(message: 'Hello!'),
);
```

### Ecouter les changements

```dart
BlocBuilder<ChatBloc, ChatState>(
  builder: (context, state) {
    if (!state.isModelReady) {
      return ModelLoadingIndicator();
    }
    return MessageList(messages: state.messages);
  },
)
```

### Ecouter les erreurs

```dart
BlocListener<ChatBloc, ChatState>(
  listenWhen: (prev, curr) => curr.error != null,
  listener: (context, state) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(state.error!)),
    );
  },
  child: // ...
)
```
