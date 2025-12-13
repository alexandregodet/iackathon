import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../data/datasources/database.dart';
import '../../../data/datasources/gemma_service.dart';
import '../../../data/datasources/rag_service.dart';
import '../../../domain/entities/chat_message.dart';
import '../../../domain/entities/document_info.dart';
import 'chat_event.dart';
import 'chat_state.dart';

@injectable
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GemmaService _gemmaService;
  final RagService _ragService;
  final AppDatabase _database;
  StreamSubscription<String>? _responseSubscription;

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
      _responseSubscription = _gemmaService
          .generateResponse(promptToSend, imageBytes: event.imageBytes)
          .listen(
        (chunk) => add(ChatStreamChunk(chunk)),
        onDone: () => add(const ChatStreamComplete()),
        onError: (e) {
          emit(state.copyWith(
            isGenerating: false,
            error: e.toString(),
          ));
        },
      );
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

  void _onStreamComplete(
    ChatStreamComplete event,
    Emitter<ChatState> emit,
  ) {
    if (state.messages.isEmpty) return;

    final messages = List<ChatMessage>.from(state.messages);
    final lastMessage = messages.last;

    if (lastMessage.role == MessageRole.assistant) {
      messages[messages.length - 1] = lastMessage.copyWith(
        isStreaming: false,
      );
      emit(state.copyWith(
        messages: messages,
        isGenerating: false,
      ));
    }
  }

  Future<void> _onClearConversation(
    ChatClearConversation event,
    Emitter<ChatState> emit,
  ) async {
    await _gemmaService.clearChat();
    emit(state.copyWith(messages: []));
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

  @override
  Future<void> close() {
    _responseSubscription?.cancel();
    return super.close();
  }
}
