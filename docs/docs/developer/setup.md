---
sidebar_position: 9
title: Configuration de dev
description: Configurer votre environnement de developpement
---

# Configuration de l'environnement de developpement

Ce guide vous accompagne dans la mise en place de votre environnement pour contribuer a IAckathon.

## Prerequis

### Logiciels requis

| Logiciel | Version | Verification |
|----------|---------|--------------|
| Flutter SDK | 3.22+ | `flutter --version` |
| Dart SDK | 3.4+ | `dart --version` |
| Android Studio | 2024+ | - |
| Git | 2.x | `git --version` |

### Configuration Android

- Android SDK (API 26+)
- Android NDK
- Un emulateur ou appareil physique

## Installation

### 1. Cloner le depot

```bash
git clone https://github.com/iackathon/iackathon.git
cd iackathon
```

### 2. Installer les dependances

```bash
flutter pub get
```

### 3. Generer le code

Plusieurs fichiers sont generes automatiquement (DI, Drift) :

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. Verifier l'installation

```bash
flutter doctor -v
```

Assurez-vous que Flutter detecte bien votre environnement Android.

## Structure du projet

```
iackathon/
├── lib/                    # Code source
├── integration_test/       # Tests E2E
├── test/                   # Tests unitaires
├── android/                # Code natif Android
├── docs/                   # Documentation Docusaurus
├── pubspec.yaml            # Dependances
└── README.md
```

## Lancer l'application

### Sur emulateur

```bash
# Lister les emulateurs disponibles
flutter emulators

# Lancer un emulateur
flutter emulators --launch <emulator_id>

# Lancer l'app
flutter run
```

### Sur appareil physique

1. Activez le mode developpeur sur votre appareil
2. Activez le debogage USB
3. Connectez l'appareil via USB

```bash
# Verifier que l'appareil est detecte
flutter devices

# Lancer l'app
flutter run -d <device_id>
```

### Mode debug vs release

```bash
# Mode debug (par defaut)
flutter run

# Mode release (optimise)
flutter run --release

# Mode profile (pour le profilage)
flutter run --profile
```

## IDE recommande

### VS Code

Extensions recommandees :
- **Flutter** (Dart-Code.flutter)
- **Dart** (Dart-Code.dart-code)
- **bloc** (FelixAngelov.bloc)

Configuration `.vscode/settings.json` :

```json
{
  "editor.formatOnSave": true,
  "dart.lineLength": 100,
  "[dart]": {
    "editor.defaultFormatter": "Dart-Code.dart-code"
  }
}
```

### Android Studio

Plugins recommandes :
- Flutter
- Dart
- Bloc

## Configuration du linting

Le projet utilise `flutter_lints` :

```yaml
# analysis_options.yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    prefer_single_quotes: true
    require_trailing_commas: true
    avoid_print: true
```

Verifier le code :

```bash
flutter analyze
```

## Workflow de developpement

### 1. Creer une branche

```bash
git checkout -b feature/ma-fonctionnalite
```

### 2. Developper

```bash
# Lancer en mode hot reload
flutter run

# Les modifications sont automatiquement rechargees
# Appuyez sur 'r' pour forcer le hot reload
# Appuyez sur 'R' pour un hot restart complet
```

### 3. Formater le code

```bash
dart format .
```

### 4. Analyser

```bash
flutter analyze
```

### 5. Tester

```bash
# Tests unitaires
flutter test

# Tests d'integration
flutter test integration_test/app_test.dart
```

### 6. Commiter

```bash
git add .
git commit -m "feat: description de la fonctionnalite"
```

## Variables d'environnement

Si necessaire, creez un fichier `.env` :

```env
# Configuration optionnelle
HUGGINGFACE_TOKEN=votre_token
```

## Depannage

### Flutter doctor echoue

```bash
# Verifier les problemes
flutter doctor -v

# Solutions courantes
flutter config --android-studio-dir="<path>"
flutter config --android-sdk="<path>"
```

### Build runner echoue

```bash
# Nettoyer et regenerer
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Erreur de version Gradle

Verifiez `android/gradle/wrapper/gradle-wrapper.properties` :

```properties
distributionUrl=https\://services.gradle.org/distributions/gradle-8.4-all.zip
```

### Appareil non detecte

```bash
# Linux/Mac
adb kill-server
adb start-server

# Windows
# Reinstaller les drivers USB du fabricant
```

## Ressources

- [Documentation Flutter](https://flutter.dev/docs)
- [Documentation Dart](https://dart.dev/guides)
- [flutter_gemma](https://pub.dev/packages/flutter_gemma)
- [flutter_bloc](https://bloclibrary.dev/)
- [Drift](https://drift.simonbinder.eu/)
