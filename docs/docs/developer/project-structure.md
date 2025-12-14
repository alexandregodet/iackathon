---
sidebar_position: 2
title: Structure du projet
description: Organisation des fichiers et dossiers du projet
---

# Structure du projet

Ce document detaille l'organisation des fichiers et dossiers du projet IAckathon.

## Arborescence principale

```
iackathon/
├── lib/                          # Code source Dart
│   ├── core/                     # Configuration et utilitaires
│   │   ├── di/                   # Injection de dependances
│   │   │   ├── injection.dart
│   │   │   └── injection.config.dart
│   │   ├── errors/               # Gestion des erreurs
│   │   │   └── app_errors.dart
│   │   ├── utils/                # Utilitaires
│   │   │   ├── app_logger.dart
│   │   │   └── connectivity_checker.dart
│   │   └── theme/                # Theme de l'application
│   │       └── app_theme.dart
│   │
│   ├── data/                     # Couche donnees
│   │   └── datasources/          # Sources de donnees
│   │       ├── database.dart     # Drift database
│   │       ├── database.g.dart   # Code genere
│   │       ├── gemma_service.dart
│   │       ├── rag_service.dart
│   │       ├── settings_service.dart
│   │       ├── tts_service.dart
│   │       └── prompt_template_service.dart
│   │
│   ├── domain/                   # Couche domaine
│   │   └── entities/             # Entites metier
│   │       ├── chat_message.dart
│   │       ├── conversation_info.dart
│   │       ├── document_info.dart
│   │       └── gemma_model_info.dart
│   │
│   ├── presentation/             # Couche presentation
│   │   ├── blocs/                # BLoCs (gestion d'etat)
│   │   │   └── chat/
│   │   │       ├── chat_bloc.dart
│   │   │       ├── chat_event.dart
│   │   │       └── chat_state.dart
│   │   │
│   │   ├── pages/                # Pages/Ecrans
│   │   │   ├── home_page.dart
│   │   │   ├── chat_page.dart
│   │   │   ├── model_selection_page.dart
│   │   │   ├── settings_page.dart
│   │   │   ├── conversations_page.dart
│   │   │   └── prompt_templates_page.dart
│   │   │
│   │   └── widgets/              # Widgets reutilisables
│   │       ├── chat_bubble.dart
│   │       └── model_status_card.dart
│   │
│   └── main.dart                 # Point d'entree
│
├── integration_test/             # Tests d'integration
│   ├── app_test.dart
│   ├── mocks/                    # Services mockes
│   │   ├── mock_gemma_service.dart
│   │   ├── mock_rag_service.dart
│   │   ├── mock_tts_service.dart
│   │   └── mock_settings_service.dart
│   └── utils/
│       └── test_app.dart
│
├── test/                         # Tests unitaires
│   └── ...
│
├── test_driver/                  # Driver pour tests d'integration
│   └── integration_test.dart
│
├── android/                      # Code natif Android
│   ├── app/
│   │   └── src/main/
│   │       ├── AndroidManifest.xml
│   │       └── kotlin/...
│   └── build.gradle
│
├── docs/                         # Documentation Docusaurus
│   ├── docs/
│   │   ├── user-guide/
│   │   └── developer/
│   ├── docusaurus.config.ts
│   └── sidebars.ts
│
├── pubspec.yaml                  # Dependances Flutter
├── pubspec.lock
├── analysis_options.yaml         # Regles de linting
└── README.md
```

## Description des dossiers

### `/lib/core/`

Configuration globale de l'application.

#### `/lib/core/di/`

Injection de dependances avec `get_it` et `injectable` :

```dart
// injection.dart
final getIt = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies() async {
  getIt.init();
}

Future<void> resetGetIt() async {
  await getIt.reset();
}
```

#### `/lib/core/errors/`

Gestion centralisee des erreurs :

```dart
// app_errors.dart
class AppError implements Exception {
  final String message;
  final String? code;
  // ...
}
```

#### `/lib/core/utils/`

Utilitaires de l'application :

- `app_logger.dart` : Logger centralise pour le debug
- `connectivity_checker.dart` : Verification de la connectivite reseau

#### `/lib/core/theme/`

Theme et styles de l'application :

```dart
// app_theme.dart
class AppTheme {
  static ThemeData get lightTheme { ... }
  static ThemeData get darkTheme { ... }
}
```

### `/lib/data/datasources/`

Services et sources de donnees :

| Fichier | Description |
|---------|-------------|
| `database.dart` | Schema et configuration Drift |
| `gemma_service.dart` | Interface avec flutter_gemma |
| `rag_service.dart` | Traitement PDF et embeddings |
| `settings_service.dart` | Preferences utilisateur |
| `tts_service.dart` | Synthese vocale |
| `prompt_template_service.dart` | CRUD modeles de prompts |

### `/lib/domain/entities/`

Entites metier pures (pas de dependances externes) :

```dart
// chat_message.dart
class ChatMessage {
  final String id;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final bool isStreaming;
  final Uint8List? imageBytes;
  final String? thinkingContent;
}
```

### `/lib/presentation/blocs/`

BLoCs pour la gestion d'etat :

```
chat/
├── chat_bloc.dart    # Logique metier
├── chat_event.dart   # Evenements entrants
└── chat_state.dart   # Etat immutable
```

### `/lib/presentation/pages/`

Ecrans de l'application :

| Page | Route | Description |
|------|-------|-------------|
| `home_page.dart` | `/` | Ecran d'accueil |
| `model_selection_page.dart` | `/models` | Selection du modele |
| `chat_page.dart` | `/chat` | Interface de chat |
| `settings_page.dart` | `/settings` | Parametres |
| `conversations_page.dart` | `/conversations` | Historique |
| `prompt_templates_page.dart` | `/templates` | Modeles de prompts |

### `/integration_test/`

Tests E2E avec le framework `integration_test` :

```
integration_test/
├── app_test.dart           # Tests principaux
├── mocks/                  # Services mockes
│   ├── mock_gemma_service.dart
│   ├── mock_rag_service.dart
│   └── ...
└── utils/
    └── test_app.dart       # Configuration de test
```

## Fichiers de configuration

### `pubspec.yaml`

```yaml
name: iackathon
description: Assistant IA local avec Gemma

environment:
  sdk: '>=3.4.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  flutter_gemma: ^x.x.x
  flutter_bloc: ^x.x.x
  get_it: ^x.x.x
  injectable: ^x.x.x
  drift: ^x.x.x
  # ...

dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  build_runner: ^x.x.x
  injectable_generator: ^x.x.x
  drift_dev: ^x.x.x
  mocktail: ^x.x.x
```

### `analysis_options.yaml`

```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    prefer_single_quotes: true
    require_trailing_commas: true
    avoid_print: true
```

## Generation de code

Certains fichiers sont generes automatiquement :

```bash
# Generer tout le code (DI, Drift, etc.)
flutter pub run build_runner build --delete-conflicting-outputs
```

### Fichiers generes

| Pattern | Generateur | Description |
|---------|------------|-------------|
| `*.g.dart` | Drift | Schema et queries DB |
| `injection.config.dart` | Injectable | Configuration DI |

## Conventions de nommage

### Fichiers

- **snake_case** pour les noms de fichiers : `chat_bloc.dart`
- Un fichier par classe principale
- Suffixes descriptifs : `_page.dart`, `_bloc.dart`, `_service.dart`

### Classes

- **PascalCase** pour les classes : `ChatBloc`
- Suffixes descriptifs : `Page`, `Bloc`, `Service`, `State`, `Event`

### Variables et methodes

- **camelCase** : `sendMessage()`, `currentUser`
- Prefixe `_` pour les membres prives : `_onInitialize()`
