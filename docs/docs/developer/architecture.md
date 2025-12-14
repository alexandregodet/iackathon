---
sidebar_position: 1
title: Architecture
description: Vue d'ensemble de l'architecture de IAckathon
---

# Architecture de IAckathon

Ce document presente l'architecture globale de l'application IAckathon, un assistant IA local construit avec Flutter.

## Vue d'ensemble

IAckathon est une application Flutter Android qui execute des modeles d'IA (Gemma, DeepSeek) localement sur l'appareil. L'architecture suit les principes de **Clean Architecture** pour assurer la maintenabilite et la testabilite.

```
+--------------------------------------------------+
|                    UI Layer                       |
|  (Pages, Widgets, BLoC)                          |
+--------------------------------------------------+
                        |
                        v
+--------------------------------------------------+
|                 Domain Layer                      |
|  (Entities, Use Cases, Repository Interfaces)    |
+--------------------------------------------------+
                        |
                        v
+--------------------------------------------------+
|                  Data Layer                       |
|  (Services, Repositories, Data Sources)          |
+--------------------------------------------------+
                        |
                        v
+--------------------------------------------------+
|               Infrastructure                      |
|  (flutter_gemma, Drift, SharedPreferences)       |
+--------------------------------------------------+
```

## Stack technique

### Framework et langage

| Technologie | Version | Usage |
|-------------|---------|-------|
| Flutter | 3.10+ | Framework UI multiplateforme |
| Dart | 3.10+ | Langage de programmation |

### Dependances principales

| Package | Usage |
|---------|-------|
| `flutter_gemma` | Inference locale des modeles Gemma |
| `flutter_bloc` | Gestion d'etat avec le pattern BLoC |
| `get_it` + `injectable` | Injection de dependances |
| `drift` | Base de donnees SQLite locale |
| `read_pdf_text` | Extraction de texte PDF |

## Composants principaux

### 1. GemmaService

Service singleton responsable de l'inference IA :

```dart
@singleton
class GemmaService {
  // Gestion du cycle de vie du modele
  Future<void> checkModelStatus(GemmaModelInfo modelInfo);
  Future<void> downloadModel(GemmaModelInfo modelInfo, {...});
  Future<void> loadModel([GemmaModelInfo? modelInfo]);

  // Generation de texte
  Stream<String> generateResponse(String userMessage, {Uint8List? imageBytes});
  Stream<GemmaStreamResponse> generateResponseWithThinking(String userMessage, {...});
}
```

### 2. RagService

Service pour le traitement des documents PDF (Retrieval-Augmented Generation) :

```dart
@singleton
class RagService {
  // Gestion des documents
  Future<DocumentInfo> processDocument(String filePath);
  Future<List<DocumentInfo>> getProcessedDocuments();

  // Recherche semantique
  Future<String> buildAugmentedPrompt({
    required String userQuery,
    int topK = 3,
    double threshold = 0.5,
  });
}
```

### 3. ChatBloc

BLoC principal gerant l'etat du chat :

```dart
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc(this._gemmaService, this._ragService, this._database);

  // Evenements geres
  on<ChatInitialize>(_onInitialize);
  on<ChatSendMessage>(_onSendMessage);
  on<ChatStreamChunk>(_onStreamChunk);
  on<ChatLoadConversation>(_onLoadConversation);
  // ... autres evenements
}
```

### 4. AppDatabase (Drift)

Base de donnees SQLite pour la persistance :

```dart
@DriftDatabase(tables: [Conversations, Messages, Documents, PromptTemplates])
class AppDatabase extends _$AppDatabase {
  // Tables:
  // - Conversations: historique des conversations
  // - Messages: messages de chaque conversation
  // - Documents: metadonnees des PDFs importes
  // - PromptTemplates: modeles de prompts sauvegardes
}
```

## Flux de donnees

### Envoi d'un message

```
1. Utilisateur tape un message
      |
      v
2. ChatPage appelle ChatBloc.add(ChatSendMessage(message))
      |
      v
3. ChatBloc._onSendMessage:
   - Verifie que le modele est pret
   - Ajoute le message utilisateur a l'etat
   - Construit le prompt (avec RAG si documents actifs)
   - Appelle GemmaService.generateResponse()
      |
      v
4. GemmaService stream les tokens de reponse
      |
      v
5. ChatBloc emet ChatStreamChunk pour chaque token
      |
      v
6. ChatPage rebuild avec le nouveau contenu
      |
      v
7. ChatStreamComplete: message finalise et sauvegarde en DB
```

### Traitement d'un document PDF

```
1. Utilisateur selectionne un PDF
      |
      v
2. RagService.processDocument(filePath):
   - Extraction du texte (pdf_text)
   - Decoupage en chunks (500 tokens, overlap 50)
   - Calcul des embeddings
   - Stockage en base (Documents table)
      |
      v
3. Document marque comme disponible
      |
      v
4. Lors d'une question:
   - Calcul de l'embedding de la question
   - Recherche des chunks les plus similaires
   - Construction du prompt augmente
   - Envoi au modele
```

## Injection de dependances

L'application utilise `get_it` avec `injectable` pour le DI :

```dart
// lib/core/di/injection.dart
final getIt = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies() async {
  getIt.init();
}

// Usage
final gemmaService = getIt<GemmaService>();
```

### Enregistrements

```dart
// Singletons (une instance pour toute l'app)
gh.singleton<AppDatabase>(() => AppDatabase());
gh.singleton<GemmaService>(() => GemmaService());
gh.singleton<RagService>(() => RagService());
gh.singleton<SettingsService>(() => SettingsService());

// Factory (nouvelle instance a chaque demande)
gh.factory<ChatBloc>(() => ChatBloc(
  gh<GemmaService>(),
  gh<RagService>(),
  gh<AppDatabase>(),
));
```

## Gestion d'etat

### Pattern BLoC

L'application utilise le pattern BLoC (Business Logic Component) :

```
+------------+    Event    +-------+    State    +--------+
|    UI      | ---------> | BLoC  | ---------> |   UI   |
| (dispatch) |            |       |            | (build)|
+------------+            +-------+            +--------+
```

### ChatState

```dart
class ChatState extends Equatable {
  final List<ChatMessage> messages;
  final GemmaModelInfo? selectedModel;
  final GemmaModelState modelState;
  final bool isGenerating;
  final bool isThinking;
  final String? currentThinkingContent;
  final List<DocumentInfo> documents;
  final int? currentConversationId;
  // ...
}
```

## Securite et confidentialite

### Donnees locales uniquement

- **Aucune API externe** : Tout le traitement IA est local
- **Base SQLite chiffree** : Option disponible via SQLCipher
- **Pas de telemetrie** : Aucune donnee n'est collectee

### Permissions minimales

```xml
<!-- AndroidManifest.xml -->
<uses-permission android:name="android.permission.INTERNET" />
<!-- Uniquement pour telecharger les modeles initiaux -->
```

## Performance

### Optimisations implementees

1. **Streaming des reponses** : Affichage progressif des tokens
2. **Lazy loading** : Chargement des conversations a la demande
3. **Memory management** : Decharger le modele si inactif
4. **Background processing** : Traitement PDF en arriere-plan

### Metriques cibles

| Metrique | Cible |
|----------|-------|
| Temps de chargement du modele | < 15s |
| Premier token | < 1s |
| Tokens par seconde | > 10 t/s |
| RAM usage (1B model) | < 3 Go |
