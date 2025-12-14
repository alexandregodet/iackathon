---
sidebar_position: 8
title: Injection de dependances
description: Configuration et utilisation de GetIt avec Injectable
---

# Injection de dependances

IAckathon utilise **GetIt** comme conteneur de services et **Injectable** pour la generation automatique de la configuration.

## Configuration

### Setup

```dart
// lib/core/di/injection.dart
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injection.config.dart';

final getIt = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies() async {
  getIt.init();
}

/// Reset pour les tests
Future<void> resetGetIt() async {
  await getIt.reset();
}

/// Verifier si les services sont enregistres
bool get isGetItReady => getIt.isRegistered<Object>();
```

### Initialisation dans main

```dart
// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configurer l'injection de dependances
  await configureDependencies();

  // Initialiser les services
  await getIt<SettingsService>().init();
  await getIt<TtsService>().init();

  runApp(const MyApp());
}
```

## Annotations

### @singleton

Une seule instance pour toute l'application :

```dart
@singleton
class GemmaService {
  // Instance unique
}

@singleton
class RagService {
  // Instance unique
}
```

### @lazySingleton

Instance creee a la premiere utilisation :

```dart
@lazySingleton
class SettingsService {
  // Cree a la premiere demande
}
```

### @injectable

Nouvelle instance a chaque demande (factory) :

```dart
@injectable
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  ChatBloc(this._gemmaService, this._ragService, this._database);
}
```

### @preResolve

Pour les services qui necessitent une initialisation async :

```dart
@singleton
@preResolve
class DatabaseService {
  @factoryMethod
  static Future<DatabaseService> create() async {
    final db = DatabaseService._();
    await db._initialize();
    return db;
  }
}
```

## Fichier genere

Apres execution de `build_runner`, le fichier `injection.config.dart` est genere :

```dart
// GENERATED CODE - DO NOT MODIFY BY HAND

extension GetItInjectableX on GetIt {
  GetIt init({
    String? environment,
    EnvironmentFilter? environmentFilter,
  }) {
    final gh = GetItHelper(this, environment, environmentFilter);

    // Singletons
    gh.singleton<AppDatabase>(() => AppDatabase());
    gh.singleton<GemmaService>(() => GemmaService());
    gh.singleton<RagService>(() => RagService());
    gh.singleton<SettingsService>(() => SettingsService());
    gh.singleton<TtsService>(() => TtsService());

    // Singletons avec dependances
    gh.singleton<PromptTemplateService>(
      () => PromptTemplateService(gh<AppDatabase>()),
    );

    // Factories
    gh.factory<ChatBloc>(
      () => ChatBloc(
        gh<GemmaService>(),
        gh<RagService>(),
        gh<AppDatabase>(),
      ),
    );

    return this;
  }
}
```

## Usage

### Recuperer un service

```dart
// Singleton
final gemmaService = getIt<GemmaService>();

// Factory (nouvelle instance)
final chatBloc = getIt<ChatBloc>();
```

### Dans un Widget

```dart
class ChatPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ChatBloc>(),
      child: const _ChatPageContent(),
    );
  }
}
```

### Acces direct (deconseille)

```dart
// A eviter si possible - preferer l'injection par constructeur
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final service = getIt<SomeService>();
    // ...
  }
}
```

## Tests

### Reset entre les tests

```dart
setUp(() async {
  await resetGetIt();
  // Configurer les mocks
});

tearDown(() async {
  await resetGetIt();
});
```

### Enregistrer des mocks

```dart
class TestApp {
  static late MockGemmaService mockGemmaService;
  static late MockRagService mockRagService;

  static Future<void> initialize() async {
    await resetGetIt();

    // Creer les mocks
    mockGemmaService = MockGemmaService();
    mockRagService = MockRagService();

    // Enregistrer
    getIt.registerSingleton<GemmaService>(mockGemmaService);
    getIt.registerSingleton<RagService>(mockRagService);
    getIt.registerSingleton<AppDatabase>(
      AppDatabase.forTesting(NativeDatabase.memory()),
    );

    // Factory pour ChatBloc
    getIt.registerFactory<ChatBloc>(
      () => ChatBloc(
        mockGemmaService,
        mockRagService,
        getIt<AppDatabase>(),
      ),
    );
  }
}
```

### Exemple de test

```dart
testWidgets('ChatPage displays correctly', (tester) async {
  await TestApp.initialize();

  TestApp.mockGemmaService.setModelState(GemmaModelState.ready);

  await tester.pumpWidget(
    MaterialApp(home: ChatPage(modelInfo: testModel)),
  );

  expect(find.byType(TextField), findsOneWidget);
});
```

## Environnements

Injectable supporte les environnements :

```dart
// Service uniquement en dev
@Environment('dev')
@singleton
class DebugService { }

// Service uniquement en prod
@Environment('prod')
@singleton
class AnalyticsService { }

// Initialisation avec environnement
configureDependencies(environment: 'prod');
```

## Bonnes pratiques

### 1. Injection par constructeur

```dart
// Bon - dependances explicites
class ChatBloc {
  final GemmaService _gemmaService;
  final RagService _ragService;

  ChatBloc(this._gemmaService, this._ragService);
}

// Moins bon - dependance cachee
class ChatBloc {
  final _gemmaService = getIt<GemmaService>();
}
```

### 2. Interfaces pour les tests

```dart
// Interface
abstract class IGemmaService {
  Stream<String> generateResponse(String message);
}

// Implementation
@Singleton(as: IGemmaService)
class GemmaService implements IGemmaService {
  @override
  Stream<String> generateResponse(String message) async* { }
}

// Mock
class MockGemmaService implements IGemmaService { }
```

### 3. Grouper les enregistrements logiquement

```dart
// Module data
@module
abstract class DataModule {
  @singleton
  AppDatabase get database => AppDatabase();

  @singleton
  GemmaService get gemmaService => GemmaService();
}
```

## Regenerer le code

```bash
# Build unique
flutter pub run build_runner build --delete-conflicting-outputs

# Mode watch
flutter pub run build_runner watch --delete-conflicting-outputs
```
