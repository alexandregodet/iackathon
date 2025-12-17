import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/errors/app_errors.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/datasources/checklist_service.dart';
import '../../../data/datasources/database.dart';
import '../../../data/datasources/gemma_service.dart';
import '../../../data/datasources/rag_service.dart';
import '../../../data/datasources/settings_service.dart';
import '../../../domain/entities/chat_message.dart';
import '../../../domain/entities/checklist_question.dart';
import '../../../domain/entities/checklist_response.dart';
import '../../../domain/entities/checklist_session.dart';
import '../../../domain/entities/conversation_info.dart';
import '../../../domain/entities/document_info.dart';
import 'chat_event.dart';
import 'chat_state.dart';

@injectable
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GemmaService _gemmaService;
  final RagService _ragService;
  final AppDatabase _database;
  final SettingsService _settingsService;
  final ChecklistService _checklistService;
  StreamSubscription<String>? _responseSubscription;
  StreamSubscription<GemmaStreamResponse>? _thinkingResponseSubscription;

  ChatBloc(
    this._gemmaService,
    this._ragService,
    this._database,
    this._settingsService,
    this._checklistService,
  )
    : super(const ChatState()) {
    on<ChatInitialize>(_onInitialize);
    on<ChatDownloadModel>(_onDownloadModel);
    on<ChatLoadModel>(_onLoadModel);
    on<ChatUnloadModel>(_onUnloadModel);
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
    // Checklists events
    on<ChatResetChecklistsFlag>(_onResetChecklistsFlag);
    on<ChatLoadChecklists>(_onLoadChecklists);
    // Checklist Session events
    on<ChatInitializeChecklistService>(_onInitializeChecklistService);
    on<ChatChecklistShowRemaining>(_onChecklistShowRemaining);
    on<ChatChecklistGenerateReport>(_onChecklistGenerateReport);
    on<ChatChecklistEndSession>(_onChecklistEndSession);
  }

  Future<void> _onInitialize(
    ChatInitialize event,
    Emitter<ChatState> emit,
  ) async {
    emit(state.copyWith(selectedModel: event.modelInfo));
    await _gemmaService.checkModelStatus(event.modelInfo);
    emit(
      state.copyWith(
        modelState: _gemmaService.state,
        selectedModel: event.modelInfo,
      ),
    );

    // Initialiser le ChecklistService automatiquement
    try {
      if (!_checklistService.isLoaded) {
        await _checklistService.loadChecklistFromAsset();
        AppLogger.info(
          'ChecklistService auto-initialise avec ${_checklistService.sections.length} sections',
          'ChatBloc',
        );
      }
    } catch (e, stack) {
      AppLogger.error(
        'Erreur auto-init ChecklistService',
        tag: 'ChatBloc',
        error: e,
        stackTrace: stack,
      );
    }
  }

  Future<void> _onDownloadModel(
    ChatDownloadModel event,
    Emitter<ChatState> emit,
  ) async {
    if (state.selectedModel == null) return;

    AppLogger.info('Demarrage du telechargement du modele', 'ChatBloc');

    try {
      emit(
        state.copyWith(
          modelState: GemmaModelState.downloading,
          downloadProgress: 0.0,
          clearError: true,
        ),
      );

      await _gemmaService.downloadModel(
        state.selectedModel!,
        token: event.huggingFaceToken,
        onProgress: (progress) {
          emit(state.copyWith(downloadProgress: progress));
        },
      );

      emit(state.copyWith(modelState: GemmaModelState.installed));
    } on AppError catch (e) {
      AppLogger.logAppError(e, 'ChatBloc');
      emit(state.copyWith(modelState: GemmaModelState.error, error: e));
    } catch (e, stack) {
      AppLogger.error(
        'Erreur inattendue telechargement',
        tag: 'ChatBloc',
        error: e,
        stackTrace: stack,
      );
      emit(
        state.copyWith(
          modelState: GemmaModelState.error,
          error: NetworkError.downloadFailed(original: e, stack: stack),
        ),
      );
    }
  }

  Future<void> _onLoadModel(
    ChatLoadModel event,
    Emitter<ChatState> emit,
  ) async {
    final maxTokens = _settingsService.maxTokens;
    AppLogger.info('Chargement du modele (maxTokens: $maxTokens)', 'ChatBloc');

    try {
      emit(
        state.copyWith(modelState: GemmaModelState.loading, clearError: true),
      );
      await _gemmaService.loadModel(maxTokens: maxTokens);
      emit(state.copyWith(modelState: GemmaModelState.ready));
    } on AppError catch (e) {
      AppLogger.logAppError(e, 'ChatBloc');
      emit(state.copyWith(modelState: GemmaModelState.error, error: e));
    } catch (e, stack) {
      AppLogger.error(
        'Erreur inattendue chargement',
        tag: 'ChatBloc',
        error: e,
        stackTrace: stack,
      );
      emit(
        state.copyWith(
          modelState: GemmaModelState.error,
          error: ModelError.loadingFailed(original: e, stack: stack),
        ),
      );
    }
  }

  Future<void> _onUnloadModel(
    ChatUnloadModel event,
    Emitter<ChatState> emit,
  ) async {
    AppLogger.info('Dechargement du modele', 'ChatBloc');
    await _gemmaService.unloadModel();
    emit(state.copyWith(modelState: GemmaModelState.installed));
  }

  Future<void> _onSendMessage(
    ChatSendMessage event,
    Emitter<ChatState> emit,
  ) async {
    // Verifier que le modele est pret
    if (!_gemmaService.isReady) {
      AppLogger.warning('Tentative d\'envoi sans modele charge', 'ChatBloc');
      emit(state.copyWith(error: ModelError.notLoaded()));
      return;
    }

    if (state.isGenerating) return;

    AppLogger.debug('Envoi du message', 'ChatBloc');

    // ============== CHECKLIST TRIGGERS ==============
    final lowerMessage = event.message.toLowerCase();

    // S'assurer que le ChecklistService est charge (fallback)
    if (!_checklistService.isLoaded) {
      try {
        await _checklistService.loadChecklistFromAsset();
        AppLogger.info(
          'ChecklistService charge (fallback) avec ${_checklistService.sections.length} sections',
          'ChatBloc',
        );
      } catch (e) {
        AppLogger.warning('Impossible de charger checklist: $e', 'ChatBloc');
      }
    }

    // Detecter trigger de rapport JSON
    if (_isReportTrigger(lowerMessage)) {
      add(const ChatChecklistGenerateReport());
      return;
    }

    // Detecter demande "qu'est-ce qu'il me reste?"
    if (_isRemainingTrigger(lowerMessage)) {
      add(const ChatChecklistShowRemaining());
      return;
    }

    // Detecter fin de session
    if (_isEndSessionTrigger(lowerMessage)) {
      add(const ChatChecklistEndSession());
      return;
    }

    // Detecter section si pas de session active
    if (_checklistService.isLoaded && !state.hasActiveChecklistSession) {
      AppLogger.debug(
        'Tentative detection section: "${event.message}"',
        'ChatBloc',
      );
      final section = _checklistService.detectSection(event.message);
      if (section != null) {
        AppLogger.info(
          'Section detectee: ${section.title}',
          'ChatBloc',
        );
        await _handleChecklistStartSession(section, emit);
        return;
      } else {
        AppLogger.debug('Aucune section detectee', 'ChatBloc');
      }
    }

    // Si session checklist active, traiter comme reponse
    if (state.hasActiveChecklistSession) {
      await _handleChecklistAnswer(event.message, emit);
      return;
    }
    // ============== FIN CHECKLIST TRIGGERS ==============

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

    emit(
      state.copyWith(
        messages: [...state.messages, userMessage, assistantMessage],
        isGenerating: true,
        clearError: true,
      ),
    );

    // Save user message to database if we have a conversation
    if (state.currentConversationId != null) {
      await _saveMessageToDb(userMessage, state.currentConversationId!);
    }

    try {
      // Build augmented prompt if RAG is active (documents ou checklists)
      // Ne pas utiliser le RAG si les checklists sont en cours de chargement
      String promptToSend = event.message;
      final useRag = _ragService.isReady &&
          (state.hasActiveDocuments || state.checklistsLoaded) &&
          !state.checklistsLoading; // Pas de RAG pendant le chargement
      if (useRag) {
        try {
          promptToSend = await _ragService.buildAugmentedPrompt(
            userQuery: event.message,
            topK: 2, // Réduit pour éviter de dépasser la limite de tokens
            threshold: 0.5,
          );
          // Limiter la taille du prompt pour ne pas dépasser la limite du modèle
          if (promptToSend.length > 3000) {
            promptToSend = '${promptToSend.substring(0, 3000)}\n...[tronque]';
          }
          AppLogger.debug('RAG prompt augmente: ${promptToSend.length} chars', 'ChatBloc');
        } catch (e) {
          AppLogger.warning('RAG search failed, using original prompt: $e', 'ChatBloc');
          // Continue avec le prompt original
        }
      }

      _responseSubscription?.cancel();
      _thinkingResponseSubscription?.cancel();

      // Use thinking-aware generation for models that support it
      if (_gemmaService.supportsThinking) {
        emit(state.copyWith(isThinking: true, currentThinkingContent: ''));

        _thinkingResponseSubscription = _gemmaService
            .generateResponseWithThinking(
              promptToSend,
              imageBytes: event.imageBytes,
            )
            .listen(
              (response) {
                if (response.isThinkingPhase &&
                    response.thinkingChunk != null) {
                  add(ChatThinkingChunk(response.thinkingChunk!));
                } else if (response.textChunk != null) {
                  add(ChatStreamChunk(response.textChunk!));
                }
              },
              onDone: () {
                add(const ChatThinkingComplete());
                add(const ChatStreamComplete());
              },
              onError: (e) => add(
                ChatStreamError(
                  e is AppError ? e : ModelError.inferenceError(original: e),
                ),
              ),
            );
      } else {
        _responseSubscription = _gemmaService
            .generateResponse(promptToSend, imageBytes: event.imageBytes)
            .listen(
              (chunk) => add(ChatStreamChunk(chunk)),
              onDone: () => add(const ChatStreamComplete()),
              onError: (e) => add(
                ChatStreamError(
                  e is AppError ? e : ModelError.inferenceError(original: e),
                ),
              ),
            );
      }
    } on AppError catch (e) {
      AppLogger.logAppError(e, 'ChatBloc');
      emit(state.copyWith(isGenerating: false, error: e));
    } catch (e, stack) {
      AppLogger.error(
        'Erreur envoi message',
        tag: 'ChatBloc',
        error: e,
        stackTrace: stack,
      );
      emit(
        state.copyWith(
          isGenerating: false,
          error: ModelError.inferenceError(original: e, stack: stack),
        ),
      );
    }
  }

  void _onStreamChunk(ChatStreamChunk event, Emitter<ChatState> emit) {
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

      emit(state.copyWith(messages: messages, isGenerating: false));

      // Save assistant message to database if we have a conversation
      if (state.currentConversationId != null &&
          completedMessage.content.isNotEmpty) {
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

  void _onThinkingChunk(ChatThinkingChunk event, Emitter<ChatState> emit) {
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
    AppLogger.info('Telechargement de l\'embedder', 'ChatBloc');

    try {
      emit(
        state.copyWith(
          embedderState: EmbedderState.downloading,
          embedderDownloadProgress: 0.0,
          clearRagError: true,
        ),
      );

      await _ragService.downloadEmbedder(
        onProgress: (progress) {
          emit(state.copyWith(embedderDownloadProgress: progress));
        },
      );

      emit(state.copyWith(embedderState: EmbedderState.installed));
    } on AppError catch (e) {
      AppLogger.logAppError(e, 'ChatBloc');
      emit(state.copyWith(embedderState: EmbedderState.error, ragError: e));
    } catch (e, stack) {
      AppLogger.error(
        'Erreur telechargement embedder',
        tag: 'ChatBloc',
        error: e,
        stackTrace: stack,
      );
      emit(
        state.copyWith(
          embedderState: EmbedderState.error,
          ragError: NetworkError.downloadFailed(
            modelName: 'embedder',
            original: e,
            stack: stack,
          ),
        ),
      );
    }
  }

  Future<void> _onLoadEmbedder(
    ChatLoadEmbedder event,
    Emitter<ChatState> emit,
  ) async {
    AppLogger.info('Chargement de l\'embedder', 'ChatBloc');

    try {
      emit(
        state.copyWith(
          embedderState: EmbedderState.loading,
          clearRagError: true,
        ),
      );
      await _ragService.loadEmbedder();
      emit(state.copyWith(embedderState: EmbedderState.ready));

      // Charger automatiquement les checklists après que l'embedder soit prêt
      _loadChecklistsInBackground();
    } on AppError catch (e) {
      AppLogger.logAppError(e, 'ChatBloc');
      emit(state.copyWith(embedderState: EmbedderState.error, ragError: e));
    } catch (e, stack) {
      AppLogger.error(
        'Erreur chargement embedder',
        tag: 'ChatBloc',
        error: e,
        stackTrace: stack,
      );
      emit(
        state.copyWith(
          embedderState: EmbedderState.error,
          ragError: RagError.embedderNotLoaded(stack: stack),
        ),
      );
    }
  }

  Future<void> _loadChecklistsInBackground() async {
    // Vérifier si déjà chargées avant de lancer
    final alreadyLoaded = await _ragService.areChecklistsLoaded();
    if (alreadyLoaded) {
      AppLogger.debug('Checklists deja chargees, skip', 'ChatBloc');
      // ignore: invalid_use_of_visible_for_testing_member
      emit(state.copyWith(checklistsLoaded: true));
      return;
    }

    // Indiquer que le chargement commence
    // ignore: invalid_use_of_visible_for_testing_member
    emit(state.copyWith(checklistsLoading: true));

    // Chargement en arrière-plan sans bloquer l'UI
    _ragService.loadAssetJsonsToVectorStore(
      onProgress: (current, total, fileName) {
        AppLogger.debug(
          'Chargement checklist $current/$total: $fileName',
          'ChatBloc',
        );
      },
    ).then((_) {
      AppLogger.info('Checklists chargees avec succes', 'ChatBloc');
      // Notifier l'UI que les checklists sont chargées
      // ignore: invalid_use_of_visible_for_testing_member
      emit(state.copyWith(
        checklistsJustLoaded: true,
        checklistsLoading: false,
        checklistsLoaded: true,
      ));
    }).catchError((e, stack) {
      AppLogger.error(
        'Erreur chargement checklists',
        tag: 'ChatBloc',
        error: e,
        stackTrace: stack,
      );
      // ignore: invalid_use_of_visible_for_testing_member
      emit(state.copyWith(checklistsLoading: false));
    });
  }

  void _onResetChecklistsFlag(
    ChatResetChecklistsFlag event,
    Emitter<ChatState> emit,
  ) {
    emit(state.copyWith(checklistsJustLoaded: false));
  }

  Future<void> _onLoadChecklists(
    ChatLoadChecklists event,
    Emitter<ChatState> emit,
  ) async {
    if (!_ragService.isReady) {
      AppLogger.warning('Embedder non pret, impossible de charger les checklists', 'ChatBloc');
      return;
    }

    _loadChecklistsInBackground();
  }

  Future<void> _onLoadDocuments(
    ChatLoadDocuments event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final docs = await _database.select(_database.documents).get();
      final documentInfos = docs
          .map(
            (d) => DocumentInfo(
              id: d.id,
              name: d.name,
              filePath: d.filePath,
              totalChunks: d.totalChunks,
              createdAt: d.createdAt,
              lastUsedAt: d.lastUsedAt,
              isActive: d.isActive,
            ),
          )
          .toList();
      emit(state.copyWith(documents: documentInfos));
    } catch (e, stack) {
      AppLogger.error(
        'Erreur chargement documents',
        tag: 'ChatBloc',
        error: e,
        stackTrace: stack,
      );
      emit(
        state.copyWith(
          ragError: StorageError.databaseError(original: e, stack: stack),
        ),
      );
    }
  }

  Future<void> _onDocumentSelected(
    ChatDocumentSelected event,
    Emitter<ChatState> emit,
  ) async {
    AppLogger.info('Traitement du document: ${event.fileName}', 'ChatBloc');

    try {
      emit(
        state.copyWith(
          isProcessingDocument: true,
          documentProcessingCurrent: 0,
          documentProcessingTotal: 0,
          clearRagError: true,
        ),
      );

      // Extract text from PDF
      final text = await _ragService.extractTextFromPdf(event.filePath);

      // Insert document into database
      final docId = await _database
          .into(_database.documents)
          .insert(
            DocumentsCompanion.insert(
              name: event.fileName,
              filePath: event.filePath,
              isActive: const Value(true),
            ),
          );

      // Chunk the text
      final chunks = _ragService.chunkText(text: text, documentId: docId);

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

      AppLogger.info('Document traite: ${chunks.length} chunks', 'ChatBloc');
      emit(state.copyWith(isProcessingDocument: false));
    } on AppError catch (e) {
      AppLogger.logAppError(e, 'ChatBloc');
      emit(state.copyWith(isProcessingDocument: false, ragError: e));
    } catch (e, stack) {
      AppLogger.error(
        'Erreur traitement document',
        tag: 'ChatBloc',
        error: e,
        stackTrace: stack,
      );
      emit(
        state.copyWith(
          isProcessingDocument: false,
          ragError: RagError.pdfExtractionFailed(
            fileName: event.fileName,
            original: e,
            stack: stack,
          ),
        ),
      );
    }
  }

  void _onDocumentProcessingProgress(
    ChatDocumentProcessingProgress event,
    Emitter<ChatState> emit,
  ) {
    emit(
      state.copyWith(
        documentProcessingCurrent: event.current,
        documentProcessingTotal: event.total,
      ),
    );
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
    } catch (e, stack) {
      AppLogger.error(
        'Erreur toggle document',
        tag: 'ChatBloc',
        error: e,
        stackTrace: stack,
      );
      emit(
        state.copyWith(
          ragError: StorageError.databaseError(original: e, stack: stack),
        ),
      );
    }
  }

  Future<void> _onRemoveDocument(
    ChatRemoveDocument event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await (_database.delete(
        _database.documents,
      )..where((d) => d.id.equals(event.documentId))).go();

      add(const ChatLoadDocuments());
    } catch (e, stack) {
      AppLogger.error(
        'Erreur suppression document',
        tag: 'ChatBloc',
        error: e,
        stackTrace: stack,
      );
      emit(
        state.copyWith(
          ragError: StorageError.databaseError(original: e, stack: stack),
        ),
      );
    }
  }

  // ============== CONVERSATION HANDLERS ==============

  Future<void> _onLoadConversations(
    ChatLoadConversations event,
    Emitter<ChatState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoadingConversations: true));

      final convos = await (_database.select(
        _database.conversations,
      )..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])).get();

      final conversationInfos = <ConversationInfo>[];

      for (final conv in convos) {
        final messagesQuery = _database.select(_database.messages)
          ..where((m) => m.conversationId.equals(conv.id))
          ..orderBy([(m) => OrderingTerm.desc(m.createdAt)])
          ..limit(1);

        final lastMessageResult = await messagesQuery.get();
        final messageCount =
            await (_database.select(_database.messages)
                  ..where((m) => m.conversationId.equals(conv.id)))
                .get()
                .then((msgs) => msgs.length);

        conversationInfos.add(
          ConversationInfo(
            id: conv.id,
            title: conv.title,
            createdAt: conv.createdAt,
            updatedAt: conv.updatedAt,
            messageCount: messageCount,
            lastMessage: lastMessageResult.isNotEmpty
                ? lastMessageResult.first.content
                : null,
          ),
        );
      }

      emit(
        state.copyWith(
          conversations: conversationInfos,
          isLoadingConversations: false,
        ),
      );
    } catch (e, stack) {
      AppLogger.error(
        'Erreur chargement conversations',
        tag: 'ChatBloc',
        error: e,
        stackTrace: stack,
      );
      emit(
        state.copyWith(
          isLoadingConversations: false,
          error: StorageError.databaseError(original: e, stack: stack),
        ),
      );
    }
  }

  Future<void> _onCreateConversation(
    ChatCreateConversation event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final title = event.title ?? 'Nouvelle conversation';
      final now = DateTime.now();

      final id = await _database
          .into(_database.conversations)
          .insert(
            ConversationsCompanion.insert(
              title: title,
              createdAt: Value(now),
              updatedAt: Value(now),
            ),
          );

      await _gemmaService.clearChat();
      emit(
        state.copyWith(
          currentConversationId: id,
          messages: [],
          clearError: true,
        ),
      );

      add(const ChatLoadConversations());
    } catch (e, stack) {
      AppLogger.error(
        'Erreur creation conversation',
        tag: 'ChatBloc',
        error: e,
        stackTrace: stack,
      );
      emit(
        state.copyWith(
          error: StorageError.databaseError(original: e, stack: stack),
        ),
      );
    }
  }

  Future<void> _onLoadConversation(
    ChatLoadConversation event,
    Emitter<ChatState> emit,
  ) async {
    try {
      emit(state.copyWith(isLoadingConversations: true));

      final dbMessages =
          await (_database.select(_database.messages)
                ..where((m) => m.conversationId.equals(event.conversationId))
                ..orderBy([(m) => OrderingTerm.asc(m.createdAt)]))
              .get();

      final messages = dbMessages
          .map(
            (m) => ChatMessage(
              id: m.id.toString(),
              role: m.role == 'user' ? MessageRole.user : MessageRole.assistant,
              content: m.content,
              timestamp: m.createdAt,
            ),
          )
          .toList();

      await _gemmaService.clearChat();

      emit(
        state.copyWith(
          currentConversationId: event.conversationId,
          messages: messages,
          isLoadingConversations: false,
        ),
      );
    } catch (e, stack) {
      AppLogger.error(
        'Erreur chargement conversation',
        tag: 'ChatBloc',
        error: e,
        stackTrace: stack,
      );
      emit(
        state.copyWith(
          isLoadingConversations: false,
          error: StorageError.databaseError(original: e, stack: stack),
        ),
      );
    }
  }

  Future<void> _onDeleteConversation(
    ChatDeleteConversation event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await (_database.delete(
        _database.conversations,
      )..where((c) => c.id.equals(event.conversationId))).go();

      if (state.currentConversationId == event.conversationId) {
        await _gemmaService.clearChat();
        emit(state.copyWith(clearCurrentConversation: true, messages: []));
      }

      add(const ChatLoadConversations());
    } catch (e, stack) {
      AppLogger.error(
        'Erreur suppression conversation',
        tag: 'ChatBloc',
        error: e,
        stackTrace: stack,
      );
      emit(
        state.copyWith(
          error: StorageError.databaseError(original: e, stack: stack),
        ),
      );
    }
  }

  Future<void> _onRenameConversation(
    ChatRenameConversation event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await (_database.update(
        _database.conversations,
      )..where((c) => c.id.equals(event.conversationId))).write(
        ConversationsCompanion(
          title: Value(event.newTitle),
          updatedAt: Value(DateTime.now()),
        ),
      );

      add(const ChatLoadConversations());
    } catch (e, stack) {
      AppLogger.error(
        'Erreur renommage conversation',
        tag: 'ChatBloc',
        error: e,
        stackTrace: stack,
      );
      emit(
        state.copyWith(
          error: StorageError.databaseError(original: e, stack: stack),
        ),
      );
    }
  }

  Future<void> _saveMessageToDb(ChatMessage message, int conversationId) async {
    await _database
        .into(_database.messages)
        .insert(
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
    add(
      ChatSendMessage(userMessage.content, imageBytes: userMessage.imageBytes),
    );
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

      emit(
        state.copyWith(
          messages: messages,
          isGenerating: false,
          isThinking: false,
        ),
      );

      // Save partial message to database if conversation exists
      if (state.currentConversationId != null &&
          stoppedMessage.content.isNotEmpty) {
        await _saveMessageToDb(stoppedMessage, state.currentConversationId!);
      }
    } else {
      emit(state.copyWith(isGenerating: false, isThinking: false));
    }
  }

  void _onStreamError(ChatStreamError event, Emitter<ChatState> emit) {
    AppLogger.logAppError(event.error, 'ChatBloc');
    emit(
      state.copyWith(
        isGenerating: false,
        isThinking: false,
        error: event.error,
      ),
    );
  }

  // ============== CHECKLIST SESSION HANDLERS ==============

  bool _isReportTrigger(String message) {
    final triggers = [
      'genere le rapport',
      'génère le rapport',
      'export json',
      'rapport json',
      'generate report',
      'json report',
    ];
    return triggers.any((t) => message.contains(t));
  }

  bool _isRemainingTrigger(String message) {
    final triggers = [
      'reste',
      'manque',
      'oublie',
      'remaining',
      'what\'s left',
      'il me reste',
      'qu\'est-ce qu\'il',
    ];
    return triggers.any((t) => message.contains(t));
  }

  bool _isEndSessionTrigger(String message) {
    final triggers = [
      'terminer',
      'fin de session',
      'arreter',
      'stop checklist',
      'end session',
      'quitter inspection',
    ];
    return triggers.any((t) => message.contains(t));
  }

  Future<void> _handleChecklistStartSession(
    dynamic section,
    Emitter<ChatState> emit,
  ) async {
    final session = _checklistService.startSession(section);

    // Met a jour le prompt systeme de Gemma
    final prompt = _checklistService.buildSystemPrompt();
    _gemmaService.setSystemPrompt(prompt);

    final firstQuestion = section.questions.first;
    final startMessage = '''Parfait, nous allons inspecter la section "${section.title}".

Cette section comporte ${section.questions.length} elements a verifier dont ${section.mandatoryQuestions} obligatoires.

Commencons: ${firstQuestion.questionPrompt}''';

    // Ajouter les messages dans le chat
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.user,
      content: 'Je suis dans ${section.title}',
      timestamp: DateTime.now(),
    );

    final assistantMessage = ChatMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}_assistant',
      role: MessageRole.assistant,
      content: startMessage,
      timestamp: DateTime.now(),
    );

    emit(state.copyWith(
      messages: [...state.messages, userMessage, assistantMessage],
      checklistSession: session,
      checklistResponse: startMessage,
    ));

    AppLogger.info('Session checklist demarree: ${section.title}', 'ChatBloc');
  }

  Future<void> _handleChecklistAnswer(
    String userInput,
    Emitter<ChatState> emit,
  ) async {
    // Ajouter le message utilisateur
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.user,
      content: userInput,
      timestamp: DateTime.now(),
    );

    // Ajouter un message "en cours de traitement"
    final processingMessage = ChatMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}_assistant',
      role: MessageRole.assistant,
      content: 'Analyse de votre reponse...',
      timestamp: DateTime.now(),
      isStreaming: true,
    );

    emit(state.copyWith(
      messages: [...state.messages, userMessage, processingMessage],
      isGenerating: true,
    ));

    String responseMessage;
    final confirmations = <String>[];

    try {
      // Detecter si plusieurs questions sont mentionnees
      final mentionedQuestions = _checklistService.detectMentionedQuestions(userInput);

      if (mentionedQuestions.isNotEmpty) {
        // Classifier chaque question mentionnee avec Gemma
        for (final question in mentionedQuestions) {
          final classified = await _classifyAnswerWithGemma(userInput, question);
          if (classified != null) {
            _checklistService.recordResponse(classified);
            confirmations.add('${question.title} = ${classified.displayValue}');
          }
        }
      } else if (state.checklistSession?.currentQuestion != null) {
        // Classifier la reponse pour la question courante
        final question = state.checklistSession!.currentQuestion!;
        final classified = await _classifyAnswerWithGemma(userInput, question);

        if (classified != null) {
          _checklistService.recordResponse(classified);
          confirmations.add('${question.title} = ${classified.displayValue}');
        }
      }

      final session = _checklistService.currentSession!;
      final nextMessage = _buildNextQuestionMessage(session);

      if (confirmations.isNotEmpty) {
        responseMessage = 'J\'ai bien note: ${confirmations.join(", ")}.\n\n$nextMessage';
      } else {
        responseMessage = 'Je n\'ai pas pu interpreter votre reponse. ${state.checklistSession?.currentQuestion?.questionPrompt ?? nextMessage}';
      }
    } catch (e, stack) {
      AppLogger.error('Erreur classification reponse', tag: 'ChatBloc', error: e, stackTrace: stack);
      responseMessage = 'Erreur lors de l\'analyse. Pouvez-vous reformuler votre reponse?';
    }

    // Mettre a jour le prompt systeme
    final prompt = _checklistService.buildSystemPrompt();
    _gemmaService.setSystemPrompt(prompt);

    // Remplacer le message "en cours" par la reponse finale
    final messages = List<ChatMessage>.from(state.messages);
    messages[messages.length - 1] = ChatMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}_assistant',
      role: MessageRole.assistant,
      content: responseMessage,
      timestamp: DateTime.now(),
    );

    emit(state.copyWith(
      messages: messages,
      isGenerating: false,
      checklistSession: _checklistService.currentSession,
      checklistResponse: responseMessage,
    ));
  }

  /// Utilise Gemma pour classifier la reponse de l'utilisateur
  Future<ChecklistResponse?> _classifyAnswerWithGemma(
    String userInput,
    ChecklistQuestion question,
  ) async {
    try {
      if (question.type == QuestionType.text) {
        // Pour les questions texte, pas besoin de classification
        return _checklistService.createTextResponse(userInput, question);
      }

      if (question.type == QuestionType.checkbox) {
        // Pour les checkbox, classifier oui/non
        final classificationPrompt = _checklistService.buildCheckboxClassificationPrompt(
          userInput,
          question,
        );

        final gemmaResponse = await _getGemmaResponse(classificationPrompt);
        final checkboxValue = _checklistService.parseGemmaCheckbox(gemmaResponse);

        if (checkboxValue != null) {
          return _checklistService.createCheckboxResponse(userInput, question, checkboxValue);
        }
        return null;
      }

      // Pour les questions a choix multiples
      final classificationPrompt = _checklistService.buildClassificationPrompt(
        userInput,
        question,
      );

      AppLogger.debug('Classification prompt: $classificationPrompt', 'ChatBloc');

      final gemmaResponse = await _getGemmaResponse(classificationPrompt);
      AppLogger.debug('Gemma classification response: $gemmaResponse', 'ChatBloc');

      final choice = _checklistService.parseGemmaChoice(gemmaResponse, question);

      if (choice != null) {
        return _checklistService.createResponseFromChoice(userInput, question, choice);
      }

      return null;
    } catch (e, stack) {
      AppLogger.error('Erreur classification Gemma', tag: 'ChatBloc', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Obtient une reponse de Gemma de maniere synchrone (en collectant le stream)
  Future<String> _getGemmaResponse(String prompt) async {
    final buffer = StringBuffer();

    await for (final chunk in _gemmaService.generateResponse(prompt)) {
      buffer.write(chunk);
    }

    return buffer.toString();
  }

  String _buildNextQuestionMessage(ChecklistSession session) {
    if (session.currentQuestion != null) {
      return session.currentQuestion!.shortPrompt;
    }

    final unanswered = session.unansweredMandatoryQuestions;
    if (unanswered.isNotEmpty) {
      return 'Excellent! Il reste ${unanswered.length} question(s) obligatoire(s) sans reponse: ${unanswered.map((q) => q.title).join(", ")}.\n\nSouhaitez-vous y revenir?';
    }

    return 'L\'inspection de cette section est complete!\n\nDites "genere le rapport" pour obtenir le JSON, ou "qu\'est-ce qu\'il me reste?" pour voir les questions optionnelles.';
  }

  Future<void> _onInitializeChecklistService(
    ChatInitializeChecklistService event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await _checklistService.loadChecklistFromAsset();
      AppLogger.info(
        'ChecklistService initialise avec ${_checklistService.sections.length} sections',
        'ChatBloc',
      );
    } catch (e, stack) {
      AppLogger.error(
        'Erreur initialisation ChecklistService',
        tag: 'ChatBloc',
        error: e,
        stackTrace: stack,
      );
    }
  }

  Future<void> _onChecklistShowRemaining(
    ChatChecklistShowRemaining event,
    Emitter<ChatState> emit,
  ) async {
    if (!state.hasActiveChecklistSession) {
      final assistantMessage = ChatMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}_assistant',
        role: MessageRole.assistant,
        content: 'Aucune session active. Dites dans quelle section vous etes.',
        timestamp: DateTime.now(),
      );

      emit(state.copyWith(
        messages: [...state.messages, assistantMessage],
      ));
      return;
    }

    final message = _checklistService.formatRemainingQuestionsForLLM();
    final session = _checklistService.currentSession!;
    final nextQuestion = session.currentQuestion;
    final fullMessage = nextQuestion != null
        ? '$message\n\nVoulez-vous continuer avec "${nextQuestion.title}"?'
        : message;

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.user,
      content: 'Qu\'est-ce qu\'il me reste?',
      timestamp: DateTime.now(),
    );

    final assistantMessage = ChatMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}_assistant',
      role: MessageRole.assistant,
      content: fullMessage,
      timestamp: DateTime.now(),
    );

    emit(state.copyWith(
      messages: [...state.messages, userMessage, assistantMessage],
      checklistResponse: fullMessage,
    ));
  }

  Future<void> _onChecklistGenerateReport(
    ChatChecklistGenerateReport event,
    Emitter<ChatState> emit,
  ) async {
    if (!state.hasActiveChecklistSession) {
      final assistantMessage = ChatMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}_assistant',
        role: MessageRole.assistant,
        content: 'Aucune session active pour generer un rapport.',
        timestamp: DateTime.now(),
      );

      emit(state.copyWith(
        messages: [...state.messages, assistantMessage],
      ));
      return;
    }

    final report = _checklistService.generateReport();
    final jsonReport = const JsonEncoder.withIndent('  ').convert(report);
    final fullMessage =
        'Voici le rapport JSON de l\'inspection:\n\n```json\n$jsonReport\n```';

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.user,
      content: 'Genere le rapport',
      timestamp: DateTime.now(),
    );

    final assistantMessage = ChatMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}_assistant',
      role: MessageRole.assistant,
      content: fullMessage,
      timestamp: DateTime.now(),
    );

    emit(state.copyWith(
      messages: [...state.messages, userMessage, assistantMessage],
      checklistResponse: fullMessage,
    ));

    AppLogger.info('Rapport checklist genere', 'ChatBloc');
  }

  Future<void> _onChecklistEndSession(
    ChatChecklistEndSession event,
    Emitter<ChatState> emit,
  ) async {
    _checklistService.endSession();
    _gemmaService.setSystemPrompt(null);

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.user,
      content: 'Terminer la session',
      timestamp: DateTime.now(),
    );

    final assistantMessage = ChatMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}_assistant',
      role: MessageRole.assistant,
      content: 'Session d\'inspection terminee. Merci!',
      timestamp: DateTime.now(),
    );

    emit(state.copyWith(
      messages: [...state.messages, userMessage, assistantMessage],
      clearChecklistSession: true,
      clearChecklistResponse: true,
    ));

    AppLogger.info('Session checklist terminee', 'ChatBloc');
  }

  @override
  Future<void> close() {
    _responseSubscription?.cancel();
    _thinkingResponseSubscription?.cancel();
    return super.close();
  }
}
