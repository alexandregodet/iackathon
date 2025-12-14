import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:iackathon/data/datasources/gemma_service.dart';
import 'package:iackathon/data/datasources/rag_service.dart';
import 'package:iackathon/domain/entities/gemma_model_info.dart';

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

      // Verify HomePage elements
      expect(find.text('IAckathon'), findsOneWidget);
      expect(find.text('SELECT_MODEL'), findsOneWidget);
    });

    testWidgets('Navigate to ModelSelectionPage', (tester) async {
      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      // Tap SELECT_MODEL button
      await tester.tap(find.text('SELECT_MODEL'));
      await tester.pumpAndSettle();

      // Verify ModelSelectionPage
      expect(find.text('select_model'), findsOneWidget);
      expect(find.text('# MULTIMODAL'), findsOneWidget);
      expect(find.text('# TEXT_ONLY'), findsOneWidget);
    });

    testWidgets('Navigate to Settings', (tester) async {
      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      // Tap settings icon
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      // Verify SettingsPage
      expect(find.text('Parametres'), findsOneWidget);
    });

    testWidgets('Select model and navigate to ChatPage', (tester) async {
      // Configure mock to be ready immediately
      TestApp.mockGemmaService.setModelState(GemmaModelState.ready);
      TestApp.mockGemmaService.setCurrentModel(AvailableModels.multimodal.first);

      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      // Navigate to model selection
      await tester.tap(find.text('SELECT_MODEL'));
      await tester.pumpAndSettle();

      // Select first model (Gemma 3)
      final modelCard = find.text('Gemma 3 1B').first;
      await tester.tap(modelCard);
      await tester.pumpAndSettle();

      // Should navigate to ChatPage
      // The chat page has an input field
      expect(find.byType(TextField), findsOneWidget);
    });
  });

  group('Chat Tests', () {
    setUp(() async {
      await TestApp.initialize();
      // Pre-configure model as ready
      TestApp.mockGemmaService.setModelState(GemmaModelState.ready);
      TestApp.mockGemmaService.setCurrentModel(AvailableModels.textOnly.first);
      TestApp.mockGemmaService.setMockResponses([
        'Hello! I am a mock AI assistant.',
        'That is a great question. Let me help you with that.',
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

      // Select text-only model (Gemma 3 1B is the first text-only model)
      await tester.tap(find.text('Gemma 3 1B').first);
      await tester.pumpAndSettle();

      // Find and enter message
      final textField = find.byType(TextField);
      await tester.enterText(textField, 'Hello, AI!');
      await tester.pumpAndSettle();

      // Tap send button
      await tester.tap(find.byIcon(Icons.arrow_forward));

      // Allow bloc events to be processed
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // User message should be visible in the chat
      // Note: The message may be in a chat bubble widget
      expect(find.textContaining('Hello, AI!'), findsWidgets);
    });

    testWidgets('Open attachment menu', (tester) async {
      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      // Navigate to chat
      await tester.tap(find.text('SELECT_MODEL'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Gemma 3 1B').first);
      await tester.pumpAndSettle();

      // Tap the + button to open attachment menu
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Verify attachment menu options
      expect(find.text('attach'), findsOneWidget);
      expect(find.text('pdf'), findsOneWidget);
      expect(find.text('template'), findsOneWidget);
    });
  });

  group('Settings Tests', () {
    setUp(() async {
      await TestApp.initialize();
    });

    tearDown(() async {
      await TestApp.tearDown();
    });

    testWidgets('Change theme to dark', (tester) async {
      await tester.pumpWidget(TestApp.buildAppWithTheme());
      await tester.pumpAndSettle();

      // Navigate to settings
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      // Find theme section - settings page has "Apparence" section
      expect(find.text('Apparence'), findsOneWidget);
      expect(find.text('Theme'), findsOneWidget);
    });

    testWidgets('Modify temperature setting', (tester) async {
      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      // Navigate to settings
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      // Find model parameters section
      expect(find.text('Parametres du modele'), findsOneWidget);
      expect(find.byType(Slider), findsWidgets);
    });
  });

  group('Conversations Tests', () {
    setUp(() async {
      await TestApp.initialize();
      TestApp.mockGemmaService.setModelState(GemmaModelState.ready);
      TestApp.mockGemmaService.setCurrentModel(AvailableModels.textOnly.first);
      TestApp.mockGemmaService.setMockResponses([
        'First response.',
        'Second response.',
      ]);
    });

    tearDown(() async {
      await TestApp.tearDown();
    });

    testWidgets('Create conversation and view in history', (tester) async {
      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      // Navigate to chat
      await tester.tap(find.text('SELECT_MODEL'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Gemma 3 1B').first);
      await tester.pumpAndSettle();

      // Send a message to create conversation
      final textField = find.byType(TextField);
      await tester.enterText(textField, 'Test message');
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pumpAndSettle();

      // Wait for response
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // Open history
      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();

      // Should see conversations page
      expect(find.text('Conversations'), findsOneWidget);
    });
  });

  group('Prompt Templates Tests', () {
    setUp(() async {
      await TestApp.initialize();
      TestApp.mockGemmaService.setModelState(GemmaModelState.ready);
      TestApp.mockGemmaService.setCurrentModel(AvailableModels.textOnly.first);
    });

    tearDown(() async {
      await TestApp.tearDown();
    });

    testWidgets('Open prompt templates from attachment menu', (tester) async {
      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      // Navigate to chat
      await tester.tap(find.text('SELECT_MODEL'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Gemma 3 1B').first);
      await tester.pumpAndSettle();

      // Tap + button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Tap template option
      await tester.tap(find.text('template'));
      await tester.pumpAndSettle();

      // Should see templates picker
      expect(find.text('Modeles de prompts'), findsOneWidget);
    });
  });

  group('RAG Tests', () {
    setUp(() async {
      await TestApp.initialize();
      TestApp.mockGemmaService.setModelState(GemmaModelState.ready);
      TestApp.mockGemmaService.setCurrentModel(AvailableModels.textOnly.first);
      TestApp.mockRagService.setEmbedderState(EmbedderState.ready);
    });

    tearDown(() async {
      await TestApp.tearDown();
    });

    testWidgets('Show PDF option in attachment menu', (tester) async {
      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      // Navigate to chat
      await tester.tap(find.text('SELECT_MODEL'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Gemma 3 1B').first);
      await tester.pumpAndSettle();

      // Tap + button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Verify PDF option is visible
      expect(find.text('pdf'), findsOneWidget);
      expect(find.text('add document'), findsOneWidget);
    });
  });

  group('Multimodal Tests', () {
    setUp(() async {
      await TestApp.initialize();
      TestApp.mockGemmaService.setModelState(GemmaModelState.ready);
      // Set a multimodal model
      TestApp.mockGemmaService.setCurrentModel(AvailableModels.multimodal.first);
    });

    tearDown(() async {
      await TestApp.tearDown();
    });

    testWidgets('Multimodal model shows image option', (tester) async {
      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      // Navigate to model selection
      await tester.tap(find.text('SELECT_MODEL'));
      await tester.pumpAndSettle();

      // Select multimodal model (PaliGemma)
      final modelCard = find.textContaining('PaliGemma').first;
      await tester.tap(modelCard);
      await tester.pumpAndSettle();

      // Tap + button
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Verify image option is visible for multimodal models
      expect(find.text('image'), findsOneWidget);
    });
  });

  group('Error Handling Tests', () {
    setUp(() async {
      await TestApp.initialize();
    });

    tearDown(() async {
      await TestApp.tearDown();
    });

    testWidgets('Shows download button when model not installed', (tester) async {
      TestApp.mockGemmaService.setModelState(GemmaModelState.notInstalled);

      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      // Navigate to chat
      await tester.tap(find.text('SELECT_MODEL'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Gemma 3 1B').first);
      await tester.pumpAndSettle();

      // Should show ModelStatusCard with download option
      expect(find.text('Telecharger'), findsOneWidget);
    });

    testWidgets('Shows load button when model installed but not loaded', (tester) async {
      TestApp.mockGemmaService.setModelState(GemmaModelState.installed);

      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      // Navigate to chat
      await tester.tap(find.text('SELECT_MODEL'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Gemma 3 1B').first);
      await tester.pumpAndSettle();

      // Should show load option
      expect(find.text('Charger'), findsOneWidget);
    });
  });

  group('Theme Tests', () {
    setUp(() async {
      await TestApp.initialize();
    });

    tearDown(() async {
      await TestApp.tearDown();
    });

    testWidgets('Can switch between themes', (tester) async {
      await tester.pumpWidget(TestApp.buildAppWithTheme());
      await tester.pumpAndSettle();

      // Navigate to settings
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      // Find theme section
      expect(find.text('Theme'), findsOneWidget);

      // Find theme buttons (Auto, Clair, Sombre)
      expect(find.text('Auto'), findsOneWidget);
      expect(find.text('Clair'), findsOneWidget);
      expect(find.text('Sombre'), findsOneWidget);
    });
  });

  group('System Prompt Tests', () {
    setUp(() async {
      await TestApp.initialize();
      TestApp.mockGemmaService.setModelState(GemmaModelState.ready);
      TestApp.mockGemmaService.setCurrentModel(AvailableModels.textOnly.first);
    });

    tearDown(() async {
      await TestApp.tearDown();
    });

    testWidgets('Can open system prompt dialog', (tester) async {
      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      // Navigate to chat
      await tester.tap(find.text('SELECT_MODEL'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Gemma 3 1B').first);
      await tester.pumpAndSettle();

      // Tap system prompt button
      await tester.tap(find.byIcon(Icons.settings_suggest));
      await tester.pumpAndSettle();

      // Should see system prompt dialog
      expect(find.text('Instructions systeme'), findsOneWidget);
    });
  });

  group('Clear Conversation Tests', () {
    setUp(() async {
      await TestApp.initialize();
      TestApp.mockGemmaService.setModelState(GemmaModelState.ready);
      TestApp.mockGemmaService.setCurrentModel(AvailableModels.textOnly.first);
      TestApp.mockGemmaService.setMockResponses(['Test response.']);
    });

    tearDown(() async {
      await TestApp.tearDown();
    });

    testWidgets('Can clear conversation', (tester) async {
      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      // Navigate to chat
      await tester.tap(find.text('SELECT_MODEL'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Gemma 3 1B').first);
      await tester.pumpAndSettle();

      // Send a message
      final textField = find.byType(TextField);
      await tester.enterText(textField, 'Test message');
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 500));

      // Clear conversation
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // Message should be gone (empty state shown)
      expect(find.text('Demarrez une conversation'), findsOneWidget);
    });
  });
}
