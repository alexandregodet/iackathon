---
sidebar_position: 11
title: Tests
description: Strategie et implementation des tests
---

# Tests

IAckathon utilise une strategie de tests a plusieurs niveaux pour garantir la qualite du code.

## Types de tests

| Type | Emplacement | Usage |
|------|-------------|-------|
| Unitaires | `test/` | Tester des fonctions/classes isolees |
| Widget | `test/` | Tester des widgets individuels |
| Integration | `integration_test/` | Tester des flux complets E2E |

## Tests unitaires

### Structure

```dart
// test/data/gemma_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:iackathon/data/datasources/gemma_service.dart';

void main() {
  group('GemmaService', () {
    late GemmaService service;

    setUp(() {
      service = GemmaService();
    });

    test('initial state is notDownloaded', () {
      expect(service.state, GemmaModelState.notDownloaded);
    });

    test('isReady returns true when state is ready', () {
      // Arrange
      service.setModelState(GemmaModelState.ready);

      // Act & Assert
      expect(service.isReady, true);
    });
  });
}
```

### Lancer les tests unitaires

```bash
# Tous les tests
flutter test

# Un fichier specifique
flutter test test/data/gemma_service_test.dart

# Avec couverture
flutter test --coverage
```

## Tests de BLoC

Utilisez le package `bloc_test` :

```dart
// test/presentation/blocs/chat_bloc_test.dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:iackathon/presentation/blocs/chat/chat_bloc.dart';

class MockGemmaService extends Mock implements GemmaService {}
class MockRagService extends Mock implements RagService {}

void main() {
  late ChatBloc bloc;
  late MockGemmaService mockGemmaService;
  late MockRagService mockRagService;
  late AppDatabase mockDatabase;

  setUp(() {
    mockGemmaService = MockGemmaService();
    mockRagService = MockRagService();
    mockDatabase = AppDatabase.forTesting(NativeDatabase.memory());

    when(() => mockGemmaService.state).thenReturn(GemmaModelState.ready);
    when(() => mockGemmaService.isReady).thenReturn(true);

    bloc = ChatBloc(mockGemmaService, mockRagService, mockDatabase);
  });

  tearDown(() async {
    await bloc.close();
    await mockDatabase.close();
  });

  group('ChatBloc', () {
    blocTest<ChatBloc, ChatState>(
      'emits state with model when initialized',
      build: () => bloc,
      act: (bloc) => bloc.add(ChatInitialize(AvailableModels.gemma3_1b)),
      expect: () => [
        isA<ChatState>()
            .having((s) => s.selectedModel, 'selectedModel', isNotNull),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'emits isGenerating true then false when sending message',
      build: () {
        when(() => mockGemmaService.generateResponse(any()))
            .thenAnswer((_) => Stream.fromIterable(['Hello', ' ', 'World']));
        return bloc;
      },
      act: (bloc) => bloc.add(const ChatSendMessage(message: 'Hi')),
      expect: () => [
        isA<ChatState>().having((s) => s.isGenerating, 'isGenerating', true),
        isA<ChatState>().having((s) => s.messages.length, 'messages', 2),
        // Chunks...
        isA<ChatState>().having((s) => s.isGenerating, 'isGenerating', false),
      ],
    );
  });
}
```

## Tests d'integration

### Configuration

```dart
// integration_test/utils/test_app.dart
class TestApp {
  static late MockGemmaService mockGemmaService;
  static late MockRagService mockRagService;
  static late AppDatabase testDatabase;

  static Future<void> initialize() async {
    await resetGetIt();

    mockGemmaService = MockGemmaService();
    mockRagService = MockRagService();
    testDatabase = AppDatabase.forTesting(NativeDatabase.memory());

    getIt.registerSingleton<GemmaService>(mockGemmaService);
    getIt.registerSingleton<RagService>(mockRagService);
    getIt.registerSingleton<AppDatabase>(testDatabase);
    getIt.registerFactory<ChatBloc>(
      () => ChatBloc(mockGemmaService, mockRagService, testDatabase),
    );
  }

  static Future<void> tearDown() async {
    await testDatabase.close();
    await resetGetIt();
  }

  static Widget buildApp({Widget? home}) {
    return MaterialApp(
      home: home ?? const HomePage(),
    );
  }
}
```

### Tests E2E

```dart
// integration_test/app_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'utils/test_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Navigation Tests', () {
    setUp(() async {
      await TestApp.initialize();
    });

    tearDown(() async {
      await TestApp.tearDown();
    });

    testWidgets('App launches and shows HomePage', (tester) async {
      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      expect(find.text('IAckathon'), findsOneWidget);
      expect(find.text('SELECT_MODEL'), findsOneWidget);
    });

    testWidgets('Navigate to ModelSelectionPage', (tester) async {
      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('SELECT_MODEL'));
      await tester.pumpAndSettle();

      expect(find.text('select_model'), findsOneWidget);
    });
  });

  group('Chat Tests', () {
    setUp(() async {
      await TestApp.initialize();
      TestApp.mockGemmaService.setModelState(GemmaModelState.ready);
      TestApp.mockGemmaService.setMockResponses([
        'Hello! I am an AI assistant.',
      ]);
    });

    tearDown(() async {
      await TestApp.tearDown();
    });

    testWidgets('Send message and receive response', (tester) async {
      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      // Navigate to chat
      await tester.tap(find.text('SELECT_MODEL'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Gemma 3 1B').first);
      await tester.pumpAndSettle();

      // Send message
      final textField = find.byType(TextField);
      await tester.enterText(textField, 'Hello');
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pumpAndSettle();

      // Verify
      expect(find.textContaining('Hello'), findsWidgets);
    });
  });
}
```

### Lancer les tests d'integration

```bash
# Sur emulateur/appareil
flutter test integration_test/app_test.dart

# Avec driver (pour CI)
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart
```

## Mocking

### Avec Mocktail

```dart
import 'package:mocktail/mocktail.dart';

// Creer un mock
class MockGemmaService extends Mock implements GemmaService {}

// Usage
final mock = MockGemmaService();

// Stub une methode
when(() => mock.isReady).thenReturn(true);
when(() => mock.generateResponse(any()))
    .thenAnswer((_) => Stream.value('Response'));

// Verifier un appel
verify(() => mock.loadModel()).called(1);
```

### Mock complet pour les tests

```dart
// integration_test/mocks/mock_gemma_service.dart
class MockGemmaService extends Mock implements GemmaService {
  GemmaModelState _state = GemmaModelState.ready;
  final List<String> _mockResponses = [];
  int _responseIndex = 0;

  @override
  GemmaModelState get state => _state;

  @override
  bool get isReady => _state == GemmaModelState.ready;

  void setModelState(GemmaModelState newState) {
    _state = newState;
  }

  void setMockResponses(List<String> responses) {
    _mockResponses.clear();
    _mockResponses.addAll(responses);
    _responseIndex = 0;
  }

  @override
  Future<void> checkModelStatus(GemmaModelInfo modelInfo) async {
    if (_state != GemmaModelState.ready) {
      _state = GemmaModelState.installed;
    }
  }

  @override
  Stream<String> generateResponse(String message, {Uint8List? imageBytes}) async* {
    final response = _mockResponses[_responseIndex % _mockResponses.length];
    _responseIndex++;

    for (final word in response.split(' ')) {
      await Future.delayed(const Duration(milliseconds: 10));
      yield '$word ';
    }
  }
}
```

## Couverture de code

```bash
# Generer la couverture
flutter test --coverage

# Visualiser (necessite lcov)
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html

# Ou avec le package coverage
flutter pub global activate coverage
dart pub global run coverage:format_coverage \
  --lcov -i coverage -o coverage/lcov.info \
  --packages=.packages --report-on=lib
```

## Bonnes pratiques

### 1. AAA Pattern

```dart
test('should return sum of two numbers', () {
  // Arrange
  final calculator = Calculator();

  // Act
  final result = calculator.add(2, 3);

  // Assert
  expect(result, 5);
});
```

### 2. Un assert par test

```dart
// Bon
test('isReady returns true when ready', () {
  service.setState(GemmaModelState.ready);
  expect(service.isReady, true);
});

test('isReady returns false when not ready', () {
  service.setState(GemmaModelState.loading);
  expect(service.isReady, false);
});

// Moins bon
test('isReady works correctly', () {
  service.setState(GemmaModelState.ready);
  expect(service.isReady, true);

  service.setState(GemmaModelState.loading);
  expect(service.isReady, false);
});
```

### 3. Nommer clairement

```dart
// Bon
test('should emit error state when network fails', () { });

// Moins bon
test('test network error', () { });
```

### 4. Isoler les tests

```dart
setUp(() {
  // Reinitialiser l'etat avant chaque test
});

tearDown(() {
  // Nettoyer apres chaque test
});
```
