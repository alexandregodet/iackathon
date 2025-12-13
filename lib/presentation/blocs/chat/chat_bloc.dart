import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../data/datasources/database.dart';
import '../../../data/datasources/gemma_service.dart';
import '../../../data/datasources/rag_service.dart';
import '../../../domain/entities/chat_message.dart';
import '../../../domain/entities/conversation_info.dart';
import '../../../domain/entities/document_info.dart';
import 'chat_event.dart';
import 'chat_state.dart';

@injectable
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GemmaService _gemmaService;
  final RagService _ragService;
  final AppDatabase _database;
  StreamSubscription<String>? _responseSubscription;
  StreamSubscription<GemmaStreamResponse>? _thinkingResponseSubscription;

  ChatBloc(this._gemmaService, this._ragService, this._database)
      : super(const ChatState()) {
    on<ChatInitialize>(_onInitialize);
    on<ChatDownloadModel>(_onDownloadModel);
    on<ChatLoadModel>(_onLoadModel);
    on<ChatSendMessage>(_onSendMessage);
    on<ChatStreamChunk>(_onStreamChunk);
    on<ChatStreamComplete>(_onStreamComplete);
    on<ChatClearConversation>(_onClearConversation);
    // RAG events
    on<ChatCheckEmbedder>(_onCheckEmbedder);
    on<ChatDownloadEmbedder>(_onDownloadEmbedder);
    on<ChatLoadEmbedder>(_onLoadEmbedder);
    on<ChatLoadDocuments>(_onLoadDocuments);
    on<ChatDocumentSelected>(_onDocumentSelected);
    on<ChatDocumentProcessingProgress>(_onDocumentProcessingProgress);
    on<ChatToggleDocument>(_onToggleDocument);
    on<ChatRemoveDocument>(_onRemoveDocument);
    // Thinking events
    on<ChatThinkingChunk>(_onThinkingChunk);
    on<ChatThinkingComplete>(_onThinkingComplete);
    // Conversation events
    on<ChatLoadConversations>(_onLoadConversations);
    on<ChatCreateConversation>(_onCreateConversation);
    on<ChatLoadConversation>(_onLoadConversation);
    on<ChatDeleteConversation>(_onDeleteConversation);
    on<ChatRenameConversation>(_onRenameConversation);
    // Message action events
    on<ChatCopyMessage>(_onCopyMessage);
    on<ChatRegenerateMessage>(_onRegenerateMessage);
    on<ChatStopGeneration>(_onStopGeneration);
    on<ChatStreamError>(_onStreamError);
  }

  Future<void> _onInitialize(
    ChatInitialize event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(selectedModel: event.modelInfo));
    await _gemmaService.checkModelStatus(event.modelInfo);
    emit(state.copyWith(
      modelState: _gemmaService.state,
      selectedModel: event.modelInfo,
    ));
  }

  Future<void> _onDownloadModel(
    ChatDownloadModel event,
    Emitter<ChatState> emit,
  ) async {
    if (state.selectedModel == null) return;

    try {
      emit(state.copyWith(
        modelState: GemmaModelState.downloading,
        downloadProgress: 0.0,
      ));

      await _gemmaService.downloadModel(
        state.selectedModel!,
        token: event.huggingFaceToken,
        onProgress: (progress) {
          emit(state.copyWith(downloadProgress: progress));
        },
      );

      emit(state.copyWith(modelState: GemmaModelState.installed));
    } catch (e) {
      emit(state.copyWith(
        modelState: GemmaModelState.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onLoadModel(
    ChatLoadModel event,
    Emitter<ChatState> emit,
  ) async {
    try {
      emit(state.copyWith(modelState: GemmaModelState.loading));
      await _gemmaService.loadModel();
      emit(state.copyWith(modelState: GemmaModelState.ready));
    } catch (e) {
      emit(state.copyWith(
        modelState: GemmaModelState.error,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onSendMessage(
    ChatSendMessage event,
    Emitter<ChatState> emit,
  ) async {
    if (!_gemmaService.isReady || state.isGenerating) return;

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.user,
      content: event.message,
      timestamp: DateTime.now(),
      imageBytes: event.imageBytes,
    );

    final assistantMessage = ChatMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}_assistant',
      role: MessageRole.assistant,
      content: '',
      timestamp: DateTime.now(),
      isStreaming: true,
    );

    emit(state.copyWith(
      messages: [...state.messages, userMessage, assistantMessage],
      isGenerating: true,
    ));

    // Save user message to database if we have a conversation
    if (state.currentConversationId != null) {
      await _saveMessageToDb(userMessage, state.currentConversationId!);
    }

    try {
      // Build augmented prompt if RAG is active
      String promptToSend = event.message;
      if (state.hasActiveDocuments && _ragService.isReady) {
        promptToSend = await _ragService.buildAugmentedPrompt(
          userQuery: event.message,
          topK: 3,
          threshold: 0.5,
        );
      }

      _responseSubscription?.cancel();
      _thinkingResponseSubscription?.cancel();

      // Use thinking-aware generation for models that support it
      if (_gemmaService.supportsThinking) {
        emit(state.copyWith(isThinking: true, currentThinkingContent: ''));

        _thinkingResponseSubscription = _gemmaService
            .generateResponseWithThinking(promptToSend, imageBytes: event.imageBytes)
            .listen(
          (response) {
            if (response.isThinkingPhase && response.thinkingChunk != null) {
              add(ChatThinkingChunk(response.thinkingChunk!));
            } else if (response.textChunk != null) {
              add(ChatStreamChunk(response.textChunk!));
            }
          },
          onDone: () {
            add(const ChatThinkingComplete());
            add(const ChatStreamComplete());
          },
          onError: (e) => add(ChatStreamError(e.toString())),
        );
      } else {
        _responseSubscription = _gemmaService
            .generateResponse(promptToSend, imageBytes: event.imageBytes)
            .listen(
          (chunk) => add(ChatStreamChunk(chunk)),
          onDone: () => add(const ChatStreamComplete()),
          onError: (e) => add(ChatStreamError(e.toString())),
        );
      }
    } catch (e) {
      emit(state.copyWith(
        isGenerating: false,
        error: e.toString(),
      ));
    }
  }

  void _onStreamChunk(
    ChatStreamChunk event,
    Emitter<ChatState> emit,
  ) {
    if (state.messages.isEmpty) return;

    final messages = List<ChatMessage>.from(state.messages);
    final lastMessage = messages.last;

    if (lastMessage.role == MessageRole.assistant) {
      messages[messages.length - 1] = lastMessage.copyWith(
        content: lastMessage.content + event.chunk,
      );
      emit(state.copyWith(messages: messages));
    }
  }

  Future<void> _onStreamComplete(
    ChatStreamComplete event,
    Emitter<ChatState> emit,
  ) async {
    if (state.messages.isEmpty) return;

    final messages = List<ChatMessage>.from(state.messages);
    final lastMessage = messages.last;

    if (lastMessage.role == MessageRole.assistant) {
      final completedMessage = lastMessage.copyWith(isStreaming: false);
      messages[messages.length - 1] = completedMessage;

      emit(state.copyWith(
        messages: messages,
        isGenerating: false,
      ));

      // Save assistant message to database if we have a conversation
      if (state.currentConversationId != null && completedMessage.content.isNotEmpty) {
        await _saveMessageToDb(completedMessage, state.currentConversationId!);
      }
    }
  }

  Future<void> _onClearConversation(
    ChatClearConversation event,
    Emitter<ChatState> emit,
  ) async {
    await _gemmaService.clearChat();
    emit(state.copyWith(messages: []));
  }

  // ============== THINKING HANDLERS ==============

  void _onThinkingChunk(
    ChatThinkingChunk event,
    Emitter<ChatState> emit,
  ) {
    // Accumulate thinking content in state
    final newThinkingContent = state.currentThinkingContent + event.chunk;
    emit(state.copyWith(currentThinkingContent: newThinkingContent));

    // Also update the current assistant message with thinking content
    if (state.messages.isEmpty) return;

    final messages = List<ChatMessage>.from(state.messages);
    final lastMessage = messages.last;

    if (lastMessage.role == MessageRole.assistant) {
      messages[messages.length - 1] = lastMessage.copyWith(
        thinkingContent: newThinkingContent,
      );
      emit(state.copyWith(messages: messages));
    }
  }

  void _onThinkingComplete(
    ChatThinkingComplete event,
    Emitter<ChatState> emit,
  ) {
    emit(state.copyWith(isThinking: false));

    // Mark thinking as complete on the message
    if (state.messages.isEmpty) return;

    final messages = List<ChatMessage>.from(state.messages);
    final lastMessage = messages.last;

    if (lastMessage.role == MessageRole.assistant) {
      messages[messages.length - 1] = lastMessage.copyWith(
        isThinkingComplete: true,
      );
      emit(state.copyWith(messages: messages));
    }
  }

  // ============== RAG HANDLERS ==============

  Future<void> _onCheckEmbedder(
    ChatCheckEmbedder event,
    Emitter<ChatState> emit,
  ) async {
    await _ragService.checkEmbedderStatus();
    emit(state.copyWith(embedderState: _ragService.state));
  }

  Future<void> _onDownloadEmbedder(
    ChatDownloadEmbedder event,
    Emitter<ChatState> emit,
  ) async {
    try {
      emit(state.copyWith(
        embedderState: EmbedderState.downloading,
        embedderDownloadProgress: 0.0,
      ));

      await _ragService.downloadEmbedder(
        onProgress: (progress) {
          emit(state.copyWith(embedderDownloadProgress: progress));
        },
      );

      emit(state.copyWith(embedderState: EmbedderState.installed));
    } catch (e) {
      emit(state.copyWith(
        embedderState: EmbedderState.error,
        ragError: e.toString(),
      ));
    }
  }

  Future<void> _onLoadEmbedder(
    ChatLoadEmbedder event,
    Emitter<ChatState> emit,
  ) async {
    try {
      emit(state.copyWith(embedderState: EmbedderState.loading));
      await _ragService.loadEmbedder();
      emit(state.copyWith(embedderState: EmbedderState.ready));
    } catch (e) {
      emit(state.copyWith(
        embedderState: EmbedderState.error,
        ragError: e.toString(),
      ));
    }
  }

  Future<void> _onLoadDocuments(
    ChatLoadDocuments event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final docs = await _database.select(_database.documents).get();
      final documentInfos = docs
          .map((d) => DocumentInfo(
                id: d.id,
                name: d.name,
                filePath: d.filePath,
                totalChunks: d.totalChunks,
                createdAt: d.createdAt,
                lastUsedAt: d.lastUsedAt,
                isActive: d.isActive,
              ))
          .toList();
      emit(state.copyWith(documents: documentInfos));
    } catch (e) {
      emit(state.copyWith(ragError: e.toString()));
    }
  }

  Future<void> _onDocumentSelected(
    ChatDocumentSelected event,
    Emitter<ChatState> emit,
  ) async {
    try {
      emit(state.copyWith(
        isProcessingDocument: true,
        documentProcessingCurrent: 0,
        documentProcessingTotal: 0,
      ));

      // Extract text from PDF
      final text = await _ragService.extractTextFromPdf(event.filePath);

      // Insert document into database
      final docId = await _database.into(_database.documents).insert(
            DocumentsCompanion.insert(
              name: event.fileName,
              filePath: event.filePath,
              isActive: const Value(true),
            ),
          );

      // Chunk the text
      final chunks = _ragService.chunkText(
        text: text,
        documentId: docId,
      );

      // Add chunks to vector store with progress
      await _ragService.addDocumentChunks(
        chunks,
        onProgress: (current, total) {
          add(ChatDocumentProcessingProgress(current: current, total: total));
        },
      );

      // Update document with chunk count
      await (_database.update(_database.documents)
            ..where((d) => d.id.equals(docId)))
          .write(DocumentsCompanion(totalChunks: Value(chunks.length)));

      // Reload documents list
      add(const ChatLoadDocuments());

      emit(state.copyWith(isProcessingDocument: false));
    } catch (e) {
      emit(state.copyWith(
        isProcessingDocument: false,
        ragError: e.toString(),
      ));
    }
  }

  void _onDocumentProcessingProgress(
    ChatDocumentProcessingProgress event,
    Emitter<ChatState> emit,
  ) {
    emit(state.copyWith(
      documentProcessingCurrent: event.current,
      documentProcessingTotal: event.total,
    ));
  }

  Future<void> _onToggleDocument(
    ChatToggleDocument event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await (_database.update(_database.documents)
            ..where((d) => d.id.equals(event.documentId)))
          .write(DocumentsCompanion(isActive: Value(event.isActive)));

      // Update last used if activating
      if (event.isActive) {
        await (_database.update(_database.documents)
              ..where((d) => d.id.equals(event.documentId)))
            .write(DocumentsCompanion(lastUsedAt: Value(DateTime.now())));
      }

      add(const ChatLoadDocuments());
    } catch (e) {
      emit(state.copyWith(ragError: e.toString()));
    }
  }

  Future<void> _onRemoveDocument(
    ChatRemoveDocument event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await (_database.delete(_database.documents)
            ..where((d) => d.id.equals(event.documentId)))
          .go();

      add(const ChatLoadDocuments());
    } catch (e) {
      emit(state.copyWith(ragError: e.toString()));
    }
  }

  // ============== CONVERSATION HANDLERS ==============

  Future<void> _onLoadConversations(
    ChatLoadConversations event,
    Emitter<ChatState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoadingConversations: true));

      final convos = await (_database.select(_database.conversations)
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .get();

      final conversationInfos = <ConversationInfo>[];

      for (final conv in convos) {
        final messagesQuery = _database.select(_database.messages)
          ..where((m) => m.conversationId.equals(conv.id))
          ..orderBy([(m) => OrderingTerm.desc(m.createdAt)])
          ..limit(1);

        final lastMessageResult = await messagesQuery.get();
        final messageCount = await (_database.select(_database.messages)
              ..where((m) => m.conversationId.equals(conv.id)))
            .get()
            .then((msgs) => msgs.length);

        conversationInfos.add(ConversationInfo(
          id: conv.id,
          title: conv.title,
          createdAt: conv.createdAt,
          updatedAt: conv.updatedAt,
          messageCount: messageCount,
          lastMessage: lastMessageResult.isNotEmpty
              ? lastMessageResult.first.content
              : null,
        ));
      }

      emit(state.copyWith(
        conversations: conversationInfos,
        isLoadingConversations: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingConversations: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onCreateConversation(
    ChatCreateConversation event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final title = event.title ?? 'Nouvelle conversation';
      final now = DateTime.now();

      final id = await _database.into(_database.conversations).insert(
            ConversationsCompanion.insert(
              title: title,
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );

      await _gemmaService.clearChat();
      emit(state.copyWith(
        currentConversationId: id,
        messages: [],
      ));

      add(const ChatLoadConversations());
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onLoadConversation(
    ChatLoadConversation event,
    Emitter<ChatState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoadingConversations: true));

      final dbMessages = await (_database.select(_database.messages)
            ..where((m) => m.conversationId.equals(event.conversationId))
            ..orderBy([(m) => OrderingTerm.asc(m.createdAt)]))
          .get();

      final messages = dbMessages
          .map((m) => ChatMessage(
                id: m.id.toString(),
                role: m.role == 'user' ? MessageRole.user : MessageRole.assistant,
                content: m.content,
                timestamp: m.createdAt,
              ))
          .toList();

      await _gemmaService.clearChat();

      emit(state.copyWith(
        currentConversationId: event.conversationId,
        messages: messages,
        isLoadingConversations: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingConversations: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onDeleteConversation(
    ChatDeleteConversation event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await (_database.delete(_database.conversations)
            ..where((c) => c.id.equals(event.conversationId)))
          .go();

      if (state.currentConversationId == event.conversationId) {
        await _gemmaService.clearChat();
        emit(state.copyWith(
          clearCurrentConversation: true,
          messages: [],
        ));
      }

      add(const ChatLoadConversations());
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _onRenameConversation(
    ChatRenameConversation event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await (_database.update(_database.conversations)
            ..where((c) => c.id.equals(event.conversationId)))
          .write(ConversationsCompanion(
            title: Value(event.newTitle),
            updatedAt: Value(DateTime.now()),
          ));

      add(const ChatLoadConversations());
    } catch (e) {
      emit(state.copyWith(error: e.toString()));
    }
  }

  Future<void> _saveMessageToDb(ChatMessage message, int conversationId) async {
    await _database.into(_database.messages).insert(
          MessagesCompanion.insert(
            conversationId: conversationId,
            role: message.role == MessageRole.user ? 'user' : 'assistant',
            content: message.content,
            createdAt: Value(message.timestamp),
          ),
        );

    await (_database.update(_database.conversations)
          ..where((c) => c.id.equals(conversationId)))
        .write(ConversationsCompanion(updatedAt: Value(DateTime.now())));
  }

  // ============== MESSAGE ACTION HANDLERS ==============

  Future<void> _onCopyMessage(
    ChatCopyMessage event,
    Emitter<ChatState> emit,
  ) async {
    final message = state.messages.firstWhere(
      (m) => m.id == event.messageId,
      orElse: () => throw Exception('Message not found'),
    );
    await Clipboard.setData(ClipboardData(text: message.content));
  }

  Future<void> _onRegenerateMessage(
    ChatRegenerateMessage event,
    Emitter<ChatState> emit,
  ) async {
    if (state.isGenerating) return;

    // Find the assistant message index
    final assistantIndex = state.messages.indexWhere(
      (m) => m.id == event.assistantMessageId,
    );

    if (assistantIndex == -1 || assistantIndex == 0) return;

    // Find the preceding user message
    final userMessage = state.messages[assistantIndex - 1];
    if (userMessage.role != MessageRole.user) return;

    // Remove the assistant message from state
    final updatedMessages = List<ChatMessage>.from(state.messages)
      ..removeAt(assistantIndex);

    emit(state.copyWith(messages: updatedMessages));

    // Re-send the user message
    add(ChatSendMessage(userMessage.content, imageBytes: userMessage.imageBytes));
  }

  Future<void> _onStopGeneration(
    ChatStopGeneration event,
    Emitter<ChatState> emit,
  ) async {
    // Cancel active subscriptions
    await _responseSubscription?.cancel();
    await _thinkingResponseSubscription?.cancel();
    _responseSubscription = null;
    _thinkingResponseSubscription = null;

    // Mark the last message as no longer streaming, keep partial content
    if (state.messages.isEmpty) {
      emit(state.copyWith(isGenerating: false, isThinking: false));
      return;
    }

    final messages = List<ChatMessage>.from(state.messages);
    final lastMessage = messages.last;

    if (lastMessage.role == MessageRole.assistant && lastMessage.isStreaming) {
      final stoppedMessage = lastMessage.copyWith(isStreaming: false);
      messages[messages.length - 1] = stoppedMessage;

      emit(state.copyWith(
        messages: messages,
        isGenerating: false,
        isThinking: false,
      ));

      // Save partial message to database if conversation exists
      if (state.currentConversationId != null &&
          stoppedMessage.content.isNotEmpty) {
        await _saveMessageToDb(stoppedMessage, state.currentConversationId!);
      }
    } else {
      emit(state.copyWith(isGenerating: false, isThinking: false));
    }
  }

  void _onStreamError(
    ChatStreamError event,
    Emitter<ChatState> emit,
  ) {
    emit(state.copyWith(
      isGenerating: false,
      isThinking: false,
      error: event.error,
    ));
  }

  @override
  Future<void> close() {
    _responseSubscription?.cancel();
    _thinkingResponseSubscription?.cancel();
    return super.close();
  }
}
