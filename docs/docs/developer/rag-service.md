---
sidebar_position: 5
title: RagService
description: Service de Retrieval-Augmented Generation pour les documents PDF
---

# RagService

Le `RagService` gere le traitement des documents PDF et la recherche semantique pour augmenter les reponses de l'IA avec du contenu pertinent.

## Vue d'ensemble

```dart
@singleton
class RagService {
  // Etat
  bool get isReady;
  EmbedderState get embedderState;

  // Gestion de l'embedder
  Future<void> checkEmbedderStatus();
  Future<void> downloadEmbedder({void Function(double)?});
  Future<void> loadEmbedder();

  // Documents
  Future<DocumentInfo> processDocument(String filePath);
  Future<List<DocumentInfo>> getProcessedDocuments();
  Future<void> removeDocument(int documentId);

  // Recherche
  Future<String> buildAugmentedPrompt({
    required String userQuery,
    int topK = 3,
    double threshold = 0.5,
  });
}
```

## Architecture RAG

```
+-------------+     +-------------+     +-------------+
|    PDF      | --> | Extraction  | --> |   Chunks    |
+-------------+     +-------------+     +-------------+
                                              |
                                              v
+-------------+     +-------------+     +-------------+
|   Prompt    | <-- |   Search    | <-- | Embeddings  |
|  augmente   |     | semantique  |     +-------------+
+-------------+     +-------------+
```

## Etats de l'embedder

```dart
enum EmbedderState {
  notDownloaded,  // Modele d'embeddings non telecharge
  downloading,    // Telechargement en cours
  installed,      // Telecharge mais non charge
  loading,        // Chargement en cours
  ready,          // Pret pour l'indexation
  error,          // Erreur
}
```

## Gestion de l'embedder

L'embedder est un modele separe pour calculer les vecteurs d'embedding.

### Verifier le statut

```dart
Future<void> checkEmbedderStatus() async {
  final embedderPath = await _getEmbedderPath();
  final file = File(embedderPath);

  if (await file.exists()) {
    _embedderState = EmbedderState.installed;
  } else {
    _embedderState = EmbedderState.notDownloaded;
  }
}
```

### Telecharger l'embedder

```dart
Future<void> downloadEmbedder({
  void Function(double)? onProgress,
}) async {
  _embedderState = EmbedderState.downloading;

  await FlutterGemma.instance.downloadEmbedder(
    _embedderUrl,
    _embedderFilename,
    onProgress: onProgress,
  );

  _embedderState = EmbedderState.installed;
}
```

### Charger l'embedder

```dart
Future<void> loadEmbedder() async {
  _embedderState = EmbedderState.loading;

  await FlutterGemma.instance.loadEmbedder(
    modelPath: _embedderFilename,
  );

  _embedderState = EmbedderState.ready;
}
```

## Traitement des documents

### processDocument

```dart
Future<DocumentInfo> processDocument(String filePath) async {
  if (!isReady) {
    throw StateError('Embedder not ready');
  }

  // 1. Extraire le texte du PDF
  final text = await _extractTextFromPdf(filePath);

  // 2. Decouper en chunks
  final chunks = _splitIntoChunks(text);

  // 3. Calculer les embeddings
  final embeddings = await _computeEmbeddings(chunks);

  // 4. Sauvegarder en base
  final document = await _saveDocument(
    filePath: filePath,
    chunks: chunks,
    embeddings: embeddings,
  );

  return document;
}
```

### Extraction du texte

```dart
Future<String> _extractTextFromPdf(String filePath) async {
  final doc = await PDFDoc.fromPath(filePath);
  final buffer = StringBuffer();

  for (int i = 1; i <= doc.length; i++) {
    final page = await doc.pageAt(i);
    final text = await page.text;
    buffer.writeln(text);
  }

  return buffer.toString();
}
```

### Decoupage en chunks

```dart
List<String> _splitIntoChunks(
  String text, {
  int chunkSize = 500,
  int overlap = 50,
}) {
  final chunks = <String>[];
  final words = text.split(RegExp(r'\s+'));

  int start = 0;
  while (start < words.length) {
    final end = (start + chunkSize).clamp(0, words.length);
    final chunk = words.sublist(start, end).join(' ');
    chunks.add(chunk);

    start += chunkSize - overlap;
  }

  return chunks;
}
```

### Calcul des embeddings

```dart
Future<List<List<double>>> _computeEmbeddings(List<String> chunks) async {
  final embeddings = <List<double>>[];

  for (final chunk in chunks) {
    final embedding = await FlutterGemma.instance.computeEmbedding(chunk);
    embeddings.add(embedding);
  }

  return embeddings;
}
```

## Recherche semantique

### buildAugmentedPrompt

```dart
Future<String> buildAugmentedPrompt({
  required String userQuery,
  int topK = 3,
  double threshold = 0.5,
}) async {
  // 1. Calculer l'embedding de la requete
  final queryEmbedding = await FlutterGemma.instance.computeEmbedding(userQuery);

  // 2. Rechercher les chunks les plus similaires
  final results = await _searchSimilarChunks(
    queryEmbedding,
    topK: topK,
    threshold: threshold,
  );

  if (results.isEmpty) {
    return userQuery; // Pas de contexte trouve
  }

  // 3. Construire le prompt augmente
  final context = results.map((r) => r.text).join('\n\n');

  return '''
Contexte (extrait de documents):
$context

Question de l'utilisateur: $userQuery

Reponds a la question en te basant sur le contexte fourni. Si le contexte ne contient pas l'information, dis-le clairement.
''';
}
```

### Recherche de similarite

```dart
Future<List<SearchResult>> _searchSimilarChunks(
  List<double> queryEmbedding, {
  required int topK,
  required double threshold,
}) async {
  final results = <SearchResult>[];

  // Recuperer tous les documents actifs
  final activeDocuments = await _getActiveDocuments();

  for (final doc in activeDocuments) {
    for (int i = 0; i < doc.chunks.length; i++) {
      final similarity = _cosineSimilarity(
        queryEmbedding,
        doc.embeddings[i],
      );

      if (similarity >= threshold) {
        results.add(SearchResult(
          documentId: doc.id,
          chunkIndex: i,
          text: doc.chunks[i],
          similarity: similarity,
        ));
      }
    }
  }

  // Trier par similarite decroissante et prendre topK
  results.sort((a, b) => b.similarity.compareTo(a.similarity));
  return results.take(topK).toList();
}

double _cosineSimilarity(List<double> a, List<double> b) {
  double dotProduct = 0;
  double normA = 0;
  double normB = 0;

  for (int i = 0; i < a.length; i++) {
    dotProduct += a[i] * b[i];
    normA += a[i] * a[i];
    normB += b[i] * b[i];
  }

  return dotProduct / (sqrt(normA) * sqrt(normB));
}
```

## Gestion des documents

### Structure DocumentInfo

```dart
class DocumentInfo {
  final int id;
  final String name;
  final String filePath;
  final int totalChunks;
  final DateTime createdAt;
  final DateTime? lastUsedAt;
  final bool isActive;

  const DocumentInfo({...});
}
```

### Operations CRUD

```dart
// Recuperer tous les documents
Future<List<DocumentInfo>> getProcessedDocuments() async {
  final docs = await _database.select(_database.documents).get();
  return docs.map((d) => DocumentInfo.fromDb(d)).toList();
}

// Activer/desactiver un document
Future<void> toggleDocument(int documentId, bool isActive) async {
  await (_database.update(_database.documents)
    ..where((d) => d.id.equals(documentId)))
    .write(DocumentsCompanion(isActive: Value(isActive)));
}

// Supprimer un document
Future<void> removeDocument(int documentId) async {
  await (_database.delete(_database.documents)
    ..where((d) => d.id.equals(documentId)))
    .go();
}
```

## Integration avec ChatBloc

```dart
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  Future<void> _onSendMessage(
    ChatSendMessage event,
    Emitter<ChatState> emit,
  ) async {
    String promptToSend = event.message;

    // Augmenter le prompt si des documents sont actifs
    if (state.hasActiveDocuments && _ragService.isReady) {
      promptToSend = await _ragService.buildAugmentedPrompt(
        userQuery: event.message,
        topK: 3,
        threshold: 0.5,
      );
    }

    // Envoyer le prompt augmente au modele
    _responseSubscription = _gemmaService
        .generateResponse(promptToSend)
        .listen((chunk) => add(ChatStreamChunk(chunk)));
  }
}
```

## Mock pour les tests

```dart
class MockRagService extends Mock implements RagService {
  EmbedderState _embedderState = EmbedderState.ready;
  final List<DocumentInfo> _documents = [];

  @override
  bool get isReady => _embedderState == EmbedderState.ready;

  @override
  EmbedderState get embedderState => _embedderState;

  void setEmbedderState(EmbedderState state) {
    _embedderState = state;
  }

  @override
  Future<String> buildAugmentedPrompt({
    required String userQuery,
    int topK = 3,
    double threshold = 0.5,
  }) async {
    // En mode test, retourner la query telle quelle
    return userQuery;
  }

  @override
  Future<List<DocumentInfo>> getProcessedDocuments() async {
    return _documents;
  }
}
```
