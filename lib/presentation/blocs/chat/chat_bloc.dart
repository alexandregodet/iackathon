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
import '../../../data/datasources/stt_service.dart';
import '../../../data/datasources/tts_service.dart';
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
  final SttService _sttService;
  final TtsService _ttsService;
  StreamSubscription<String>? _responseSubscription;
  StreamSubscription<GemmaStreamResponse>? _thinkingResponseSubscription;
  StreamSubscription<String>? _partialTranscriptionSubscription;
  StreamSubscription<String>? _finalTranscriptionSubscription;
  StreamSubscription<bool>? _sttStateSubscription;
  StreamSubscription<String>? _sttErrorSubscription;

  // Voice mode state
  String _accumulatedTextForTts = '';
  bool _hasStartedTts = false;
  StreamSubscription<void>? _ttsCompletionSubscription;

  ChatBloc(
    this._gemmaService,
    this._ragService,
    this._database,
    this._settingsService,
    this._checklistService,
    this._sttService,
    this._ttsService,
  ) : super(const ChatState()) {
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
    // Voice mode events
    on<ChatToggleVoiceMode>(_onToggleVoiceMode);
    on<ChatStartListening>(_onStartListening);
    on<ChatStopListening>(_onStopListening);
    on<ChatPartialTranscription>(_onPartialTranscription);
    on<ChatFinalTranscription>(_onFinalTranscription);
    on<ChatVoiceError>(_onVoiceError);
    on<ChatUpdateListeningState>(_onUpdateListeningState);
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

    // Si session checklist active, detecter l'intention avec Gemma
    if (state.hasActiveChecklistSession) {
      final intent = await _detectUserIntent(event.message);
      AppLogger.debug('Intent detecte: $intent', 'ChatBloc');

      switch (intent) {
        case 'RAPPORT':
          add(ChatChecklistGenerateReport(event.message));
          return;
        case 'RESTE':
          add(ChatChecklistShowRemaining(event.message));
          return;
        case 'TERMINER':
          add(ChatChecklistEndSession(event.message));
          return;
        case 'CHOIX':
          await _handleShowAllChoices(event.message, emit);
          return;
        default:
          // REPONSE - traiter comme reponse a la checklist
          await _handleChecklistAnswer(event.message, emit);
          return;
      }
    }

    // Detecter section si pas de session active
    if (_checklistService.isLoaded) {
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
      final newContent = lastMessage.content + event.chunk;
      messages[messages.length - 1] = lastMessage.copyWith(
        content: newContent,
      );
      emit(state.copyWith(messages: messages));

      // In voice mode, start TTS as soon as we have complete sentences
      if (state.isVoiceMode) {
        AppLogger.debug('Voice mode active, accumulating for TTS: ${event.chunk.length} chars', 'ChatBloc');
        _accumulatedTextForTts += event.chunk;
        _processTtsStreaming(lastMessage.id);
      } else {
        AppLogger.debug('Voice mode NOT active, skipping TTS', 'ChatBloc');
      }
    }
  }

  void _processTtsStreaming(String messageId) {
    // Check if we have a complete sentence (ends with . ! ? or has enough words)
    final sentences = _extractCompleteSentences(_accumulatedTextForTts);

    if (sentences.isNotEmpty) {
      // Stop listening when we start speaking (first sentence)
      if (!_hasStartedTts && state.isListening) {
        AppLogger.info('Stopping STT before starting TTS', 'ChatBloc');
        _sttService.stopListening();
        _hasStartedTts = true;
      }

      // Send each complete sentence to TTS
      for (final sentence in sentences) {
        _ttsService.speakStreaming(
          sentence,
          messageId,
          onComplete: () {
            // Restart listening when all TTS completes
            AppLogger.info('All TTS complete, restarting listening', 'ChatBloc');
            if (state.isVoiceMode && !_sttService.isListening && !isClosed) {
              _sttService.startListening();
            }
          },
        );
      }
    }
  }

  List<String> _extractCompleteSentences(String text) {
    final sentences = <String>[];
    final sentenceEndings = RegExp(r'[.!?]\s*');
    final matches = sentenceEndings.allMatches(text);

    if (matches.isEmpty) {
      // No complete sentences, but check if we have enough words (>15 words)
      final wordCount = text.trim().split(RegExp(r'\s+')).length;
      if (wordCount > 15) {
        sentences.add(text);
        _accumulatedTextForTts = '';
      }
      return sentences;
    }

    // Extract all complete sentences
    int lastEnd = 0;
    for (final match in matches) {
      final sentence = text.substring(lastEnd, match.end).trim();
      if (sentence.isNotEmpty) {
        sentences.add(sentence);
      }
      lastEnd = match.end;
    }

    // Keep the remaining partial sentence
    _accumulatedTextForTts = text.substring(lastEnd);
    return sentences;
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

      // In voice mode with streaming TTS
      if (state.isVoiceMode && completedMessage.content.isNotEmpty) {
        // Send any remaining accumulated text to TTS
        if (_accumulatedTextForTts.trim().isNotEmpty) {
          AppLogger.info('Speaking remaining text: ${_accumulatedTextForTts}', 'ChatBloc');
          _ttsService.speakStreaming(
            _accumulatedTextForTts,
            completedMessage.id,
            onComplete: () {
              // Restart listening when all TTS completes
              AppLogger.info('All TTS complete, restarting listening', 'ChatBloc');
              if (state.isVoiceMode && !_sttService.isListening && !isClosed) {
                _sttService.startListening();
              }
            },
          );
        }

        // Reset TTS streaming state
        _accumulatedTextForTts = '';
        _hasStartedTts = false;

        // If no TTS was started (empty response), restart listening
        if (!_ttsService.isPlaying && !_sttService.isListening) {
          AppLogger.info('No TTS played, restarting listening immediately', 'ChatBloc');
          await _sttService.startListening();
        }
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

  /// Detecte l'intention de l'utilisateur via Gemma
  Future<String> _detectUserIntent(String userInput) async {
    final prompt = _checklistService.buildIntentDetectionPrompt(userInput);
    final response = await _getGemmaResponse(prompt);
    return _checklistService.parseIntentDetection(response);
  }

  /// Affiche tous les choix possibles pour la question courante
  Future<void> _handleShowAllChoices(
    String userInput,
    Emitter<ChatState> emit,
  ) async {
    final question = state.checklistSession?.currentQuestion;
    if (question == null) {
      final assistantMessage = ChatMessage(
        id: '${DateTime.now().millisecondsSinceEpoch}_assistant',
        role: MessageRole.assistant,
        content: 'Aucune question en cours.',
        timestamp: DateTime.now(),
      );
      emit(state.copyWith(messages: [...state.messages, assistantMessage]));
      return;
    }

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: MessageRole.user,
      content: userInput,
      timestamp: DateTime.now(),
    );

    final responseMessage = _checklistService.formatChoicesForUser(question);

    final assistantMessage = ChatMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}_assistant',
      role: MessageRole.assistant,
      content: responseMessage,
      timestamp: DateTime.now(),
    );

    emit(state.copyWith(
      messages: [...state.messages, userMessage, assistantMessage],
      pendingQuestionForSelection: question,
    ));
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

    // TTS pour la réponse checklist
    _speakIfVoiceMode(startMessage, assistantMessage.id);

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

    emit(state.copyWith(
      messages: [...state.messages, userMessage],
    ));

    // Si on attend une selection manuelle de l'utilisateur
    if (state.isWaitingForSelection && state.pendingQuestionForSelection != null) {
      await _handleDirectSelection(userInput, emit);
      return;
    }

    // Ajouter un message "en cours de traitement"
    final processingMessage = ChatMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}_assistant',
      role: MessageRole.assistant,
      content: 'Analyse de votre reponse...',
      timestamp: DateTime.now(),
      isStreaming: true,
    );

    emit(state.copyWith(
      messages: [...state.messages, processingMessage],
      isGenerating: true,
    ));

    String responseMessage;
    final confirmations = <String>[];
    ChecklistQuestion? pendingQuestion;

    try {
      // Detecter si plusieurs questions sont mentionnees
      final mentionedQuestions = _checklistService.detectMentionedQuestions(userInput);

      if (mentionedQuestions.isNotEmpty) {
        // Classifier chaque question mentionnee avec Gemma
        for (final question in mentionedQuestions) {
          final result = await _classifyWithConfidence(userInput, question);
          if (result != null) {
            // Classification reussie - enregistrer
            _checklistService.recordResponse(result.response);
            final confirmation = result.comment != null
                ? '${question.title} = ${result.response.displayValue} (${result.comment})'
                : '${question.title} = ${result.response.displayValue}';
            confirmations.add(confirmation);
          } else {
            // Pas de classification - proposer tous les choix
            pendingQuestion = question;
            break;
          }
        }
      } else if (state.checklistSession?.currentQuestion != null) {
        // Classifier la reponse pour la question courante
        final question = state.checklistSession!.currentQuestion!;
        final result = await _classifyWithConfidence(userInput, question);

        if (result != null) {
          // Classification reussie - enregistrer
          _checklistService.recordResponse(result.response);
          final confirmation = result.comment != null
              ? '${question.title} = ${result.response.displayValue} (${result.comment})'
              : '${question.title} = ${result.response.displayValue}';
          confirmations.add(confirmation);
        } else {
          // Pas de classification - proposer tous les choix
          pendingQuestion = question;
        }
      }

      // Construire le message de reponse
      if (pendingQuestion != null) {
        // Gemma n'a pas trouve de choix - proposer tous les choix
        responseMessage = _checklistService.formatChoicesForUser(pendingQuestion);
      } else {
        final session = _checklistService.currentSession!;
        final nextMessage = _buildNextQuestionMessage(session);

        if (confirmations.isNotEmpty) {
          responseMessage = 'J\'ai bien note: ${confirmations.join(", ")}.\n\n$nextMessage';
        } else {
          responseMessage = 'Je n\'ai pas pu interpreter votre reponse. ${state.checklistSession?.currentQuestion?.questionPrompt ?? nextMessage}';
        }
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
      pendingQuestionForSelection: pendingQuestion,
    ));

    // TTS pour la réponse checklist
    _speakIfVoiceMode(responseMessage, messages.last.id);
  }

  /// Gere la selection de l'utilisateur quand on lui propose des choix
  /// L'utilisateur peut: repondre librement (Gemma re-analyse) ou donner un numero
  Future<void> _handleDirectSelection(
    String userInput,
    Emitter<ChatState> emit,
  ) async {
    final question = state.pendingQuestionForSelection!;

    String responseMessage;
    bool clearPending = false;

    // 1. Essayer de parser une selection directe (numero ou nom exact)
    final directChoice = _checklistService.parseDirectChoice(userInput, question);

    if (directChoice != null) {
      // Choix direct valide - enregistrer
      final response = _checklistService.createResponseFromChoice(
        userInput,
        question,
        directChoice,
      );

      if (response != null) {
        _checklistService.recordResponse(response);

        final session = _checklistService.currentSession!;
        final nextMessage = _buildNextQuestionMessage(session);
        responseMessage = 'J\'ai bien note: ${question.title} = $directChoice.\n\n$nextMessage';
        clearPending = true;
      } else {
        responseMessage = 'Erreur lors de l\'enregistrement.';
      }
    } else {
      // 3. Pas de selection directe - re-analyser avec Gemma
      final result = await _classifyWithConfidence(userInput, question);

      if (result != null) {
        // Classification reussie
        final response = _checklistService.createResponseFromChoice(
          userInput,
          question,
          result.response.selectedChoices.first,
          comment: result.comment,
        );

        if (response != null) {
          _checklistService.recordResponse(response);

          final session = _checklistService.currentSession!;
          final nextMessage = _buildNextQuestionMessage(session);
          final confirmationText = result.comment != null
              ? '${question.title} = ${result.response.selectedChoices.first} (${result.comment})'
              : '${question.title} = ${result.response.selectedChoices.first}';
          responseMessage = 'J\'ai bien note: $confirmationText.\n\n$nextMessage';
          clearPending = true;
        } else {
          responseMessage = 'Erreur lors de l\'enregistrement.';
        }
      } else {
        // Gemma n'a pas pu classifier - remontrer les choix
        responseMessage = 'Je n\'ai pas compris votre reponse. ${_checklistService.formatChoicesForUser(question)}';

        final assistantMessage = ChatMessage(
          id: '${DateTime.now().millisecondsSinceEpoch}_assistant',
          role: MessageRole.assistant,
          content: responseMessage,
          timestamp: DateTime.now(),
        );

        emit(state.copyWith(
          messages: [...state.messages, assistantMessage],
          checklistResponse: responseMessage,
        ));
        return;
      }
    }

    // Mettre a jour le prompt systeme
    final prompt = _checklistService.buildSystemPrompt();
    _gemmaService.setSystemPrompt(prompt);

    final assistantMessage = ChatMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}_assistant',
      role: MessageRole.assistant,
      content: responseMessage,
      timestamp: DateTime.now(),
    );

    emit(state.copyWith(
      messages: [...state.messages, assistantMessage],
      checklistSession: _checklistService.currentSession,
      checklistResponse: responseMessage,
      clearPendingQuestion: clearPending,
    ));

    // TTS pour la réponse checklist
    _speakIfVoiceMode(responseMessage, assistantMessage.id);
  }

  /// Resultat de classification avec confiance
  Future<_ClassificationWithConfidence?> _classifyWithConfidence(
    String userInput,
    ChecklistQuestion question,
  ) async {
    try {
      if (question.type == QuestionType.text) {
        final response = _checklistService.createTextResponse(userInput, question);
        return response != null
            ? _ClassificationWithConfidence(response: response, isConfident: true)
            : null;
      }

      if (question.type == QuestionType.checkbox) {
        final classificationPrompt = _checklistService.buildCheckboxClassificationPrompt(
          userInput,
          question,
        );

        final gemmaResponse = await _getGemmaResponse(classificationPrompt);
        final result = _checklistService.parseGemmaCheckboxClassification(gemmaResponse);

        if (result != null) {
          final response = _checklistService.createCheckboxResponse(
            userInput,
            question,
            result.value,
          );
          return response != null
              ? _ClassificationWithConfidence(
                  response: response,
                  isConfident: result.isConfident,
                )
              : null;
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

      final result = _checklistService.parseGemmaClassification(gemmaResponse, question);

      if (result != null) {
        final response = _checklistService.createResponseFromChoice(
          userInput,
          question,
          result.choice,
          comment: result.comment,
        );
        return response != null
            ? _ClassificationWithConfidence(
                response: response,
                isConfident: result.isConfident,
                probableChoices: result.probableChoices,
                comment: result.comment,
              )
            : null;
      }

      return null;
    } catch (e, stack) {
      AppLogger.error('Erreur classification Gemma', tag: 'ChatBloc', error: e, stackTrace: stack);
      return null;
    }
  }

  /// Obtient une reponse de Gemma en mode "one-shot" (sans polluer l'historique)
  Future<String> _getGemmaResponse(String prompt) async {
    final buffer = StringBuffer();

    await for (final chunk in _gemmaService.generateOneShot(prompt)) {
      buffer.write(chunk);
    }

    return buffer.toString();
  }

  /// Parle le message si le mode vocal est actif
  void _speakIfVoiceMode(String message, String messageId) {
    if (state.isVoiceMode) {
      AppLogger.info('Speaking checklist response: ${message.length} chars', 'ChatBloc');
      _ttsService.speakStreaming(message, messageId);
    }
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
      content: event.userMessage,
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

    // TTS pour la réponse checklist
    _speakIfVoiceMode(fullMessage, assistantMessage.id);
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
      content: event.userMessage,
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
      content: event.userMessage,
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

    // TTS pour la réponse checklist
    _speakIfVoiceMode('Session d\'inspection terminee. Merci!', assistantMessage.id);

    AppLogger.info('Session checklist terminee', 'ChatBloc');
  }

  // ============== VOICE MODE HANDLERS ==============

  Future<void> _onToggleVoiceMode(
    ChatToggleVoiceMode event,
    Emitter<ChatState> emit,
  ) async {
    final newVoiceMode = !state.isVoiceMode;
    AppLogger.info('Toggling voice mode: $newVoiceMode', 'ChatBloc');

    if (newVoiceMode) {
      // Enabling voice mode - initialize TTS first (always works)
      await _ttsService.init();

      // Try to initialize STT (may fail on some devices)
      await _sttService.init();

      // Enable voice mode even if STT fails (TTS will still work)
      final sttAvailable = _sttService.isAvailable;
      if (!sttAvailable) {
        AppLogger.warning('STT not available, TTS-only mode', 'ChatBloc');
        // Enable voice mode for TTS only
        emit(state.copyWith(
          isVoiceMode: true,
          isListening: false,
        ));
        return;
      }

      // Check/request permission
      final hasPermission = await _sttService.checkPermission();
      if (!hasPermission) {
        final granted = await _sttService.requestPermission();
        if (!granted) {
          AppLogger.warning('Microphone permission denied, TTS-only mode', 'ChatBloc');
          // Enable voice mode for TTS only
          emit(state.copyWith(
            isVoiceMode: true,
            isListening: false,
          ));
          return;
        }
      }

      // Subscribe to STT streams
      await _partialTranscriptionSubscription?.cancel();
      await _finalTranscriptionSubscription?.cancel();
      await _sttStateSubscription?.cancel();
      await _sttErrorSubscription?.cancel();

      _partialTranscriptionSubscription =
          _sttService.partialResultStream.listen((text) {
        add(ChatPartialTranscription(text));
      });

      _finalTranscriptionSubscription = _sttService.finalResultStream.listen(
        (text) {
          add(ChatFinalTranscription(text));
        },
      );

      _sttStateSubscription = _sttService.isListeningStream.listen((listening) {
        if (!isClosed) {
          add(ChatUpdateListeningState(listening));
        }
      });

      _sttErrorSubscription = _sttService.errorStream.listen((error) {
        add(ChatVoiceError(error));
      });

      // Start listening
      await _sttService.startListening();
      emit(state.copyWith(
        isVoiceMode: true,
        isListening: _sttService.isListening,
      ));
    } else {
      // Disabling voice mode - stop listening and cleanup
      await _sttService.stopListening();
      await _partialTranscriptionSubscription?.cancel();
      await _finalTranscriptionSubscription?.cancel();
      await _sttStateSubscription?.cancel();
      await _sttErrorSubscription?.cancel();

      _partialTranscriptionSubscription = null;
      _finalTranscriptionSubscription = null;
      _sttStateSubscription = null;
      _sttErrorSubscription = null;

      emit(state.copyWith(
        isVoiceMode: false,
        isListening: false,
        partialTranscription: '',
      ));
    }
  }

  Future<void> _onStartListening(
    ChatStartListening event,
    Emitter<ChatState> emit,
  ) async {
    if (!state.isVoiceMode || !_sttService.isAvailable) return;

    await _sttService.startListening();
    emit(state.copyWith(isListening: _sttService.isListening));
  }

  Future<void> _onStopListening(
    ChatStopListening event,
    Emitter<ChatState> emit,
  ) async {
    if (!_sttService.isListening) return;

    await _sttService.stopListening();
    emit(state.copyWith(isListening: false, partialTranscription: ''));
  }

  void _onPartialTranscription(
    ChatPartialTranscription event,
    Emitter<ChatState> emit,
  ) {
    // Update partial transcription for real-time UI feedback
    emit(state.copyWith(partialTranscription: event.text));
  }

  Future<void> _onFinalTranscription(
    ChatFinalTranscription event,
    Emitter<ChatState> emit,
  ) async {
    if (event.text.trim().isEmpty) {
      AppLogger.info('Empty transcription, ignoring', 'ChatBloc');
      emit(state.copyWith(partialTranscription: ''));
      return;
    }

    AppLogger.info('Final transcription: "${event.text}"', 'ChatBloc');

    // Clear partial transcription
    emit(state.copyWith(partialTranscription: ''));

    // Send the transcribed message
    add(ChatSendMessage(event.text));

    // Note: Listening will be restarted automatically in _onStreamComplete
    // after the AI response is complete and TTS finishes
  }

  void _onVoiceError(
    ChatVoiceError event,
    Emitter<ChatState> emit,
  ) {
    AppLogger.error('Voice error: ${event.error}', tag: 'ChatBloc');

    // Don't show error for "no match" - it's normal, just restart listening
    if (event.error == 'error_no_match') {
      AppLogger.info('No speech detected, continuing to listen', 'ChatBloc');
      if (state.isVoiceMode && !_sttService.isListening) {
        add(const ChatStartListening());
      }
      return;
    }

    emit(state.copyWith(
      error: ModelError.inferenceError(original: event.error),
    ));
  }

  void _onUpdateListeningState(
    ChatUpdateListeningState event,
    Emitter<ChatState> emit,
  ) {
    emit(state.copyWith(isListening: event.isListening));

    // Auto-restart listening if it stopped while in voice mode
    if (!event.isListening &&
        state.isVoiceMode &&
        !state.isGenerating &&
        state.partialTranscription.isEmpty) {
      AppLogger.info('Auto-restarting listening in voice mode', 'ChatBloc');
      Future.delayed(const Duration(milliseconds: 500), () {
        if (state.isVoiceMode && !_sttService.isListening && !isClosed) {
          add(const ChatStartListening());
        }
      });
    }
  }

  @override
  Future<void> close() {
    _responseSubscription?.cancel();
    _thinkingResponseSubscription?.cancel();
    _partialTranscriptionSubscription?.cancel();
    _finalTranscriptionSubscription?.cancel();
    _sttStateSubscription?.cancel();
    _sttErrorSubscription?.cancel();
    return super.close();
  }
}

/// Classe interne pour le resultat de classification avec confiance
class _ClassificationWithConfidence {
  final ChecklistResponse response;
  final bool isConfident;
  final List<String> probableChoices;
  final String? comment;

  _ClassificationWithConfidence({
    required this.response,
    required this.isConfident,
    this.probableChoices = const [],
    this.comment,
  });
}
