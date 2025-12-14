import 'package:flutter_test/flutter_test.dart';

import 'package:iackathon/core/errors/app_errors.dart';
import 'package:iackathon/data/datasources/gemma_service.dart';
import 'package:iackathon/data/datasources/rag_service.dart';
import 'package:iackathon/domain/entities/chat_message.dart';
import 'package:iackathon/domain/entities/conversation_info.dart';
import 'package:iackathon/domain/entities/document_info.dart';
import 'package:iackathon/domain/entities/gemma_model_info.dart';
import 'package:iackathon/presentation/blocs/chat/chat_state.dart';

void main() {
  group('ChatState', () {
    test('default state has correct values', () {
      const state = ChatState();

      expect(state.modelState, GemmaModelState.notInstalled);
      expect(state.selectedModel, isNull);
      expect(state.downloadProgress, 0.0);
      expect(state.messages, isEmpty);
      expect(state.isGenerating, false);
      expect(state.error, isNull);
      expect(state.conversations, isEmpty);
      expect(state.currentConversationId, isNull);
      expect(state.isLoadingConversations, false);
      expect(state.embedderState, EmbedderState.notInstalled);
      expect(state.embedderDownloadProgress, 0.0);
      expect(state.documents, isEmpty);
      expect(state.isProcessingDocument, false);
      expect(state.documentProcessingCurrent, 0);
      expect(state.documentProcessingTotal, 0);
      expect(state.ragError, isNull);
      expect(state.isThinking, false);
      expect(state.currentThinkingContent, '');
    });

    group('model state getters', () {
      test('isModelReady', () {
        expect(
          const ChatState(modelState: GemmaModelState.ready).isModelReady,
          true,
        );
        expect(
          const ChatState(modelState: GemmaModelState.loading).isModelReady,
          false,
        );
        expect(
          const ChatState(modelState: GemmaModelState.installed).isModelReady,
          false,
        );
        expect(
          const ChatState(modelState: GemmaModelState.notInstalled).isModelReady,
          false,
        );
      });

      test('isModelInstalled', () {
        expect(
          const ChatState(modelState: GemmaModelState.installed).isModelInstalled,
          true,
        );
        expect(
          const ChatState(modelState: GemmaModelState.ready).isModelInstalled,
          true,
        );
        expect(
          const ChatState(modelState: GemmaModelState.notInstalled).isModelInstalled,
          false,
        );
      });

      test('isDownloading', () {
        expect(
          const ChatState(modelState: GemmaModelState.downloading).isDownloading,
          true,
        );
        expect(
          const ChatState(modelState: GemmaModelState.installed).isDownloading,
          false,
        );
      });

      test('isLoading', () {
        expect(
          const ChatState(modelState: GemmaModelState.loading).isLoading,
          true,
        );
        expect(
          const ChatState(modelState: GemmaModelState.ready).isLoading,
          false,
        );
      });

      test('isMultimodal returns false when no model selected', () {
        expect(const ChatState().isMultimodal, false);
      });

      test('isMultimodal returns model value when selected', () {
        final multimodalState = ChatState(
          selectedModel: AvailableModels.gemma3NanoE2b,
        );
        final textOnlyState = ChatState(
          selectedModel: AvailableModels.gemma3_1b,
        );

        expect(multimodalState.isMultimodal, true);
        expect(textOnlyState.isMultimodal, false);
      });

      test('requiresAuth returns false when no model selected', () {
        expect(const ChatState().requiresAuth, false);
      });

      test('supportsThinking returns false when no model selected', () {
        expect(const ChatState().supportsThinking, false);
      });

      test('supportsThinking returns model value when selected', () {
        final thinkingState = ChatState(
          selectedModel: AvailableModels.deepSeekR1,
        );

        expect(thinkingState.supportsThinking, true);
      });
    });

    group('RAG state getters', () {
      test('isEmbedderReady', () {
        expect(
          const ChatState(embedderState: EmbedderState.ready).isEmbedderReady,
          true,
        );
        expect(
          const ChatState(embedderState: EmbedderState.loading).isEmbedderReady,
          false,
        );
      });

      test('isEmbedderInstalled', () {
        expect(
          const ChatState(embedderState: EmbedderState.installed).isEmbedderInstalled,
          true,
        );
        expect(
          const ChatState(embedderState: EmbedderState.ready).isEmbedderInstalled,
          true,
        );
        expect(
          const ChatState(embedderState: EmbedderState.notInstalled).isEmbedderInstalled,
          false,
        );
      });

      test('activeDocuments filters correctly', () {
        final now = DateTime.now();
        final state = ChatState(
          documents: [
            DocumentInfo(
              id: 1,
              name: 'active.pdf',
              filePath: '/path',
              totalChunks: 10,
              createdAt: now,
              isActive: true,
            ),
            DocumentInfo(
              id: 2,
              name: 'inactive.pdf',
              filePath: '/path',
              totalChunks: 5,
              createdAt: now,
              isActive: false,
            ),
            DocumentInfo(
              id: 3,
              name: 'also_active.pdf',
              filePath: '/path',
              totalChunks: 8,
              createdAt: now,
              isActive: true,
            ),
          ],
        );

        expect(state.activeDocuments.length, 2);
        expect(state.activeDocuments.map((d) => d.id), containsAll([1, 3]));
      });

      test('hasActiveDocuments', () {
        final now = DateTime.now();

        expect(const ChatState().hasActiveDocuments, false);

        final stateWithActive = ChatState(
          documents: [
            DocumentInfo(
              id: 1,
              name: 'doc.pdf',
              filePath: '/path',
              totalChunks: 10,
              createdAt: now,
              isActive: true,
            ),
          ],
        );

        expect(stateWithActive.hasActiveDocuments, true);
      });

      test('activeDocumentCount', () {
        final now = DateTime.now();
        final state = ChatState(
          documents: [
            DocumentInfo(id: 1, name: 'a', filePath: '/a', totalChunks: 1, createdAt: now, isActive: true),
            DocumentInfo(id: 2, name: 'b', filePath: '/b', totalChunks: 1, createdAt: now, isActive: false),
            DocumentInfo(id: 3, name: 'c', filePath: '/c', totalChunks: 1, createdAt: now, isActive: true),
          ],
        );

        expect(state.activeDocumentCount, 2);
      });
    });

    group('conversation getters', () {
      test('hasCurrentConversation', () {
        expect(const ChatState().hasCurrentConversation, false);
        expect(
          const ChatState(currentConversationId: 1).hasCurrentConversation,
          true,
        );
      });

      test('currentConversation returns null when no current', () {
        expect(const ChatState().currentConversation, isNull);
      });

      test('currentConversation returns matching conversation', () {
        final now = DateTime.now();
        final state = ChatState(
          currentConversationId: 2,
          conversations: [
            ConversationInfo(id: 1, title: 'First', createdAt: now, updatedAt: now),
            ConversationInfo(id: 2, title: 'Second', createdAt: now, updatedAt: now),
            ConversationInfo(id: 3, title: 'Third', createdAt: now, updatedAt: now),
          ],
        );

        expect(state.currentConversation, isNotNull);
        expect(state.currentConversation!.id, 2);
        expect(state.currentConversation!.title, 'Second');
      });

      test('currentConversation returns null when id not found', () {
        final now = DateTime.now();
        final state = ChatState(
          currentConversationId: 99,
          conversations: [
            ConversationInfo(id: 1, title: 'First', createdAt: now, updatedAt: now),
          ],
        );

        expect(state.currentConversation, isNull);
      });
    });

    group('context usage', () {
      test('estimatedTokensUsed for empty messages', () {
        expect(const ChatState().estimatedTokensUsed, 0);
      });

      test('estimatedTokensUsed calculates from content', () {
        final state = ChatState(
          messages: [
            ChatMessage(
              id: '1',
              role: MessageRole.user,
              content: 'Hello world!', // 12 chars
              timestamp: DateTime.now(),
            ),
          ],
        );

        // 12 chars / 4 = 3 tokens
        expect(state.estimatedTokensUsed, 3);
      });

      test('estimatedTokensUsed includes thinking content', () {
        final state = ChatState(
          messages: [
            ChatMessage(
              id: '1',
              role: MessageRole.assistant,
              content: 'Response', // 8 chars
              timestamp: DateTime.now(),
              thinkingContent: 'Thinking...', // 11 chars
            ),
          ],
        );

        // (8 + 11) / 4 = 4.75 -> ceil = 5
        expect(state.estimatedTokensUsed, 5);
      });

      test('estimatedTokensUsed sums multiple messages', () {
        final state = ChatState(
          messages: [
            ChatMessage(
              id: '1',
              role: MessageRole.user,
              content: 'Hello', // 5 chars
              timestamp: DateTime.now(),
            ),
            ChatMessage(
              id: '2',
              role: MessageRole.assistant,
              content: 'Hi there!', // 9 chars
              timestamp: DateTime.now(),
            ),
          ],
        );

        // (5 + 9) / 4 = 3.5 -> ceil = 4
        expect(state.estimatedTokensUsed, 4);
      });

      test('contextUsagePercent is 0 for empty state', () {
        expect(const ChatState().contextUsagePercent, 0.0);
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

      test('isContextNearlyFull when above 80%', () {
        final state = ChatState(
          messages: [
            ChatMessage(
              id: '1',
              role: MessageRole.user,
              content: 'a' * 30000, // ~7500 tokens, above 80% of 8192
              timestamp: DateTime.now(),
            ),
          ],
        );

        expect(state.isContextNearlyFull, true);
      });

      test('isContextNearlyFull is false when below 80%', () {
        final state = ChatState(
          messages: [
            ChatMessage(
              id: '1',
              role: MessageRole.user,
              content: 'Hello', // Very few tokens
              timestamp: DateTime.now(),
            ),
          ],
        );

        expect(state.isContextNearlyFull, false);
      });
    });

    group('error helpers', () {
      test('hasError', () {
        expect(const ChatState().hasError, false);
        expect(
          ChatState(error: ModelError.notLoaded()).hasError,
          true,
        );
      });

      test('hasRagError', () {
        expect(const ChatState().hasRagError, false);
        expect(
          ChatState(ragError: RagError.embedderNotLoaded()).hasRagError,
          true,
        );
      });

      test('errorMessage', () {
        expect(const ChatState().errorMessage, isNull);

        final state = ChatState(error: ModelError.notLoaded());
        expect(state.errorMessage, isNotNull);
        expect(state.errorMessage, contains('pas charge'));
      });

      test('ragErrorMessage', () {
        expect(const ChatState().ragErrorMessage, isNull);

        final state = ChatState(ragError: RagError.pdfExtractionFailed());
        expect(state.ragErrorMessage, isNotNull);
      });

      test('isErrorRecoverable defaults to true', () {
        expect(const ChatState().isErrorRecoverable, true);
      });

      test('isErrorRecoverable returns error value', () {
        expect(
          ChatState(error: ModelError.corrupted()).isErrorRecoverable,
          false,
        );
        expect(
          ChatState(error: ModelError.notLoaded()).isErrorRecoverable,
          true,
        );
      });

      test('isRagErrorRecoverable defaults to true', () {
        expect(const ChatState().isRagErrorRecoverable, true);
      });
    });

    group('copyWith', () {
      test('preserves all values when no params', () {
        final original = ChatState(
          modelState: GemmaModelState.ready,
          selectedModel: AvailableModels.gemma3_1b,
          downloadProgress: 0.5,
          isGenerating: true,
          isThinking: true,
          currentThinkingContent: 'Thinking...',
        );

        final copied = original.copyWith();

        expect(copied.modelState, GemmaModelState.ready);
        expect(copied.selectedModel, AvailableModels.gemma3_1b);
        expect(copied.downloadProgress, 0.5);
        expect(copied.isGenerating, true);
        expect(copied.isThinking, true);
        expect(copied.currentThinkingContent, 'Thinking...');
      });

      test('clearError clears error', () {
        final original = ChatState(error: ModelError.notLoaded());

        final copied = original.copyWith(clearError: true);

        expect(copied.error, isNull);
      });

      test('clearRagError clears ragError', () {
        final original = ChatState(ragError: RagError.embedderNotLoaded());

        final copied = original.copyWith(clearRagError: true);

        expect(copied.ragError, isNull);
      });

      test('clearCurrentConversation clears conversationId', () {
        const original = ChatState(currentConversationId: 5);

        final copied = original.copyWith(clearCurrentConversation: true);

        expect(copied.currentConversationId, isNull);
      });

      test('updates all fields', () {
        const original = ChatState();
        final now = DateTime.now();

        final copied = original.copyWith(
          modelState: GemmaModelState.ready,
          selectedModel: AvailableModels.deepSeekR1,
          downloadProgress: 1.0,
          messages: [
            ChatMessage(id: '1', role: MessageRole.user, content: 'Hi', timestamp: now),
          ],
          isGenerating: true,
          error: ModelError.notLoaded(),
          conversations: [
            ConversationInfo(id: 1, title: 'Test', createdAt: now, updatedAt: now),
          ],
          currentConversationId: 1,
          isLoadingConversations: true,
          embedderState: EmbedderState.ready,
          embedderDownloadProgress: 1.0,
          documents: [
            DocumentInfo(id: 1, name: 'doc', filePath: '/p', totalChunks: 5, createdAt: now),
          ],
          isProcessingDocument: true,
          documentProcessingCurrent: 3,
          documentProcessingTotal: 10,
          ragError: RagError.embedderNotLoaded(),
          isThinking: true,
          currentThinkingContent: 'Thinking...',
        );

        expect(copied.modelState, GemmaModelState.ready);
        expect(copied.selectedModel, AvailableModels.deepSeekR1);
        expect(copied.downloadProgress, 1.0);
        expect(copied.messages.length, 1);
        expect(copied.isGenerating, true);
        expect(copied.error, isA<ModelError>());
        expect(copied.conversations.length, 1);
        expect(copied.currentConversationId, 1);
        expect(copied.isLoadingConversations, true);
        expect(copied.embedderState, EmbedderState.ready);
        expect(copied.embedderDownloadProgress, 1.0);
        expect(copied.documents.length, 1);
        expect(copied.isProcessingDocument, true);
        expect(copied.documentProcessingCurrent, 3);
        expect(copied.documentProcessingTotal, 10);
        expect(copied.ragError, isA<RagError>());
        expect(copied.isThinking, true);
        expect(copied.currentThinkingContent, 'Thinking...');
      });
    });

    group('equality', () {
      test('same states are equal', () {
        const state1 = ChatState(modelState: GemmaModelState.ready);
        const state2 = ChatState(modelState: GemmaModelState.ready);

        expect(state1, state2);
      });

      test('different modelState makes unequal', () {
        const state1 = ChatState(modelState: GemmaModelState.ready);
        const state2 = ChatState(modelState: GemmaModelState.loading);

        expect(state1, isNot(state2));
      });

      test('props contains all fields', () {
        const state = ChatState();

        // All 18 fields in props
        expect(state.props.length, 18);
      });
    });
  });
}
