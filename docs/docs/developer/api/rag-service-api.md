---
sidebar_position: 2
title: RagService API
description: Reference API du service RagService
---

# RagService API

Reference complete de l'API du service `RagService` pour le traitement des documents PDF.

## Classe

```dart
@singleton
class RagService
```

Service singleton pour le Retrieval-Augmented Generation (RAG).

---

## Proprietes

### isReady

```dart
bool get isReady
```

Indique si l'embedder est pret.

**Retour** : `true` si `embedderState == EmbedderState.ready`

---

### embedderState

```dart
EmbedderState get embedderState
```

Retourne l'etat de l'embedder.

**Retour** : `EmbedderState`

---

### downloadProgress

```dart
double get downloadProgress
```

Progression du telechargement de l'embedder (0.0 a 1.0).

**Retour** : `double` entre 0.0 et 1.0

---

## Methodes

### checkEmbedderStatus

```dart
Future<void> checkEmbedderStatus()
```

Verifie si l'embedder est telecharge sur l'appareil.

**Effets** :
- Met a jour `embedderState` vers `installed` ou `notDownloaded`

---

### downloadEmbedder

```dart
Future<void> downloadEmbedder({
  void Function(double)? onProgress,
})
```

Telecharge le modele d'embeddings.

**Parametres** :
- `onProgress` : Callback de progression (0.0 a 1.0)

**Effets** :
- Met a jour `embedderState` vers `downloading` puis `installed`

**Exemple** :
```dart
await ragService.downloadEmbedder(
  onProgress: (progress) {
    print('Embedder: ${(progress * 100).toStringAsFixed(1)}%');
  },
);
```

---

### loadEmbedder

```dart
Future<void> loadEmbedder()
```

Charge l'embedder en memoire.

**Effets** :
- Met a jour `embedderState` vers `loading` puis `ready`

---

### processDocument

```dart
Future<DocumentInfo> processDocument(String filePath)
```

Traite un document PDF : extraction, chunking, embeddings.

**Parametres** :
- `filePath` : Chemin absolu vers le fichier PDF

**Retour** : `DocumentInfo` avec les metadonnees du document

**Effets** :
- Extrait le texte du PDF
- Decoupe en chunks de ~500 tokens
- Calcule les embeddings pour chaque chunk
- Sauvegarde en base de donnees

**Exceptions** :
- `StateError` si l'embedder n'est pas pret
- `FileSystemException` si le fichier n'existe pas

**Exemple** :
```dart
final doc = await ragService.processDocument('/path/to/document.pdf');
print('Processed ${doc.totalChunks} chunks');
```

---

### getProcessedDocuments

```dart
Future<List<DocumentInfo>> getProcessedDocuments()
```

Retourne la liste des documents traites.

**Retour** : Liste de `DocumentInfo`

---

### getActiveDocuments

```dart
Future<List<DocumentInfo>> getActiveDocuments()
```

Retourne la liste des documents actifs (utilises pour le RAG).

**Retour** : Liste de `DocumentInfo` ou `isActive == true`

---

### toggleDocument

```dart
Future<void> toggleDocument(int documentId, bool isActive)
```

Active ou desactive un document pour le RAG.

**Parametres** :
- `documentId` : ID du document
- `isActive` : Nouvel etat

---

### removeDocument

```dart
Future<void> removeDocument(int documentId)
```

Supprime un document et ses embeddings.

**Parametres** :
- `documentId` : ID du document a supprimer

---

### buildAugmentedPrompt

```dart
Future<String> buildAugmentedPrompt({
  required String userQuery,
  int topK = 3,
  double threshold = 0.5,
})
```

Construit un prompt augmente avec le contexte des documents.

**Parametres** :
- `userQuery` : Question de l'utilisateur
- `topK` : Nombre max de chunks a inclure (defaut: 3)
- `threshold` : Seuil de similarite minimum (defaut: 0.5)

**Retour** : Prompt augmente avec contexte, ou `userQuery` si aucun contexte trouve

**Algorithme** :
1. Calcule l'embedding de la requete
2. Recherche les chunks les plus similaires dans les documents actifs
3. Filtre par seuil de similarite
4. Construit le prompt avec le contexte

**Exemple** :
```dart
final prompt = await ragService.buildAugmentedPrompt(
  userQuery: 'Quel est le sujet du document ?',
  topK: 3,
  threshold: 0.5,
);

// Resultat:
// Contexte (extrait de documents):
// [chunk 1]
// [chunk 2]
// [chunk 3]
//
// Question de l'utilisateur: Quel est le sujet du document ?
```

---

### searchSimilarChunks

```dart
Future<List<SearchResult>> searchSimilarChunks(
  String query, {
  int topK = 5,
  double threshold = 0.3,
})
```

Recherche les chunks similaires a une requete.

**Parametres** :
- `query` : Texte de recherche
- `topK` : Nombre max de resultats
- `threshold` : Seuil de similarite minimum

**Retour** : Liste de `SearchResult` triee par similarite

---

## Types associes

### EmbedderState

```dart
enum EmbedderState {
  notDownloaded,  // Embedder non telecharge
  downloading,    // Telechargement en cours
  installed,      // Telecharge mais non charge
  loading,        // Chargement en cours
  ready,          // Pret pour l'indexation
  error,          // Erreur
}
```

### DocumentInfo

```dart
class DocumentInfo {
  final int id;
  final String name;
  final String filePath;
  final int totalChunks;
  final DateTime createdAt;
  final DateTime? lastUsedAt;
  final bool isActive;

  const DocumentInfo({
    required this.id,
    required this.name,
    required this.filePath,
    required this.totalChunks,
    required this.createdAt,
    this.lastUsedAt,
    this.isActive = false,
  });
}
```

### SearchResult

```dart
class SearchResult {
  final int documentId;
  final int chunkIndex;
  final String text;
  final double similarity;

  const SearchResult({
    required this.documentId,
    required this.chunkIndex,
    required this.text,
    required this.similarity,
  });
}
```

---

## Constantes

### Parametres de chunking

```dart
const int defaultChunkSize = 500;    // Tokens par chunk
const int defaultOverlap = 50;       // Tokens de chevauchement
```

### Parametres de recherche

```dart
const int defaultTopK = 3;           // Chunks max par recherche
const double defaultThreshold = 0.5; // Seuil de similarite
```
