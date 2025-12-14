import 'package:bloc_test/bloc_test.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:iackathon/core/errors/app_errors.dart';
import 'package:iackathon/data/datasources/database.dart';
import 'package:iackathon/data/datasources/gemma_service.dart';
import 'package:iackathon/data/datasources/rag_service.dart';
import 'package:iackathon/domain/entities/chat_message.dart';
import 'package:iackathon/domain/entities/gemma_model_info.dart';
import 'package:iackathon/presentation/blocs/chat/chat_bloc.dart';
import 'package:iackathon/presentation/blocs/chat/chat_event.dart';
import 'package:iackathon/presentation/blocs/chat/chat_state.dart';

import '../mocks/mock_gemma_service.dart';
import '../mocks/mock_rag_service.dart';

void main() {
  late MockGemmaService mockGemmaService;
  late MockRagService mockRagService;
  late AppDatabase testDatabase;
  late ChatBloc chatBloc;

  final testModel = AvailableModels.textOnly.first;

  setUpAll(() {
    registerFallbackValue(testModel);
  });

  setUp(() {
    mockGemmaService = MockGemmaService();
    mockRagService = MockRagService();
    testDatabase = AppDatabase.forTesting(NativeDatabase.memory());
    chatBloc = ChatBloc(mockGemmaService, mockRagService, testDatabase);
  });

  tearDown(() async {
    await chatBloc.close();
    await testDatabase.close();
  });

  group('ChatBloc Initial State', () {
    test('initial state is correct', () {
      expect(chatBloc.state, const ChatState());
      expect(chatBloc.state.modelState, GemmaModelState.notInstalled);
      expect(chatBloc.state.messages, isEmpty);
      expect(chatBloc.state.isGenerating, false);
    });
  });

  group('ChatInitialize', () {
    blocTest<ChatBloc, ChatState>(
      'emits state with selected model when initialized',
      build: () {
        mockGemmaService.setModelState(GemmaModelState.installed);
        return ChatBloc(mockGemmaService, mockRagService, testDatabase);
      },
      act: (bloc) => bloc.add(ChatInitialize(testModel)),
      expect: () => [
        isA<ChatState>().having(
          (s) => s.selectedModel,
          'selectedModel',
          testModel,
        ),
        isA<ChatState>()
            .having((s) => s.selectedModel, 'selectedModel', testModel)
            .having(
              (s) => s.modelState,
              'modelState',
              GemmaModelState.installed,
            ),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'checks model status on initialize',
      build: () {
        mockGemmaService.setModelState(GemmaModelState.notInstalled);
        return ChatBloc(mockGemmaService, mockRagService, testDatabase);
      },
      act: (bloc) => bloc.add(ChatInitialize(testModel)),
      verify: (_) {
        // Model status was checked
        expect(mockGemmaService.currentModel, testModel);
      },
    );
  });

  group('ChatDownloadModel', () {
    blocTest<ChatBloc, ChatState>(
      'downloads model and updates progress',
      build: () {
        mockGemmaService.setModelState(GemmaModelState.notInstalled);
        final bloc = ChatBloc(mockGemmaService, mockRagService, testDatabase);
        bloc.emit(chatBloc.state.copyWith(selectedModel: testModel));
        return bloc;
      },
      seed: () => ChatState(selectedModel: testModel),
      act: (bloc) => bloc.add(const ChatDownloadModel()),
      wait: const Duration(milliseconds: 200),
      expect: () => [
        isA<ChatState>()
            .having(
              (s) => s.modelState,
              'modelState',
              GemmaModelState.downloading,
            )
            .having((s) => s.downloadProgress, 'downloadProgress', 0.0),
        // Progress updates (multiple states)
        isA<ChatState>().having(
          (s) => s.downloadProgress,
          'downloadProgress',
          greaterThan(0),
        ),
        isA<ChatState>().having(
          (s) => s.downloadProgress,
          'downloadProgress',
          greaterThan(0),
        ),
        isA<ChatState>().having(
          (s) => s.downloadProgress,
          'downloadProgress',
          greaterThan(0),
        ),
        isA<ChatState>().having(
          (s) => s.downloadProgress,
          'downloadProgress',
          greaterThan(0),
        ),
        isA<ChatState>().having(
          (s) => s.downloadProgress,
          'downloadProgress',
          greaterThan(0),
        ),
        isA<ChatState>().having(
          (s) => s.downloadProgress,
          'downloadProgress',
          greaterThan(0),
        ),
        isA<ChatState>().having(
          (s) => s.downloadProgress,
          'downloadProgress',
          greaterThan(0),
        ),
        isA<ChatState>().having(
          (s) => s.downloadProgress,
          'downloadProgress',
          greaterThan(0),
        ),
        isA<ChatState>().having(
          (s) => s.downloadProgress,
          'downloadProgress',
          greaterThan(0),
        ),
        isA<ChatState>().having(
          (s) => s.downloadProgress,
          'downloadProgress',
          greaterThan(0),
        ),
        isA<ChatState>().having(
          (s) => s.modelState,
          'modelState',
          GemmaModelState.installed,
        ),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'does nothing when no model is selected',
      build: () => ChatBloc(mockGemmaService, mockRagService, testDatabase),
      act: (bloc) => bloc.add(const ChatDownloadModel()),
      expect: () => [],
    );
  });

  group('ChatLoadModel', () {
    blocTest<ChatBloc, ChatState>(
      'loads model and transitions to ready state',
      build: () {
        mockGemmaService.setModelState(GemmaModelState.installed);
        return ChatBloc(mockGemmaService, mockRagService, testDatabase);
      },
      act: (bloc) => bloc.add(const ChatLoadModel()),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<ChatState>().having(
          (s) => s.modelState,
          'modelState',
          GemmaModelState.loading,
        ),
        isA<ChatState>().having(
          (s) => s.modelState,
          'modelState',
          GemmaModelState.ready,
        ),
      ],
    );
  });

  group('ChatSendMessage', () {
    blocTest<ChatBloc, ChatState>(
      'sends message and receives response',
      build: () {
        mockGemmaService.setModelState(GemmaModelState.ready);
        mockGemmaService.setMockResponses(['Test response.']);
        return ChatBloc(mockGemmaService, mockRagService, testDatabase);
      },
      act: (bloc) => bloc.add(const ChatSendMessage('Hello')),
      wait: const Duration(milliseconds: 500),
      verify: (bloc) {
        // Verify final state
        expect(bloc.state.messages.length, 2);
        expect(bloc.state.messages.first.role, MessageRole.user);
        expect(bloc.state.messages.first.content, 'Hello');
        expect(bloc.state.messages.last.role, MessageRole.assistant);
        expect(bloc.state.messages.last.content, isNotEmpty);
        expect(bloc.state.messages.last.isStreaming, false);
        expect(bloc.state.isGenerating, false);
      },
    );

    blocTest<ChatBloc, ChatState>(
      'emits error when model is not ready',
      build: () {
        mockGemmaService.setModelState(GemmaModelState.notInstalled);
        return ChatBloc(mockGemmaService, mockRagService, testDatabase);
      },
      act: (bloc) => bloc.add(const ChatSendMessage('Hello')),
      expect: () => [
        isA<ChatState>().having((s) => s.error, 'error', isA<ModelError>()),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'does not send when already generating',
      build: () {
        mockGemmaService.setModelState(GemmaModelState.ready);
        return ChatBloc(mockGemmaService, mockRagService, testDatabase);
      },
      seed: () => const ChatState(
        modelState: GemmaModelState.ready,
        isGenerating: true,
      ),
      act: (bloc) => bloc.add(const ChatSendMessage('Hello')),
      expect: () => [],
    );
  });

  group('ChatClearConversation', () {
    blocTest<ChatBloc, ChatState>(
      'clears all messages',
      build: () => ChatBloc(mockGemmaService, mockRagService, testDatabase),
      seed: () => ChatState(
        messages: [
          ChatMessage(
            id: '1',
            role: MessageRole.user,
            content: 'Hello',
            timestamp: DateTime.now(),
          ),
        ],
      ),
      act: (bloc) => bloc.add(const ChatClearConversation()),
      expect: () => [
        isA<ChatState>().having((s) => s.messages, 'messages', isEmpty),
      ],
    );
  });

  group('ChatStopGeneration', () {
    blocTest<ChatBloc, ChatState>(
      'stops generation and keeps partial content',
      build: () => ChatBloc(mockGemmaService, mockRagService, testDatabase),
      seed: () => ChatState(
        modelState: GemmaModelState.ready,
        isGenerating: true,
        messages: [
          ChatMessage(
            id: '1',
            role: MessageRole.user,
            content: 'Hello',
            timestamp: DateTime.now(),
          ),
          ChatMessage(
            id: '2',
            role: MessageRole.assistant,
            content: 'Partial response...',
            timestamp: DateTime.now(),
            isStreaming: true,
          ),
        ],
      ),
      act: (bloc) => bloc.add(const ChatStopGeneration()),
      expect: () => [
        isA<ChatState>()
            .having((s) => s.isGenerating, 'isGenerating', false)
            .having((s) => s.messages.last.isStreaming, 'isStreaming', false)
            .having(
              (s) => s.messages.last.content,
              'content',
              'Partial response...',
            ),
      ],
    );
  });

  group('Conversation Management', () {
    blocTest<ChatBloc, ChatState>(
      'creates new conversation',
      build: () => ChatBloc(mockGemmaService, mockRagService, testDatabase),
      act: (bloc) =>
          bloc.add(const ChatCreateConversation(title: 'Test Conversation')),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<ChatState>()
            .having(
              (s) => s.currentConversationId,
              'currentConversationId',
              isNotNull,
            )
            .having((s) => s.messages, 'messages', isEmpty),
        // Load conversations called
        isA<ChatState>().having(
          (s) => s.isLoadingConversations,
          'isLoading',
          true,
        ),
        isA<ChatState>().having(
          (s) => s.conversations,
          'conversations',
          isNotEmpty,
        ),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'loads conversations list',
      setUp: () async {
        // Add a test conversation
        await testDatabase
            .into(testDatabase.conversations)
            .insert(ConversationsCompanion.insert(title: 'Test Conv'));
      },
      build: () => ChatBloc(mockGemmaService, mockRagService, testDatabase),
      act: (bloc) => bloc.add(const ChatLoadConversations()),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<ChatState>().having(
          (s) => s.isLoadingConversations,
          'isLoading',
          true,
        ),
        isA<ChatState>()
            .having((s) => s.isLoadingConversations, 'isLoading', false)
            .having((s) => s.conversations.length, 'conversations.length', 1),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'deletes conversation',
      setUp: () async {
        await testDatabase
            .into(testDatabase.conversations)
            .insert(ConversationsCompanion.insert(title: 'To Delete'));
      },
      build: () => ChatBloc(mockGemmaService, mockRagService, testDatabase),
      act: (bloc) async {
        final convs = await testDatabase
            .select(testDatabase.conversations)
            .get();
        if (convs.isNotEmpty) {
          bloc.emit(bloc.state.copyWith(currentConversationId: convs.first.id));
          bloc.add(ChatDeleteConversation(convs.first.id));
        }
      },
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<ChatState>().having(
          (s) => s.currentConversationId,
          'currentConversationId',
          isNotNull,
        ),
        isA<ChatState>()
            .having(
              (s) => s.currentConversationId,
              'currentConversationId',
              null,
            )
            .having((s) => s.messages, 'messages', isEmpty),
        // Load conversations after delete
        isA<ChatState>().having(
          (s) => s.isLoadingConversations,
          'isLoading',
          true,
        ),
        isA<ChatState>().having(
          (s) => s.conversations,
          'conversations',
          isEmpty,
        ),
      ],
    );
  });

  group('RAG - Embedder', () {
    blocTest<ChatBloc, ChatState>(
      'checks embedder status',
      build: () {
        mockRagService.setEmbedderState(EmbedderState.installed);
        return ChatBloc(mockGemmaService, mockRagService, testDatabase);
      },
      act: (bloc) => bloc.add(const ChatCheckEmbedder()),
      expect: () => [
        isA<ChatState>().having(
          (s) => s.embedderState,
          'embedderState',
          EmbedderState.installed,
        ),
      ],
    );

    blocTest<ChatBloc, ChatState>(
      'loads embedder',
      build: () {
        mockRagService.setEmbedderState(EmbedderState.installed);
        return ChatBloc(mockGemmaService, mockRagService, testDatabase);
      },
      act: (bloc) => bloc.add(const ChatLoadEmbedder()),
      wait: const Duration(milliseconds: 100),
      expect: () => [
        isA<ChatState>().having(
          (s) => s.embedderState,
          'state',
          EmbedderState.loading,
        ),
        isA<ChatState>().having(
          (s) => s.embedderState,
          'state',
          EmbedderState.ready,
        ),
      ],
    );
  });

  group('ChatState', () {
    test('isModelReady returns correct value', () {
      expect(
        const ChatState(modelState: GemmaModelState.ready).isModelReady,
        true,
      );
      expect(
        const ChatState(modelState: GemmaModelState.loading).isModelReady,
        false,
      );
    });

    test('isEmbedderReady returns correct value', () {
      expect(
        const ChatState(embedderState: EmbedderState.ready).isEmbedderReady,
        true,
      );
      expect(
        const ChatState(embedderState: EmbedderState.loading).isEmbedderReady,
        false,
      );
    });

    test('estimatedTokensUsed calculates correctly', () {
      final state = ChatState(
        messages: [
          ChatMessage(
            id: '1',
            role: MessageRole.user,
            content: 'Hello world', // 11 chars
            timestamp: DateTime.now(),
          ),
        ],
      );
      // 11 chars / 4 = 2.75 -> ceil = 3
      expect(state.estimatedTokensUsed, 3);
    });

    test('contextUsagePercent clamps to 1.0', () {
      final state = ChatState(
        messages: [
          ChatMessage(
            id: '1',
            role: MessageRole.user,
            content: 'a' * 100000, // Very long message
            timestamp: DateTime.now(),
          ),
        ],
      );
      expect(state.contextUsagePercent, 1.0);
    });

    test('copyWith preserves unchanged values', () {
      final original = ChatState(
        modelState: GemmaModelState.ready,
        selectedModel: testModel,
        isGenerating: true,
      );

      final copied = original.copyWith(isGenerating: false);

      expect(copied.modelState, GemmaModelState.ready);
      expect(copied.selectedModel, testModel);
      expect(copied.isGenerating, false);
    });

    test('copyWith clears error when clearError is true', () {
      final original = ChatState(error: ModelError.notLoaded());

      final copied = original.copyWith(clearError: true);

      expect(copied.error, null);
    });
  });
}
