# IAckathon

Application Flutter de chat IA avec LLM local (Gemma) et RAG (Retrieval-Augmented Generation) entierement on-device.

## Fonctionnalites

- **Chat IA local** - Conversation avec Gemma 3 1B directement sur l'appareil, sans serveur
- **RAG integre** - Upload de documents PDF pour enrichir les reponses avec du contexte personnalise
- **Mode hors-ligne** - Fonctionne sans connexion internet une fois le modele telecharge
- **Historique des conversations** - Persistance locale avec SQLite (Drift)
- **Templates de prompts** - Prompts systeme personnalisables
- **Text-to-Speech** - Lecture vocale des reponses
- **Themes clair/sombre** - Interface Material 3 avec support du mode systeme

## Architecture

```
lib/
├── core/
│   ├── di/           # Injection de dependances (get_it + injectable)
│   ├── theme/        # Themes Material 3
│   ├── errors/       # Gestion d'erreurs structuree
│   └── utils/        # Utilitaires (logger, connectivity)
├── data/
│   └── datasources/
│       ├── database.dart       # Base SQLite (Drift)
│       ├── gemma_service.dart  # Service LLM
│       ├── rag_service.dart    # Service RAG + embeddings
│       ├── tts_service.dart    # Text-to-Speech
│       └── settings_service.dart
├── domain/
│   └── entities/     # Entites metier
└── presentation/
    ├── blocs/        # BLoC (gestion d'etat)
    ├── pages/        # Ecrans
    └── widgets/      # Composants reutilisables
```

## Stack technique

| Composant | Technologie |
|-----------|-------------|
| Framework | Flutter 3.10+ |
| Gestion d'etat | BLoC |
| Base de donnees | Drift (SQLite) |
| LLM | flutter_gemma 0.11.13 |
| Embeddings | EmbeddingGemma 300M |
| DI | get_it + injectable |
| Modele IA | Gemma 3 1B IT (int4, GPU) |

## Prerequis

- Flutter SDK ^3.10.1
- Android SDK 29+ (Android 10)
- ~1 Go d'espace pour le modele Gemma

## Installation

```bash
# Cloner le projet
git clone <repo-url>
cd iackathon

# Installer les dependances
flutter pub get

# Generer le code (Drift, Injectable)
dart run build_runner build --delete-conflicting-outputs

# Lancer l'application
flutter run
```

## Utilisation

1. **Premier lancement** - Le modele Gemma (~900 Mo) sera telecharge automatiquement
2. **Chat** - Commencez a discuter avec l'IA locale
3. **RAG (optionnel)** - Uploadez des PDF pour enrichir les reponses avec vos documents
4. **Parametres** - Ajustez la temperature, les tokens max, et le theme

## Commandes utiles

```bash
# Lancer sur Android
flutter run -d <device_id>

# Lancer sur Windows
flutter run -d windows

# Build APK
flutter build apk

# Build Windows
flutter build windows

# Regenerer le code
dart run build_runner build --delete-conflicting-outputs

# Tests d'integration
flutter test integration_test/
```

## Documentation

La documentation est construite avec [Docusaurus](https://docusaurus.io/).

```bash
cd docs

# Installer les dependances
npm install

# Lancer en mode developpement (hot reload)
npm start

# Build pour production
npm run build

# Previsualiser le build de production
npm run serve
```

La documentation sera accessible sur `http://localhost:3000` en mode developpement.

## Plateformes supportees

| Plateforme | Support |
|------------|---------|
| Android | Complet |
| Windows | Experimental |
| Web | Limite |

## Configuration Android

Le projet necessite les permissions suivantes (deja configurees) :

- `INTERNET` - Telechargement initial du modele
- `ACCESS_NETWORK_STATE` - Verification de connectivite
- `android:largeHeap="true"` - Memoire etendue pour le LLM

## License

MIT
