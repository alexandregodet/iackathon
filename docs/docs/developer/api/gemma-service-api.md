---
sidebar_position: 1
title: GemmaService API
description: Reference API du service GemmaService
---

# GemmaService API

Reference complete de l'API du service `GemmaService`.

## Classe

```dart
@singleton
class GemmaService
```

Service singleton responsable de l'inference des modeles Gemma/DeepSeek localement.

---

## Proprietes

### state

```dart
GemmaModelState get state
```

Retourne l'etat actuel du modele.

**Retour** : `GemmaModelState` - L'etat du modele

---

### isReady

```dart
bool get isReady
```

Indique si le modele est pret pour l'inference.

**Retour** : `true` si `state == GemmaModelState.ready`

---

### currentModel

```dart
GemmaModelInfo? get currentModel
```

Retourne les informations du modele actuellement charge.

**Retour** : `GemmaModelInfo` ou `null` si aucun modele

---

### isMultimodal

```dart
bool get isMultimodal
```

Indique si le modele actuel supporte les images.

**Retour** : `true` si le modele supporte la vision

---

### supportsThinking

```dart
bool get supportsThinking
```

Indique si le modele actuel supporte le mode reflexion.

**Retour** : `true` pour DeepSeek R1

---

### downloadProgress

```dart
double get downloadProgress
```

Progression du telechargement (0.0 a 1.0).

**Retour** : `double` entre 0.0 et 1.0

---

### errorMessage

```dart
String? get errorMessage
```

Message d'erreur si l'etat est `error`.

**Retour** : Message d'erreur ou `null`

---

### systemPrompt

```dart
String? get systemPrompt
```

Prompt systeme configure.

**Retour** : Prompt systeme ou `null`

---

### stateStream

```dart
Stream<GemmaModelState> get stateStream
```

Stream des changements d'etat du modele.

**Retour** : Stream de `GemmaModelState`

---

### progressStream

```dart
Stream<double> get progressStream
```

Stream de la progression du telechargement.

**Retour** : Stream de `double`

---

## Methodes

### checkModelStatus

```dart
Future<void> checkModelStatus(GemmaModelInfo modelInfo)
```

Verifie si le modele est telecharge sur l'appareil.

**Parametres** :
- `modelInfo` : Informations du modele a verifier

**Effets** :
- Met a jour `state` vers `installed` ou `notDownloaded`
- Met a jour `currentModel`
- Emet sur `stateStream`

---

### downloadModel

```dart
Future<void> downloadModel(
  GemmaModelInfo modelInfo, {
  void Function(double)? onProgress,
  String? token,
})
```

Telecharge le modele depuis le CDN.

**Parametres** :
- `modelInfo` : Informations du modele a telecharger
- `onProgress` : Callback de progression (0.0 a 1.0)
- `token` : Token HuggingFace (optionnel, pour modeles proteges)

**Effets** :
- Met a jour `state` vers `downloading` puis `installed`
- Emet sur `stateStream` et `progressStream`

**Exceptions** :
- Peut lever une exception en cas d'erreur reseau

**Exemple** :
```dart
await gemmaService.downloadModel(
  AvailableModels.gemma3_1b,
  onProgress: (progress) {
    print('Download: ${(progress * 100).toStringAsFixed(1)}%');
  },
);
```

---

### loadModel

```dart
Future<void> loadModel([GemmaModelInfo? modelInfo])
```

Charge le modele en memoire pour l'inference.

**Parametres** :
- `modelInfo` : Modele a charger (optionnel si deja defini)

**Effets** :
- Met a jour `state` vers `loading` puis `ready`
- Emet sur `stateStream`

**Exceptions** :
- `StateError` si aucun modele n'est selectionne

---

### unloadModel

```dart
Future<void> unloadModel()
```

Decharge le modele de la memoire.

**Effets** :
- Met a jour `state` vers `installed`
- Libere la memoire

---

### generateResponse

```dart
Stream<String> generateResponse(
  String userMessage, {
  Uint8List? imageBytes,
})
```

Genere une reponse en streaming.

**Parametres** :
- `userMessage` : Message de l'utilisateur
- `imageBytes` : Image en bytes (optionnel, modeles multimodaux)

**Retour** : Stream de tokens (chunks de texte)

**Exceptions** :
- `StateError` si le modele n'est pas pret

**Exemple** :
```dart
await for (final chunk in gemmaService.generateResponse('Hello!')) {
  print(chunk); // Affiche chaque token
}
```

---

### generateResponseWithThinking

```dart
Stream<GemmaStreamResponse> generateResponseWithThinking(
  String userMessage, {
  Uint8List? imageBytes,
})
```

Genere une reponse avec mode reflexion (DeepSeek R1).

**Parametres** :
- `userMessage` : Message de l'utilisateur
- `imageBytes` : Image en bytes (optionnel)

**Retour** : Stream de `GemmaStreamResponse`

**Exceptions** :
- `StateError` si le modele ne supporte pas le thinking

**Exemple** :
```dart
await for (final response in gemmaService.generateResponseWithThinking('2+2?')) {
  if (response.isThinkingPhase) {
    print('Thinking: ${response.thinkingChunk}');
  } else {
    print('Response: ${response.textChunk}');
  }
}
```

---

### generateResponseSync

```dart
Future<String> generateResponseSync(String userMessage)
```

Genere une reponse complete (non-streaming).

**Parametres** :
- `userMessage` : Message de l'utilisateur

**Retour** : Reponse complete

---

### setSystemPrompt

```dart
void setSystemPrompt(String? prompt)
```

Definit le prompt systeme.

**Parametres** :
- `prompt` : Prompt systeme ou `null` pour desactiver

---

### setHuggingFaceToken

```dart
void setHuggingFaceToken(String? token)
```

Definit le token HuggingFace pour les modeles proteges.

**Parametres** :
- `prompt` : Token HuggingFace

---

### clearChat

```dart
Future<void> clearChat()
```

Reinitialise le contexte de conversation.

---

### dispose

```dart
void dispose()
```

Libere les ressources (streams, subscriptions).

---

## Types associes

### GemmaModelState

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

### GemmaStreamResponse

```dart
class GemmaStreamResponse {
  final String? textChunk;
  final String? thinkingChunk;
  final bool isThinkingPhase;

  const GemmaStreamResponse({
    this.textChunk,
    this.thinkingChunk,
    required this.isThinkingPhase,
  });
}
```
