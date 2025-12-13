# IAckathon - Plan de Developpement

## Vue d'ensemble

Projet Flutter pour hackathon IA avec LLM local (Gemma) integre sur device.

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
  │   └── utils/       # Utilitaires
  ├── data/
  │   ├── datasources/ # Sources de donnees (DB, API)
  │   ├── models/      # Modeles de donnees
  │   └── repositories/# Implementation des repos
  ├── domain/
  │   ├── entities/    # Entites metier
  │   ├── repositories/# Interfaces des repos
  │   └── usecases/    # Cas d'utilisation
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

### 1.5 Theme Material 3
- [x] Theme clair configure
- [x] Theme sombre configure
- [x] Support du mode systeme

---

## Phase 2 : Integration flutter_gemma (COMPLETE)

### 2.1 Installation et configuration
- [x] Ajouter la dependance flutter_gemma 0.11.13
- [x] Configurer les permissions Android (Internet, OpenCL, largeHeap)
- [x] Modele configure : Gemma 3 1B IT (GPU optimized)
- [x] URL du modele : HuggingFace aspect11/gemma-3-1b-it

### 2.2 Service IA (GemmaService)
- [x] `GemmaService` singleton avec injectable
- [x] Verification de l'installation du modele
- [x] Telechargement avec progression
- [x] Chargement du modele en memoire
- [x] Generation de reponses (sync et stream)
- [x] Gestion des etats : notInstalled, downloading, installed, loading, ready, error

### 2.3 ChatBloc
- [x] Events : Initialize, DownloadModel, LoadModel, SendMessage, StreamChunk, ClearConversation
- [x] States avec : modelState, downloadProgress, messages, isGenerating, error

---

## Phase 3 : Interface Chat (COMPLETE)

### 3.1 Pages
- [x] HomePage - Ecran d'accueil avec bouton "Demarrer une conversation"
- [x] ChatPage - Interface de chat complete

### 3.2 Widgets
- [x] ChatBubble - Bulle de message (user/assistant)
- [x] ModelStatusCard - Carte de statut du modele (download, load, error)

### 3.3 Fonctionnalites UI
- [x] Liste de messages scrollable
- [x] Champ de saisie avec envoi
- [x] Indicateur de generation en cours
- [x] Bouton effacer conversation
- [x] Gestion des erreurs avec SnackBar

---

## Phase 4 : Fonctionnalites Avancees (COMPLETE)

### 4.1 Persistance des conversations
- [x] Sauvegarder les messages dans Drift
- [x] Liste des conversations historiques
- [x] Reprendre une conversation

### 4.2 Parametres du modele
- [x] Page de parametres
- [x] Configuration temperature
- [x] Configuration max tokens
- [ ] Selection du modele (Gemma 1B, 2B, autres)

### 4.3 Fonctionnalites assistant
- [x] Prompts systeme personnalisables
- [ ] Templates de conversation
- [ ] Export des conversations

### 4.4 Optimisations
- [ ] Cache des reponses frequentes
- [ ] Gestion memoire du modele
- [ ] Mode hors-ligne complet

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
```

---

## Notes techniques

### flutter_gemma
- Version : 0.11.13
- Modele : Gemma 3 1B IT (int4, f16, GPU optimized)
- Taille : ~900 Mo
- Supporte : Gemma, TinyLlama, Llama, Phi, DeepSeek, Qwen
- Inference on-device (pas de serveur)
- Compatible Android nativement, Windows/Web limite

### Architecture BLoC
- Separation claire UI / Logique metier
- Testabilite amelioree
- Flux de donnees unidirectionnel

### Drift (SQLite)
- Type-safe queries
- Generation de code automatique
- Migrations de schema supportees

---

## Structure des fichiers cles

```
lib/
├── main.dart                           # Point d'entree, init FlutterGemma
├── core/
│   ├── di/injection.dart              # Configuration get_it
│   └── theme/app_theme.dart           # Themes Material 3
├── data/
│   └── datasources/
│       ├── database.dart              # Base Drift
│       └── gemma_service.dart         # Service LLM
├── domain/
│   └── entities/
│       └── chat_message.dart          # Entite message
└── presentation/
    ├── blocs/
    │   └── chat/
    │       ├── chat_bloc.dart         # BLoC principal
    │       ├── chat_event.dart        # Events
    │       └── chat_state.dart        # States
    ├── pages/
    │   ├── home_page.dart             # Accueil
    │   └── chat_page.dart             # Chat
    └── widgets/
        ├── chat_bubble.dart           # Bulle message
        └── model_status_card.dart     # Status modele
```
