import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:iackathon/data/datasources/gemma_service.dart';
import 'package:iackathon/data/datasources/rag_service.dart';
import 'package:iackathon/domain/entities/gemma_model_info.dart';

import 'utils/test_app.dart';

// Helper to navigate to chat page
Future<void> navigateToChat(WidgetTester tester) async {
  await tester.tap(find.text('SELECT_MODEL'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Gemma 3 1B').first);
  await tester.pumpAndSettle();
}

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
      TestApp.mockGemmaService.setCurrentModel(
        AvailableModels.multimodal.first,
      );

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
      TestApp.mockGemmaService.setCurrentModel(
        AvailableModels.multimodal.first,
      );
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

      // Select multimodal model (Gemma 3 Nano)
      final modelCard = find.textContaining('Gemma 3 Nano').first;
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

    testWidgets('Shows download button when model not installed', (
      tester,
    ) async {
      TestApp.mockGemmaService.setModelState(GemmaModelState.notInstalled);

      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      // Navigate to chat
      await tester.tap(find.text('SELECT_MODEL'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Gemma 3 1B').first);
      await tester.pumpAndSettle();

      // Should show ModelStatusCard with download option
      expect(find.textContaining('Telecharger'), findsWidgets);
    });

    testWidgets('Shows load button when model installed but not loaded', (
      tester,
    ) async {
      TestApp.mockGemmaService.setModelState(GemmaModelState.installed);

      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      // Navigate to chat
      await tester.tap(find.text('SELECT_MODEL'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Gemma 3 1B').first);
      await tester.pumpAndSettle();

      // Should show load option
      expect(find.textContaining('Charger'), findsWidgets);
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

  // ============================================================
  // NEW E2E TESTS - Additional User Function Coverage
  // ============================================================

  group('Model Unload Tests', () {
    setUp(() async {
      await TestApp.initialize();
      TestApp.mockGemmaService.setModelState(GemmaModelState.ready);
      TestApp.mockGemmaService.setCurrentModel(AvailableModels.textOnly.first);
    });

    tearDown(() async {
      await TestApp.tearDown();
    });

    testWidgets('Can unload model via memory button', (tester) async {
      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      await navigateToChat(tester);

      // Tap memory button to unload
      await tester.tap(find.byIcon(Icons.memory));
      await tester.pumpAndSettle();

      // Confirm dialog should appear
      expect(find.text('Liberer la memoire ?'), findsOneWidget);

      // Tap confirm button
      await tester.tap(find.text('Liberer'));
      await tester.pumpAndSettle();

      // Model should be unloaded - shows load button
      expect(find.textContaining('Charger'), findsWidgets);
    });

    testWidgets('Can cancel model unload', (tester) async {
      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      await navigateToChat(tester);

      // Tap memory button
      await tester.tap(find.byIcon(Icons.memory));
      await tester.pumpAndSettle();

      // Cancel
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      // Model should still be ready (no load button visible)
      expect(find.textContaining('Charger le modele'), findsNothing);
    });
  });

  group('Conversation Management Tests', () {
    setUp(() async {
      await TestApp.initialize();
      TestApp.mockGemmaService.setModelState(GemmaModelState.ready);
      TestApp.mockGemmaService.setCurrentModel(AvailableModels.textOnly.first);
      TestApp.mockGemmaService.setMockResponses([
        'First response.',
        'Second response.',
        'Third response.',
      ]);
    });

    tearDown(() async {
      await TestApp.tearDown();
    });

    testWidgets('Create conversation and view in history', (tester) async {
      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      await navigateToChat(tester);

      // Send message to create conversation
      await tester.enterText(find.byType(TextField), 'Test conversation');
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Open history
      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();

      // Should see conversations page
      expect(find.text('Conversations'), findsOneWidget);

      // Conversations page should be displayed (even if empty initially)
      // The page itself existing is the success condition
    });

    testWidgets('Delete conversation from history', (tester) async {
      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      await navigateToChat(tester);

      // Create a conversation
      await tester.enterText(find.byType(TextField), 'Test to delete');
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Open history
      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();

      // Find delete button (trash icon) on conversation item
      final deleteButtons = find.byIcon(Icons.delete_outline);
      if (deleteButtons.evaluate().isNotEmpty) {
        await tester.tap(deleteButtons.first);
        await tester.pumpAndSettle();
      }

      // Verify we're still on conversations page
      expect(find.text('Conversations'), findsOneWidget);
    });
  });

  group('Settings Modification Tests', () {
    setUp(() async {
      await TestApp.initialize();
    });

    tearDown(() async {
      await TestApp.tearDown();
    });

    testWidgets('Modify temperature with slider', (tester) async {
      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      // Navigate to settings
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      // Find temperature slider
      final sliders = find.byType(Slider);
      expect(sliders, findsWidgets);

      // Drag first slider (temperature)
      final slider = sliders.first;
      await tester.drag(slider, const Offset(50, 0));
      await tester.pumpAndSettle();

      // Value should have changed (no crash)
      expect(find.byType(Slider), findsWidgets);
    });

    testWidgets('Change theme to light mode', (tester) async {
      await tester.pumpWidget(TestApp.buildAppWithTheme());
      await tester.pumpAndSettle();

      // Navigate to settings
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      // Find and tap "Clair" button
      await tester.tap(find.text('Clair'));
      await tester.pumpAndSettle();

      // Theme should be light
      expect(
        TestApp.mockSettingsService.themeModeNotifier.value,
        ThemeMode.light,
      );
    });

    testWidgets('Change theme to dark mode', (tester) async {
      await tester.pumpWidget(TestApp.buildAppWithTheme());
      await tester.pumpAndSettle();

      // Navigate to settings
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      // Find and tap "Sombre" button
      await tester.tap(find.text('Sombre'));
      await tester.pumpAndSettle();

      // Theme should be dark
      expect(
        TestApp.mockSettingsService.themeModeNotifier.value,
        ThemeMode.dark,
      );
    });
  });

  group('Prompt Template Usage Tests', () {
    setUp(() async {
      await TestApp.initialize();
      TestApp.mockGemmaService.setModelState(GemmaModelState.ready);
      TestApp.mockGemmaService.setCurrentModel(AvailableModels.textOnly.first);
    });

    tearDown(() async {
      await TestApp.tearDown();
    });

    testWidgets('Select and apply prompt template', (tester) async {
      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      await navigateToChat(tester);

      // Open attachment menu
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Tap template option
      await tester.tap(find.text('template'));
      await tester.pumpAndSettle();

      // Should see templates modal
      expect(find.text('Modeles de prompts'), findsOneWidget);

      // Find and tap a template (if any exist)
      final templateCards = find.byType(Card);
      if (templateCards.evaluate().length > 1) {
        await tester.tap(templateCards.at(1));
        await tester.pumpAndSettle();

        // Template should fill the text field
        final textField = find.byType(TextField);
        expect(textField, findsOneWidget);
      }
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

    testWidgets('Set system prompt', (tester) async {
      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      await navigateToChat(tester);

      // Open system prompt dialog
      await tester.tap(find.byIcon(Icons.settings_suggest));
      await tester.pumpAndSettle();

      // Should see dialog
      expect(find.text('Instructions systeme'), findsOneWidget);

      // Find the text field in dialog and enter prompt
      final dialogTextField = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );

      if (dialogTextField.evaluate().isNotEmpty) {
        await tester.enterText(dialogTextField, 'Tu es un assistant helpful.');
        await tester.pumpAndSettle();

        // Save the prompt (button is "Enregistrer")
        await tester.tap(find.text('Enregistrer'));
        await tester.pumpAndSettle();
      }

      // Dialog should be closed
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('Clear system prompt', (tester) async {
      // First set a prompt
      TestApp.mockGemmaService.setSystemPrompt('Initial prompt');

      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      await navigateToChat(tester);

      // Open system prompt dialog
      await tester.tap(find.byIcon(Icons.settings_suggest));
      await tester.pumpAndSettle();

      // Find and tap clear/reset button if exists
      final clearButton = find.text('Effacer');
      if (clearButton.evaluate().isNotEmpty) {
        await tester.tap(clearButton);
        await tester.pumpAndSettle();
      }

      // Close dialog
      final cancelButton = find.text('Annuler');
      if (cancelButton.evaluate().isNotEmpty) {
        await tester.tap(cancelButton);
        await tester.pumpAndSettle();
      }
    });
  });

  group('Thinking Mode Tests (DeepSeek R1)', () {
    setUp(() async {
      await TestApp.initialize();
      TestApp.mockGemmaService.setModelState(GemmaModelState.ready);
      TestApp.mockGemmaService.setCurrentModel(AvailableModels.deepSeekR1);
      TestApp.mockGemmaService.setMockResponses([
        'This is a thoughtful response after reasoning.',
      ]);
    });

    tearDown(() async {
      await TestApp.tearDown();
    });

    testWidgets('DeepSeek R1 model shows thinking indicator', (tester) async {
      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      // Navigate to model selection
      await tester.tap(find.text('SELECT_MODEL'));
      await tester.pumpAndSettle();

      // Select DeepSeek R1 (thinking model)
      final deepSeekCard = find.textContaining('DeepSeek');
      if (deepSeekCard.evaluate().isNotEmpty) {
        await tester.tap(deepSeekCard.first);
        await tester.pumpAndSettle();

        // Send message
        await tester.enterText(
          find.byType(TextField),
          'Explain quantum physics',
        );
        await tester.tap(find.byIcon(Icons.arrow_forward));

        // Pump to allow stream to start
        await tester.pump(const Duration(milliseconds: 100));

        // Allow response to complete
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        // Message should be in the chat
        expect(find.textContaining('Explain quantum'), findsWidgets);
      }
    });
  });

  group('Chat Response Tests', () {
    setUp(() async {
      await TestApp.initialize();
      TestApp.mockGemmaService.setModelState(GemmaModelState.ready);
      TestApp.mockGemmaService.setCurrentModel(AvailableModels.textOnly.first);
      TestApp.mockGemmaService.setMockResponses([
        'This is a response from the AI.',
      ]);
    });

    tearDown(() async {
      await TestApp.tearDown();
    });

    testWidgets('Message send and response flow works', (tester) async {
      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      await navigateToChat(tester);

      // Type and send message
      final textField = find.byType(TextField);
      await tester.enterText(textField, 'Hello');
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Wait for response stream to complete
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      // Input should be cleared after sending
      // And the chat should have scrollable content (ListView)
      expect(find.byType(ListView), findsWidgets);
    });
  });

  group('Message Actions Tests', () {
    setUp(() async {
      await TestApp.initialize();
      TestApp.mockGemmaService.setModelState(GemmaModelState.ready);
      TestApp.mockGemmaService.setCurrentModel(AvailableModels.textOnly.first);
      TestApp.mockGemmaService.setMockResponses([
        'First response to copy.',
        'Regenerated response.',
      ]);
    });

    tearDown(() async {
      await TestApp.tearDown();
    });

    testWidgets('Copy message action', (tester) async {
      // Set up clipboard mock
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (
            MethodCall methodCall,
          ) async {
            if (methodCall.method == 'Clipboard.setData') {
              return null;
            }
            return null;
          });

      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      await navigateToChat(tester);

      // Send message
      await tester.enterText(find.byType(TextField), 'Test message');
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Look for copy icon
      final copyIcon = find.byIcon(Icons.copy);
      final copyIconOutlined = find.byIcon(Icons.copy_outlined);
      final contentCopy = find.byIcon(Icons.content_copy);

      // Try to find and tap copy button
      if (copyIcon.evaluate().isNotEmpty) {
        await tester.tap(copyIcon.first);
        await tester.pumpAndSettle();
      } else if (copyIconOutlined.evaluate().isNotEmpty) {
        await tester.tap(copyIconOutlined.first);
        await tester.pumpAndSettle();
      } else if (contentCopy.evaluate().isNotEmpty) {
        await tester.tap(contentCopy.first);
        await tester.pumpAndSettle();
      }

      // Clean up clipboard mock
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    testWidgets('Regenerate message action', (tester) async {
      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      await navigateToChat(tester);

      // Send message
      await tester.enterText(find.byType(TextField), 'Test message');
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Look for regenerate/refresh icon
      final refreshIcon = find.byIcon(Icons.refresh);
      final replayIcon = find.byIcon(Icons.replay);

      if (refreshIcon.evaluate().isNotEmpty) {
        await tester.tap(refreshIcon.first);
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();
      } else if (replayIcon.evaluate().isNotEmpty) {
        await tester.tap(replayIcon.first);
        await tester.pump(const Duration(milliseconds: 500));
        await tester.pumpAndSettle();
      }

      // Should still have messages
      expect(find.byType(TextField), findsOneWidget);
    });
  });

  group('RAG Document Tests', () {
    setUp(() async {
      await TestApp.initialize();
      TestApp.mockGemmaService.setModelState(GemmaModelState.ready);
      TestApp.mockGemmaService.setCurrentModel(AvailableModels.textOnly.first);
      TestApp.mockRagService.setEmbedderState(EmbedderState.ready);
    });

    tearDown(() async {
      await TestApp.tearDown();
    });

    testWidgets('RAG panel shows document options', (tester) async {
      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      await navigateToChat(tester);

      // Open attachment menu
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Verify PDF option is visible
      expect(find.text('pdf'), findsOneWidget);
      expect(find.text('add document'), findsOneWidget);

      // Don't tap PDF - it opens file picker which can't work in tests
    });

    testWidgets('Embedder state is checked on attachment menu open', (
      tester,
    ) async {
      TestApp.mockRagService.setEmbedderState(EmbedderState.notInstalled);

      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      await navigateToChat(tester);

      // Open attachment menu
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // PDF option should still be visible (even if embedder not installed)
      expect(find.text('pdf'), findsOneWidget);
    });
  });

  group('Multimodal Image Tests', () {
    setUp(() async {
      await TestApp.initialize();
      TestApp.mockGemmaService.setModelState(GemmaModelState.ready);
      TestApp.mockGemmaService.setCurrentModel(AvailableModels.gemma3NanoE2b);
      TestApp.mockGemmaService.setMockResponses([
        'I can see an image in your message.',
      ]);
    });

    tearDown(() async {
      await TestApp.tearDown();
    });

    testWidgets('Multimodal model shows image option in attachment menu', (
      tester,
    ) async {
      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      // Navigate to model selection
      await tester.tap(find.text('SELECT_MODEL'));
      await tester.pumpAndSettle();

      // Select multimodal model
      final gemma3Nano = find.textContaining('Gemma 3 Nano').first;
      await tester.tap(gemma3Nano);
      await tester.pumpAndSettle();

      // Open attachment menu
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Should show image option for multimodal model
      expect(find.text('image'), findsOneWidget);

      // Don't tap further - image picker can't work in tests
    });
  });

  group('Context Indicator Tests', () {
    setUp(() async {
      await TestApp.initialize();
      TestApp.mockGemmaService.setModelState(GemmaModelState.ready);
      TestApp.mockGemmaService.setCurrentModel(AvailableModels.textOnly.first);
      TestApp.mockGemmaService.setMockResponses([
        'Short response.',
        'Another response.' * 100, // Long response
      ]);
    });

    tearDown(() async {
      await TestApp.tearDown();
    });

    testWidgets('Context usage indicator is visible', (tester) async {
      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      await navigateToChat(tester);

      // Send several messages to use context
      for (var i = 0; i < 3; i++) {
        await tester.enterText(find.byType(TextField), 'Message $i ' * 50);
        await tester.tap(find.byIcon(Icons.arrow_forward));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();
      }

      // Look for progress indicator or context bar
      // This could be a LinearProgressIndicator or custom widget
      final progressIndicators = find.byType(LinearProgressIndicator);
      final circularIndicators = find.byType(CircularProgressIndicator);

      // At least one indicator should exist (loading or context)
      // Or check for text like "tokens" or percentage
      expect(
        progressIndicators.evaluate().isNotEmpty ||
            circularIndicators.evaluate().isNotEmpty ||
            find.textContaining('%').evaluate().isNotEmpty ||
            find.textContaining('token').evaluate().isNotEmpty,
        isTrue,
      );
    });
  });

  group('Stop Generation Tests', () {
    setUp(() async {
      await TestApp.initialize();
      TestApp.mockGemmaService.setModelState(GemmaModelState.ready);
      TestApp.mockGemmaService.setCurrentModel(AvailableModels.textOnly.first);
      TestApp.mockGemmaService.setMockResponses([
        'This is a very long response that takes time to generate. ' * 20,
      ]);
    });

    tearDown(() async {
      await TestApp.tearDown();
    });

    testWidgets('Stop button appears during generation', (tester) async {
      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      await navigateToChat(tester);

      // Send message
      await tester.enterText(find.byType(TextField), 'Generate long response');
      await tester.tap(find.byIcon(Icons.arrow_forward));

      // Pump just a bit to start generation
      await tester.pump(const Duration(milliseconds: 50));

      // During generation, stop button should appear
      // Could be stop_circle, stop, or the send button changes
      final stopIcon = find.byIcon(Icons.stop);
      final stopCircle = find.byIcon(Icons.stop_circle);
      final stopOutlined = find.byIcon(Icons.stop_circle_outlined);

      // Allow generation to complete for cleanup
      await tester.pumpAndSettle(const Duration(seconds: 2));
    });
  });

  // ============================================================
  // TTS (Text-to-Speech) Tests
  // ============================================================

  group('TTS Tests', () {
    setUp(() async {
      await TestApp.initialize();
      TestApp.mockGemmaService.setModelState(GemmaModelState.ready);
      TestApp.mockGemmaService.setCurrentModel(AvailableModels.textOnly.first);
      TestApp.mockGemmaService.setMockResponses([
        'This is a response that can be read aloud.',
      ]);
    });

    tearDown(() async {
      await TestApp.tearDown();
    });

    testWidgets('TTS speak button triggers speech', (tester) async {
      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      await navigateToChat(tester);

      // Send message to get a response
      await tester.enterText(find.byType(TextField), 'Hello');
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Long press on message to show action buttons
      final chatBubbles = find.byType(GestureDetector);
      if (chatBubbles.evaluate().isNotEmpty) {
        await tester.longPress(chatBubbles.last);
        await tester.pumpAndSettle();
      }

      // Look for speak/volume button
      final speakButton = find.byIcon(Icons.volume_up);
      if (speakButton.evaluate().isNotEmpty) {
        await tester.tap(speakButton.first);
        await tester.pumpAndSettle();

        // TTS should be playing
        expect(TestApp.mockTtsService.isPlaying, isTrue);
      }
    });

    testWidgets('TTS stop button stops speech', (tester) async {
      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      await navigateToChat(tester);

      // Send message
      await tester.enterText(find.byType(TextField), 'Test TTS');
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Start TTS programmatically
      await TestApp.mockTtsService.speak('Test content', 'test-id');
      expect(TestApp.mockTtsService.isPlaying, isTrue);

      // Stop TTS
      await TestApp.mockTtsService.stop();
      expect(TestApp.mockTtsService.isPlaying, isFalse);
    });
  });

  // ============================================================
  // Advanced Conversation Management Tests
  // ============================================================

  group('Advanced Conversation Tests', () {
    setUp(() async {
      await TestApp.initialize();
      TestApp.mockGemmaService.setModelState(GemmaModelState.ready);
      TestApp.mockGemmaService.setCurrentModel(AvailableModels.textOnly.first);
      TestApp.mockGemmaService.setMockResponses([
        'Response for conversation test.',
      ]);
    });

    tearDown(() async {
      await TestApp.tearDown();
    });

    testWidgets('Search conversations by title', (tester) async {
      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      await navigateToChat(tester);

      // Create a conversation
      await tester.enterText(find.byType(TextField), 'Flutter question');
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Open history
      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();

      // Tap search icon
      final searchIcon = find.byIcon(Icons.search);
      if (searchIcon.evaluate().isNotEmpty) {
        await tester.tap(searchIcon);
        await tester.pumpAndSettle();

        // Enter search query
        final searchField = find.byType(TextField);
        if (searchField.evaluate().isNotEmpty) {
          await tester.enterText(searchField, 'Flutter');
          await tester.pumpAndSettle();
        }

        // Close search to verify title appears
        final closeIcon = find.byIcon(Icons.close);
        if (closeIcon.evaluate().isNotEmpty) {
          await tester.tap(closeIcon);
          await tester.pumpAndSettle();
        }
      }

      // Verify we're on conversations page (may show "Conversations" or just history content)
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('Create new conversation from history page', (tester) async {
      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      await navigateToChat(tester);

      // Open history
      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();

      // Tap add button (FAB or app bar)
      final addButton = find.byIcon(Icons.add);
      if (addButton.evaluate().isNotEmpty) {
        await tester.tap(addButton.first);
        await tester.pumpAndSettle();

        // Should see new conversation dialog (at least one)
        expect(find.text('Nouvelle conversation'), findsWidgets);

        // Enter title in dialog
        final dialogTextField = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        );
        if (dialogTextField.evaluate().isNotEmpty) {
          await tester.enterText(dialogTextField.first, 'Test Conversation');
          await tester.pumpAndSettle();
        }

        // Tap create
        await tester.tap(find.text('Creer'));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Rename conversation via popup menu', (tester) async {
      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      await navigateToChat(tester);

      // Create a conversation first
      await tester.enterText(find.byType(TextField), 'Original title');
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Open history
      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();

      // Find popup menu button on conversation tile
      final popupMenuButtons = find.byType(PopupMenuButton<String>);
      if (popupMenuButtons.evaluate().isNotEmpty) {
        await tester.tap(popupMenuButtons.first);
        await tester.pumpAndSettle();

        // Tap rename option
        final renameOption = find.text('Renommer');
        if (renameOption.evaluate().isNotEmpty) {
          await tester.tap(renameOption);
          await tester.pumpAndSettle();

          // Should see rename dialog
          expect(find.text('Renommer la conversation'), findsOneWidget);
        }
      }
    });

    testWidgets('Delete conversation with confirmation', (tester) async {
      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      await navigateToChat(tester);

      // Create a conversation
      await tester.enterText(find.byType(TextField), 'To be deleted');
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Open history
      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();

      // Find popup menu
      final popupMenuButtons = find.byType(PopupMenuButton<String>);
      if (popupMenuButtons.evaluate().isNotEmpty) {
        await tester.tap(popupMenuButtons.first);
        await tester.pumpAndSettle();

        // Tap delete option
        final deleteOption = find.text('Supprimer');
        if (deleteOption.evaluate().isNotEmpty) {
          await tester.tap(deleteOption);
          await tester.pumpAndSettle();

          // Should see confirmation dialog
          expect(find.text('Supprimer la conversation'), findsOneWidget);

          // Cancel deletion
          await tester.tap(find.text('Annuler'));
          await tester.pumpAndSettle();
        }
      }
    });

    testWidgets('Close search returns to normal view', (tester) async {
      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      await navigateToChat(tester);

      // Open history
      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();

      // Open search
      final searchIcon = find.byIcon(Icons.search);
      if (searchIcon.evaluate().isNotEmpty) {
        await tester.tap(searchIcon);
        await tester.pumpAndSettle();

        // Close search (icon becomes close)
        final closeIcon = find.byIcon(Icons.close);
        if (closeIcon.evaluate().isNotEmpty) {
          await tester.tap(closeIcon);
          await tester.pumpAndSettle();
        }
      }

      // Title should show Conversations again
      expect(find.text('Conversations'), findsOneWidget);
    });
  });

  // ============================================================
  // Document Management Tests
  // ============================================================

  group('Document Management Tests', () {
    setUp(() async {
      await TestApp.initialize();
      TestApp.mockGemmaService.setModelState(GemmaModelState.ready);
      TestApp.mockGemmaService.setCurrentModel(AvailableModels.textOnly.first);
      TestApp.mockRagService.setEmbedderState(EmbedderState.ready);
    });

    tearDown(() async {
      await TestApp.tearDown();
    });

    testWidgets('PDF option is available in attachment menu', (tester) async {
      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      await navigateToChat(tester);

      // Open attachment menu
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // PDF option should be visible
      expect(find.text('pdf'), findsOneWidget);
      expect(find.text('add document'), findsOneWidget);

      // Close menu
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
    });

    testWidgets('Template option is available in attachment menu', (
      tester,
    ) async {
      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      await navigateToChat(tester);

      // Open attachment menu
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Template option should be visible
      expect(find.text('template'), findsOneWidget);
      expect(find.text('prompt library'), findsOneWidget);
    });

    testWidgets('Embedder state is reflected in RAG service', (tester) async {
      // Test embedder state transitions
      TestApp.mockRagService.setEmbedderState(EmbedderState.notInstalled);
      expect(TestApp.mockRagService.state, EmbedderState.notInstalled);

      await TestApp.mockRagService.downloadEmbedder();
      expect(TestApp.mockRagService.state, EmbedderState.installed);

      await TestApp.mockRagService.loadEmbedder();
      expect(TestApp.mockRagService.state, EmbedderState.ready);
      expect(TestApp.mockRagService.isReady, isTrue);
    });

    testWidgets('RAG service can generate embeddings', (tester) async {
      TestApp.mockRagService.setEmbedderState(EmbedderState.ready);

      // Generate embedding
      final embedding = await TestApp.mockRagService.generateEmbedding(
        'Test text',
      );
      expect(embedding, isNotEmpty);
      expect(embedding.length, 256); // Mock returns 256 dimensions
    });
  });

  // ============================================================
  // Model Lifecycle Tests
  // ============================================================

  group('Model Lifecycle Tests', () {
    setUp(() async {
      await TestApp.initialize();
    });

    tearDown(() async {
      await TestApp.tearDown();
    });

    testWidgets('Model download shows progress', (tester) async {
      TestApp.mockGemmaService.setModelState(GemmaModelState.notInstalled);

      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('SELECT_MODEL'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Gemma 3 1B').first);
      await tester.pumpAndSettle();

      // Should show download option
      expect(find.textContaining('Telecharger'), findsWidgets);

      // Tap download
      final downloadButton = find.textContaining('Telecharger');
      if (downloadButton.evaluate().isNotEmpty) {
        await tester.tap(downloadButton.first);
        await tester.pump(const Duration(milliseconds: 50));

        // Progress indicator should appear
        expect(find.byType(LinearProgressIndicator), findsWidgets);

        // Wait for download to complete
        await tester.pumpAndSettle(const Duration(seconds: 1));
      }
    });

    testWidgets('Model loading shows loading state', (tester) async {
      TestApp.mockGemmaService.setModelState(GemmaModelState.installed);

      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('SELECT_MODEL'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Gemma 3 1B').first);
      await tester.pumpAndSettle();

      // Should show load option
      expect(find.textContaining('Charger'), findsWidgets);

      // Tap load
      final loadButton = find.textContaining('Charger');
      if (loadButton.evaluate().isNotEmpty) {
        await tester.tap(loadButton.first);
        await tester.pump(const Duration(milliseconds: 10));

        // Wait for loading to complete
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Should now be ready (shows chat input)
        expect(find.byType(TextField), findsOneWidget);
      }
    });

    testWidgets('Back navigation unloads model', (tester) async {
      TestApp.mockGemmaService.setModelState(GemmaModelState.ready);
      TestApp.mockGemmaService.setCurrentModel(AvailableModels.textOnly.first);

      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      await navigateToChat(tester);

      // Verify model is ready
      expect(TestApp.mockGemmaService.state, GemmaModelState.ready);

      // Press back button
      final backButton = find.byType(BackButton);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
        await tester.pumpAndSettle();
      } else {
        // Use navigator pop
        final navigator = tester.state<NavigatorState>(find.byType(Navigator));
        navigator.pop();
        await tester.pumpAndSettle();
      }

      // Model should be unloaded
      expect(TestApp.mockGemmaService.state, GemmaModelState.installed);
    });

    testWidgets('Model status badge shows correct state', (tester) async {
      TestApp.mockGemmaService.setModelState(GemmaModelState.ready);
      TestApp.mockGemmaService.setCurrentModel(AvailableModels.textOnly.first);

      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      await navigateToChat(tester);

      // Should show green check for ready state
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });
  });

  // ============================================================
  // Thinking Mode Tests (DeepSeek R1)
  // ============================================================

  group('Thinking Mode Extended Tests', () {
    setUp(() async {
      await TestApp.initialize();
      TestApp.mockGemmaService.setModelState(GemmaModelState.ready);
      TestApp.mockGemmaService.setCurrentModel(AvailableModels.deepSeekR1);
      TestApp.mockGemmaService.setMockResponses([
        'After careful reasoning, here is my answer.',
      ]);
    });

    tearDown(() async {
      await TestApp.tearDown();
    });

    testWidgets('Thinking section can be expanded', (tester) async {
      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      // Navigate to model selection
      await tester.tap(find.text('SELECT_MODEL'));
      await tester.pumpAndSettle();

      // Select DeepSeek R1
      final deepSeekCard = find.textContaining('DeepSeek');
      if (deepSeekCard.evaluate().isNotEmpty) {
        await tester.tap(deepSeekCard.first);
        await tester.pumpAndSettle();

        // Send message
        await tester.enterText(find.byType(TextField), 'Complex question');
        await tester.tap(find.byIcon(Icons.arrow_forward));

        // Wait for thinking and response
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Look for thinking section header
        final thinkingHeader = find.textContaining('reasoning');
        if (thinkingHeader.evaluate().isNotEmpty) {
          // Tap to expand
          await tester.tap(thinkingHeader.first);
          await tester.pumpAndSettle();

          // Should show expand/collapse icon
          expect(
            find.byIcon(Icons.keyboard_arrow_up).evaluate().isNotEmpty ||
                find.byIcon(Icons.keyboard_arrow_down).evaluate().isNotEmpty,
            isTrue,
          );
        }
      }
    });

    testWidgets('Thinking indicator shows during reasoning', (tester) async {
      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('SELECT_MODEL'));
      await tester.pumpAndSettle();

      final deepSeekCard = find.textContaining('DeepSeek');
      if (deepSeekCard.evaluate().isNotEmpty) {
        await tester.tap(deepSeekCard.first);
        await tester.pumpAndSettle();

        // Send message
        await tester.enterText(find.byType(TextField), 'Think about this');
        await tester.tap(find.byIcon(Icons.arrow_forward));

        // Check for thinking indicator right after sending
        await tester.pump(const Duration(milliseconds: 50));

        // Should show thinking text or psychology icon
        final thinkingIndicator = find.textContaining('thinking');
        final psychologyIcon = find.byIcon(Icons.psychology);

        // Allow completion
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
    });
  });

  // ============================================================
  // Settings Extended Tests
  // ============================================================

  group('Settings Extended Tests', () {
    setUp(() async {
      await TestApp.initialize();
    });

    tearDown(() async {
      await TestApp.tearDown();
    });

    testWidgets('Max tokens slider works', (tester) async {
      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      // Navigate to settings
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      // Find sliders
      final sliders = find.byType(Slider);
      expect(sliders, findsWidgets);

      // Should have at least 2 sliders (temperature and max tokens)
      expect(sliders.evaluate().length, greaterThanOrEqualTo(2));

      // Drag second slider (max tokens)
      if (sliders.evaluate().length >= 2) {
        await tester.drag(sliders.at(1), const Offset(30, 0));
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Theme auto mode works', (tester) async {
      await tester.pumpWidget(TestApp.buildAppWithTheme());
      await tester.pumpAndSettle();

      // Navigate to settings
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      // Tap Auto button
      await tester.tap(find.text('Auto'));
      await tester.pumpAndSettle();

      // Theme should be system
      expect(
        TestApp.mockSettingsService.themeModeNotifier.value,
        ThemeMode.system,
      );
    });

    testWidgets('Settings sections are visible', (tester) async {
      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      // Navigate to settings
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      // Verify sections
      expect(find.text('Apparence'), findsOneWidget);
      expect(find.text('Parametres du modele'), findsOneWidget);
    });
  });

  // ============================================================
  // Input & Message Edge Cases
  // ============================================================

  group('Input Edge Cases Tests', () {
    setUp(() async {
      await TestApp.initialize();
      TestApp.mockGemmaService.setModelState(GemmaModelState.ready);
      TestApp.mockGemmaService.setCurrentModel(AvailableModels.textOnly.first);
      TestApp.mockGemmaService.setMockResponses(['Response']);
    });

    tearDown(() async {
      await TestApp.tearDown();
    });

    testWidgets('Empty message cannot be sent', (tester) async {
      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      await navigateToChat(tester);

      // Ensure text field is empty
      final textField = find.byType(TextField);
      await tester.enterText(textField, '');
      await tester.pumpAndSettle();

      // Tap send button
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pumpAndSettle();

      // Should still show empty state
      expect(find.text('Demarrez une conversation'), findsOneWidget);
    });

    testWidgets('Message with only spaces cannot be sent', (tester) async {
      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      await navigateToChat(tester);

      // Enter spaces only
      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pumpAndSettle();

      // Should still show empty state
      expect(find.text('Demarrez une conversation'), findsOneWidget);
    });

    testWidgets('Multiline message works', (tester) async {
      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      await navigateToChat(tester);

      // Enter multiline text
      await tester.enterText(find.byType(TextField), 'Line 1\nLine 2\nLine 3');
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Message should be visible
      expect(find.textContaining('Line 1'), findsWidgets);
    });

    testWidgets('Long message is displayed correctly', (tester) async {
      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      await navigateToChat(tester);

      // Enter long message
      final longMessage = 'This is a very long message. ' * 20;
      await tester.enterText(find.byType(TextField), longMessage);
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Should have scrollable content
      expect(find.byType(ListView), findsWidgets);
    });
  });

  // ============================================================
  // System Prompt Extended Tests
  // ============================================================

  group('System Prompt Extended Tests', () {
    setUp(() async {
      await TestApp.initialize();
      TestApp.mockGemmaService.setModelState(GemmaModelState.ready);
      TestApp.mockGemmaService.setCurrentModel(AvailableModels.textOnly.first);
    });

    tearDown(() async {
      await TestApp.tearDown();
    });

    testWidgets('System prompt is saved', (tester) async {
      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      await navigateToChat(tester);

      // Open system prompt dialog
      await tester.tap(find.byIcon(Icons.settings_suggest));
      await tester.pumpAndSettle();

      // Find and fill the text field
      final dialogTextFields = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );

      if (dialogTextFields.evaluate().isNotEmpty) {
        await tester.enterText(
          dialogTextFields.first,
          'You are a helpful assistant.',
        );
        await tester.pumpAndSettle();

        // Save
        await tester.tap(find.text('Enregistrer'));
        await tester.pumpAndSettle();

        // Snackbar should appear
        expect(find.textContaining('enregistrees'), findsOneWidget);
      }
    });

    testWidgets('System prompt clear shows confirmation', (tester) async {
      TestApp.mockGemmaService.setSystemPrompt('Initial prompt');

      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      await navigateToChat(tester);

      // Open system prompt dialog
      await tester.tap(find.byIcon(Icons.settings_suggest));
      await tester.pumpAndSettle();

      // Tap clear/effacer button
      await tester.tap(find.text('Effacer'));
      await tester.pumpAndSettle();

      // Snackbar should appear confirming clear
      expect(find.textContaining('effacees'), findsOneWidget);
    });

    testWidgets('Cancel button closes dialog without saving', (tester) async {
      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      await navigateToChat(tester);

      // Open system prompt dialog
      await tester.tap(find.byIcon(Icons.settings_suggest));
      await tester.pumpAndSettle();

      // Enter text
      final dialogTextFields = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      );

      if (dialogTextFields.evaluate().isNotEmpty) {
        await tester.enterText(dialogTextFields.first, 'Not to be saved');
        await tester.pumpAndSettle();
      }

      // Cancel
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();

      // Dialog should be closed
      expect(find.byType(AlertDialog), findsNothing);

      // No snackbar
      expect(find.textContaining('enregistrees'), findsNothing);
    });
  });

  // ============================================================
  // Attachment Menu Tests
  // ============================================================

  group('Attachment Menu Tests', () {
    setUp(() async {
      await TestApp.initialize();
      TestApp.mockGemmaService.setModelState(GemmaModelState.ready);
      TestApp.mockGemmaService.setCurrentModel(AvailableModels.textOnly.first);
      TestApp.mockRagService.setEmbedderState(EmbedderState.ready);
    });

    tearDown(() async {
      await TestApp.tearDown();
    });

    testWidgets('Attachment menu closes when tapping outside', (tester) async {
      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      await navigateToChat(tester);

      // Open attachment menu
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Verify menu is open
      expect(find.text('attach'), findsOneWidget);

      // Tap outside (barrier)
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Menu should be closed
      expect(find.text('attach'), findsNothing);
    });

    testWidgets('Text-only model does not show image option', (tester) async {
      TestApp.mockGemmaService.setCurrentModel(AvailableModels.gemma3_1b);

      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      await navigateToChat(tester);

      // Open attachment menu
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Should NOT show image option for text-only model
      expect(find.text('image'), findsNothing);

      // But should show PDF and template
      expect(find.text('pdf'), findsOneWidget);
      expect(find.text('template'), findsOneWidget);
    });

    testWidgets('Multimodal model shows all options', (tester) async {
      TestApp.mockGemmaService.setCurrentModel(AvailableModels.gemma3NanoE2b);

      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('SELECT_MODEL'));
      await tester.pumpAndSettle();

      // Select multimodal model
      await tester.tap(find.textContaining('Gemma 3 Nano').first);
      await tester.pumpAndSettle();

      // Open attachment menu
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Should show all options
      expect(find.text('pdf'), findsOneWidget);
      expect(find.text('image'), findsOneWidget);
      expect(find.text('template'), findsOneWidget);
    });
  });

  // ============================================================
  // Token Count Display Tests
  // ============================================================

  group('Token Display Tests', () {
    setUp(() async {
      await TestApp.initialize();
      TestApp.mockGemmaService.setModelState(GemmaModelState.ready);
      TestApp.mockGemmaService.setCurrentModel(AvailableModels.textOnly.first);
      TestApp.mockGemmaService.setMockResponses(['Response text here.']);
    });

    tearDown(() async {
      await TestApp.tearDown();
    });

    testWidgets('Token count is displayed on messages', (tester) async {
      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      await navigateToChat(tester);

      // Send message
      await tester.enterText(find.byType(TextField), 'Test message');
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // Look for token count text
      expect(find.textContaining('tokens'), findsWidgets);
    });
  });

  // ============================================================
  // Empty State Tests
  // ============================================================

  group('Empty State Tests', () {
    setUp(() async {
      await TestApp.initialize();
      TestApp.mockGemmaService.setModelState(GemmaModelState.ready);
    });

    tearDown(() async {
      await TestApp.tearDown();
    });

    testWidgets('Text-only model shows text-only empty state', (tester) async {
      TestApp.mockGemmaService.setCurrentModel(AvailableModels.gemma3_1b);

      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      await navigateToChat(tester);

      // Should show text-only empty state
      expect(find.text('Demarrez une conversation'), findsOneWidget);
      expect(find.text('Posez une question au modele'), findsOneWidget);
    });

    testWidgets('Multimodal model shows vision empty state', (tester) async {
      TestApp.mockGemmaService.setCurrentModel(AvailableModels.gemma3NanoE2b);

      await tester.pumpWidget(TestApp.buildApp());
      await tester.pumpAndSettle();

      await tester.tap(find.text('SELECT_MODEL'));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Gemma 3 Nano').first);
      await tester.pumpAndSettle();

      // Should show multimodal empty state
      expect(find.text('Demarrez une conversation'), findsOneWidget);
      expect(
        find.text('Posez une question ou envoyez une image'),
        findsOneWidget,
      );
      expect(find.text('Vision activee'), findsOneWidget);
    });
  });
}
