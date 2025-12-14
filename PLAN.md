# IAckathon - Plan de Developpement

## Vue d'ensemble

Application Flutter de chat IA avec LLM local (Gemma) et RAG (Retrieval-Augmented Generation) entierement on-device.

### Configuration du projet

| Element | Valeur |
|---------|--------|
| Package ID | `com.iackathon.app` |
| Plateformes | Android, Windows, Web |
| Min Android SDK | 29 (Android 10) |
| Architecture | BLoC (Business Logic Component) |
| Base de donnees | Drift (SQLite) |
| Theme | Material 3 |
| LLM | flutter_gemma 0.11.13 |
| Embeddings | EmbeddingGemma 300M |

---

## Phase 1 : Infrastructure (COMPLETE)

### 1.1 Initialisation du projet
- [x] Creation du projet Flutter
- [x] Configuration des plateformes cibles
- [x] Configuration Android (minSdk 29)

### 1.2 Dependances
- [x] flutter_bloc / bloc - Gestion d'etat
- [x] equatable - Comparaison d'objets
- [x] get_it / injectable - Injection de dependances
- [x] drift / sqlite3_flutter_libs - Base de donnees
- [x] path_provider - Acces aux repertoires systeme

### 1.3 Architecture BLoC
- [x] Structure de dossiers creee :
  ```
  lib/
  ├── core/
  │   ├── di/          # Injection de dependances
  │   ├── theme/       # Themes Material 3
  │   ├── errors/      # Gestion d'erreurs structuree
  │   └── utils/       # Utilitaires (logger, connectivity)
  ├── data/
  │   └── datasources/ # Sources de donnees (DB, Services)
  ├── domain/
  │   └── entities/    # Entites metier
  └── presentation/
      ├── blocs/       # BLoCs
      ├── pages/       # Pages/Ecrans
      └── widgets/     # Widgets reutilisables
  ```

### 1.4 Base de donnees Drift
- [x] Configuration de la base SQLite
- [x] Tables creees :
  - `Conversations` : id, title, createdAt, updatedAt
  - `Messages` : id, conversationId, role, content, createdAt
  - `Documents` : id, name, filePath, totalChunks, isActive, createdAt
  - `PromptTemplates` : id, name, content, category, createdAt

### 1.5 Theme Material 3
- [x] Theme clair configure
- [x] Theme sombre configure
- [x] Support du mode systeme

---

## Phase 2 : Integration flutter_gemma (COMPLETE)

### 2.1 Installation et configuration
- [x] Dependance flutter_gemma 0.11.13
- [x] Permissions Android (Internet, OpenCL, largeHeap)
- [x] Support multi-modeles (Gemma2, Gemma3)
- [x] Support modeles multimodaux (vision)

### 2.2 Service IA (GemmaService)
- [x] `GemmaService` singleton avec injectable
- [x] Verification de l'installation du modele
- [x] Telechargement avec progression
- [x] Chargement du modele en memoire
- [x] Generation de reponses (stream)
- [x] Gestion des etats : notInstalled, downloading, installed, loading, ready, error
- [x] Support HuggingFace token (modeles proteges)

### 2.3 ChatBloc
- [x] Events complets : Initialize, DownloadModel, LoadModel, SendMessage, StopGeneration, etc.
- [x] States avec : modelState, downloadProgress, messages, isGenerating, error
- [x] Gestion du contexte (tokens usage)
- [x] Support regeneration de message

---

## Phase 3 : Interface Chat (COMPLETE)

### 3.1 Pages
- [x] HomePage - Ecran d'accueil avec navigation
- [x] ModelSelectionPage - Selection du modele Gemma
- [x] ChatPage - Interface de chat complete
- [x] ConversationsPage - Historique des conversations
- [x] SettingsPage - Parametres de l'application
- [x] PromptTemplatesPage - Gestion des modeles de prompts

### 3.2 Widgets
- [x] ChatBubble - Bulle de message (user/assistant) avec markdown
- [x] ModelStatusCard - Carte de statut du modele (download, load, error)

### 3.3 Fonctionnalites UI
- [x] Liste de messages scrollable
- [x] Champ de saisie avec envoi
- [x] Indicateur de generation en cours
- [x] Bouton stop generation
- [x] Bouton effacer conversation
- [x] Copier / Regenerer message
- [x] Indicateur contexte (tokens utilises)
- [x] Gestion des erreurs avec SnackBar + retry

---

## Phase 4 : Fonctionnalites Avancees (COMPLETE)

### 4.1 Persistance des conversations
- [x] Sauvegarder les messages dans Drift
- [x] Liste des conversations historiques
- [x] Reprendre une conversation
- [x] Supprimer une conversation

### 4.2 Parametres du modele
- [x] Page de parametres complete
- [x] Configuration temperature (0-1)
- [x] Configuration max tokens (256-4096)
- [x] Selection du theme (auto/clair/sombre)

### 4.3 Fonctionnalites assistant
- [x] Prompts systeme personnalisables
- [x] Templates de conversation (CRUD)
- [x] Picker de templates dans le chat

### 4.4 Gestion d'erreurs
- [x] Classes d'erreurs structurees (AppError, NetworkError, RagError)
- [x] Messages utilisateur localises
- [x] Retry automatique pour erreurs recuperables
- [x] Logger applicatif (AppLogger)

---

## Phase 5 : RAG - Retrieval-Augmented Generation (COMPLETE)

### 5.1 Service RAG (RagService)
- [x] Telechargement embedder EmbeddingGemma 300M
- [x] Extraction texte PDF (read_pdf_text)
- [x] Chunking de documents (overlap)
- [x] Generation d'embeddings
- [x] Vector store SQLite local

### 5.2 Fonctionnalites RAG
- [x] Upload de documents PDF
- [x] Indicateur de traitement (chunks progress)
- [x] Activer/Desactiver documents
- [x] Supprimer documents
- [x] Recherche semantique (similarity search)
- [x] Augmentation automatique des prompts avec contexte

---

## Phase 6 : Fonctionnalites Multimodales (COMPLETE)

### 6.1 Support Vision
- [x] Detection modeles multimodaux
- [x] Picker d'image (camera + galerie)
- [x] Preview image avant envoi
- [x] Envoi image + texte au modele

### 6.2 Text-to-Speech
- [x] Service TTS (flutter_tts)
- [x] Lecture vocale des reponses

---

## Phase 7 : Tests et Qualite (COMPLETE)

### 7.1 Tests unitaires
- [x] Tests ChatBloc (bloc_test)
  - Initialize, Download, Load, SendMessage
  - Conversation management (CRUD)
  - RAG embedder states
  - Stop generation, error handling
- [x] Tests entites
  - ChatMessage (copyWith, equality, hasImage, hasThinking)
  - DocumentInfo (copyWith, equality)
- [x] Tests ChatState
  - isModelReady, isEmbedderReady
  - estimatedTokensUsed, contextUsagePercent
  - copyWith, clearError

### 7.2 Tests d'integration E2E
- [x] Infrastructure (integration_test/)
- [x] Mocks complets (GemmaService, RagService, TtsService, SettingsService)
- [x] TestApp avec DI in-memory
- [x] Tests Navigation (HomePage, ModelSelection, Settings)
- [x] Tests Chat (send message, attachment menu)
- [x] Tests Conversations (create, load, history)
- [x] Tests RAG (PDF option, embedder states)
- [x] Tests Multimodal (image option)
- [x] Tests Error Handling (download/load states)
- [x] Tests Theme (switch light/dark/auto)
- [x] Tests System Prompt (dialog)
- [x] Tests Clear Conversation

### 7.3 Tests de performance
- [x] Chunking performance (large documents)
- [x] Token estimation performance
- [x] Chunk size/overlap impact

### 7.4 Optimisations
- [x] Gestion memoire du modele (unload)
  - Bouton dans AppBar pour liberer manuellement la memoire
  - Decharge automatique au retour arriere (PopScope)
  - Event `ChatUnloadModel` dans le BLoC
  - Libere ~500 Mo+ de RAM
- [x] Estimation tokens images (~512 tokens/image)
- [x] Fix cache images (ValueKey unique par message)
- [x] Barre de progression telechargement visible sur ModelSelectionPage

---

## Commandes utiles

```bash
# Installer les dependances
flutter pub get

# Generer le code (Drift, Injectable)
dart run build_runner build --delete-conflicting-outputs

# Lancer l'app (Windows)
flutter run -d windows

# Lancer l'app (Android)
flutter run -d <device_id>

# Build Android APK
flutter build apk

# Build Windows
flutter build windows

# Tests unitaires
flutter test

# Tests unitaires avec coverage
flutter test --coverage

# Tests d'integration
flutter test integration_test/

# Tests specifiques
flutter test test/blocs/chat_bloc_test.dart
flutter test test/entities/
flutter test test/services/
flutter test test/performance/
```

---

## Structure des fichiers cles

```
lib/
├── main.dart                           # Point d'entree
├── core/
│   ├── di/injection.dart               # Configuration get_it
│   ├── theme/app_theme.dart            # Themes Material 3
│   ├── errors/app_errors.dart          # Classes d'erreurs
│   └── utils/
│       ├── app_logger.dart             # Logger
│       └── connectivity_checker.dart   # Verif connexion
├── data/
│   └── datasources/
│       ├── database.dart               # Base Drift
│       ├── gemma_service.dart          # Service LLM
│       ├── rag_service.dart            # Service RAG
│       ├── tts_service.dart            # Text-to-Speech
│       ├── settings_service.dart       # Parametres
│       └── prompt_template_service.dart
├── domain/
│   └── entities/
│       ├── chat_message.dart           # Message
│       ├── conversation_info.dart      # Conversation
│       ├── document_info.dart          # Document RAG
│       └── gemma_model_info.dart       # Info modele
└── presentation/
    ├── blocs/
    │   └── chat/
    │       ├── chat_bloc.dart          # BLoC principal
    │       ├── chat_event.dart         # Events
    │       └── chat_state.dart         # States
    ├── pages/
    │   ├── home_page.dart              # Accueil
    │   ├── model_selection_page.dart   # Selection modele
    │   ├── chat_page.dart              # Chat
    │   ├── conversations_page.dart     # Historique
    │   ├── settings_page.dart          # Parametres
    │   └── prompt_templates_page.dart  # Templates
    └── widgets/
        ├── chat_bubble.dart            # Bulle message
        └── model_status_card.dart      # Status modele

test/
├── blocs/
│   └── chat_bloc_test.dart             # Tests BLoC
├── entities/
│   ├── chat_message_test.dart          # Tests ChatMessage
│   └── document_info_test.dart         # Tests DocumentInfo
├── services/
│   └── rag_service_test.dart           # Tests logique RAG
├── performance/
│   └── chunking_performance_test.dart  # Tests performance
└── mocks/
    ├── mock_gemma_service.dart         # Mock LLM
    └── mock_rag_service.dart           # Mock RAG

integration_test/
├── app_test.dart                       # Tests E2E
├── utils/
│   └── test_app.dart                   # Config tests
└── mocks/
    ├── mock_gemma_service.dart         # Mock complet
    ├── mock_rag_service.dart
    ├── mock_tts_service.dart
    └── mock_settings_service.dart
```

---

## Notes techniques

### flutter_gemma
- Version : 0.11.13
- Modeles supportes : Gemma2, Gemma3, TinyLlama, Llama, Phi, DeepSeek, Qwen
- Taille modeles : 800 Mo - 2.5 Go selon version
- Inference on-device (pas de serveur)
- Support vision pour modeles multimodaux

### RAG (Retrieval-Augmented Generation)
- Embedder : EmbeddingGemma 300M (~75 Mo)
- Vector store : SQLite local
- Chunking : 500 caracteres, overlap 50
- Recherche : top-K similarity (threshold 0.5)

### Architecture BLoC
- Separation claire UI / Logique metier
- Testabilite amelioree
- Flux de donnees unidirectionnel

### Drift (SQLite)
- Type-safe queries
- Generation de code automatique
- Migrations de schema supportees
