---
sidebar_position: 12
title: Contribuer
description: Guide pour contribuer au projet IAckathon
---

# Contribuer a IAckathon

Merci de votre interet pour contribuer a IAckathon ! Ce guide vous explique comment participer au projet.

## Code de conduite

- Soyez respectueux et inclusif
- Acceptez les critiques constructives
- Concentrez-vous sur ce qui est le mieux pour la communaute
- Faites preuve d'empathie envers les autres contributeurs

## Comment contribuer

### Signaler un bug

1. Verifiez que le bug n'a pas deja ete signale dans les [Issues](https://github.com/iackathon/iackathon/issues)
2. Si non, creez une nouvelle issue avec :
   - Un titre clair et descriptif
   - Les etapes pour reproduire le bug
   - Le comportement attendu vs observe
   - Votre environnement (version Android, modele de telephone)
   - Des captures d'ecran si pertinent

### Proposer une fonctionnalite

1. Verifiez que la fonctionnalite n'est pas deja proposee
2. Creez une issue avec le label `enhancement`
3. Decrivez clairement la fonctionnalite et son utilite
4. Attendez la validation avant de commencer a coder

### Soumettre du code

1. Forkez le repository
2. Creez une branche depuis `main`
3. Implementez vos modifications
4. Testez votre code
5. Soumettez une Pull Request

## Workflow Git

### Branches

| Branche | Usage |
|---------|-------|
| `main` | Code stable, releases |
| `develop` | Integration des features |
| `feature/*` | Nouvelles fonctionnalites |
| `fix/*` | Corrections de bugs |
| `docs/*` | Documentation |

### Creer une branche

```bash
# Feature
git checkout -b feature/nom-fonctionnalite

# Bugfix
git checkout -b fix/description-bug

# Documentation
git checkout -b docs/mise-a-jour-readme
```

### Commits

Suivez le format [Conventional Commits](https://www.conventionalcommits.org/) :

```
<type>(<scope>): <description>

[body optionnel]

[footer optionnel]
```

#### Types

| Type | Description |
|------|-------------|
| `feat` | Nouvelle fonctionnalite |
| `fix` | Correction de bug |
| `docs` | Documentation |
| `style` | Formatage (pas de changement de code) |
| `refactor` | Refactoring |
| `test` | Ajout/modification de tests |
| `chore` | Maintenance, deps, etc. |

#### Exemples

```bash
git commit -m "feat(chat): add image attachment support"
git commit -m "fix(rag): handle empty PDF documents"
git commit -m "docs: update installation instructions"
git commit -m "refactor(bloc): simplify message handling"
git commit -m "test: add ChatBloc unit tests"
```

## Pull Requests

### Avant de soumettre

1. **Synchronisez** avec la branche principale :
   ```bash
   git fetch origin
   git rebase origin/main
   ```

2. **Formatez** le code :
   ```bash
   dart format .
   ```

3. **Analysez** le code :
   ```bash
   flutter analyze
   ```

4. **Testez** :
   ```bash
   flutter test
   ```

5. **Generez** le code si necessaire :
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

### Template de PR

```markdown
## Description

Decrivez brievement vos modifications.

## Type de changement

- [ ] Bug fix
- [ ] Nouvelle fonctionnalite
- [ ] Breaking change
- [ ] Documentation

## Checklist

- [ ] J'ai lu les guidelines de contribution
- [ ] Mon code suit le style du projet
- [ ] J'ai ajoute des tests pour mes modifications
- [ ] Tous les tests passent
- [ ] J'ai mis a jour la documentation si necessaire

## Tests effectues

Decrivez les tests que vous avez realises.

## Screenshots (si applicable)

Ajoutez des captures d'ecran si pertinent.
```

### Review process

1. Un mainteneur examinera votre PR
2. Des modifications peuvent etre demandees
3. Une fois approuvee, la PR sera mergee

## Standards de code

### Style Dart

- Utilisez les single quotes pour les strings
- Ajoutez des trailing commas
- Limitez les lignes a 100 caracteres
- Documentez les fonctions publiques

```dart
/// Envoie un message et retourne le stream de reponse.
///
/// [message] Le message utilisateur.
/// [imageBytes] Image optionnelle pour les modeles multimodaux.
Stream<String> sendMessage(
  String message, {
  Uint8List? imageBytes,
}) async* {
  // Implementation
}
```

### Structure des fichiers

- Un fichier par classe principale
- Nommage en snake_case pour les fichiers
- Grouper les imports (dart, packages, local)

```dart
// Imports Dart
import 'dart:async';
import 'dart:typed_data';

// Imports packages
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Imports locaux
import '../services/gemma_service.dart';
import 'chat_state.dart';
```

### Tests

- Couvrez les cas nominaux et les cas d'erreur
- Utilisez des noms descriptifs
- Un assert par test quand possible

## Architecture

Respectez l'architecture Clean Architecture :

- **Presentation** : Pages, Widgets, BLoCs
- **Domain** : Entities, logique metier pure
- **Data** : Services, repositories, sources de donnees

## Ressources

- [Documentation Flutter](https://flutter.dev/docs)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)
- [BLoC Pattern](https://bloclibrary.dev/)

## Questions ?

Si vous avez des questions :

1. Consultez d'abord la documentation
2. Cherchez dans les issues existantes
3. Ouvrez une nouvelle issue si necessaire

Merci de contribuer a IAckathon !
