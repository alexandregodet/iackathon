import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/errors/app_errors.dart';
import '../../../core/utils/app_logger.dart';
import '../../../data/datasources/ask_pdf_service.dart';
import '../../../data/datasources/gemma_service.dart';
import '../../../data/datasources/rag_service.dart';
import '../../../domain/entities/gemma_model_info.dart';
import '../../../domain/entities/pdf_source.dart';
import 'ask_pdf_event.dart';
import 'ask_pdf_state.dart';

@injectable
class AskPdfBloc extends Bloc<AskPdfEvent, AskPdfState> {
  final GemmaService _gemmaService;
  final AskPdfService _askPdfService;
  StreamSubscription<String>? _responseSubscription;
  StreamSubscription<GemmaStreamResponse>? _thinkingResponseSubscription;
  List<PdfSource> _pendingSources = [];
  GemmaModelInfo? _modelInfo;

  AskPdfBloc(this._gemmaService, this._askPdfService)
      : super(const AskPdfState()) {
    on<AskPdfInitialize>(_onInitialize);
    on<AskPdfDownloadEmbedder>(_onDownloadEmbedder);
    on<AskPdfLoadEmbedder>(_onLoadEmbedder);
    on<AskPdfDownloadGemma>(_onDownloadGemma);
    on<AskPdfLoadGemma>(_onLoadGemma);
    on<AskPdfSelectFile>(_onSelectFile);
    on<AskPdfProcessingProgress>(_onProcessingProgress);
    on<AskPdfSendQuestion>(_onSendQuestion);
    on<AskPdfStreamChunk>(_onStreamChunk);
    on<AskPdfThinkingChunk>(_onThinkingChunk);
    on<AskPdfThinkingComplete>(_onThinkingComplete);
    on<AskPdfStreamComplete>(_onStreamComplete);
    on<AskPdfStreamError>(_onStreamError);
    on<AskPdfClearSession>(_onClearSession);
    on<AskPdfToggleSourcePanel>(_onToggleSourcePanel);
    on<AskPdfSelectSource>(_onSelectSource);
    on<AskPdfStopGeneration>(_onStopGeneration);
  }

  Future<void> _onInitialize(
    AskPdfInitialize event,
    Emitter<AskPdfState> emit,
  ) async {
    AppLogger.info('Initializing Ask PDF with model: ${event.modelInfo.name}', 'AskPdfBloc');
    _modelInfo = event.modelInfo;

    // Check embedder status
    await _askPdfService.checkEmbedderStatus();

    // Check Gemma model status
    await _gemmaService.checkModelStatus(event.modelInfo);

    emit(state.copyWith(
      embedderState: _askPdfService.state,
      gemmaState: _gemmaService.state,
    ));
  }

  Future<void> _onDownloadEmbedder(
    AskPdfDownloadEmbedder event,
    Emitter<AskPdfState> emit,
  ) async {
    AppLogger.info('Downloading embedder', 'AskPdfBloc');

    try {
      emit(state.copyWith(
        embedderState: EmbedderState.downloading,
        embedderDownloadProgress: 0.0,
        clearError: true,
      ));

      await _askPdfService.downloadEmbedder(
        onProgress: (progress) {
          emit(state.copyWith(embedderDownloadProgress: progress));
        },
      );

      emit(state.copyWith(embedderState: EmbedderState.installed));
    } on AppError catch (e) {
      AppLogger.logAppError(e, 'AskPdfBloc');
      emit(state.copyWith(embedderState: EmbedderState.error, error: e));
    } catch (e, stack) {
      AppLogger.error(
        'Embedder download failed',
        tag: 'AskPdfBloc',
        error: e,
        stackTrace: stack,
      );
      emit(state.copyWith(
        embedderState: EmbedderState.error,
        error: NetworkError.downloadFailed(
          modelName: 'embedder',
          original: e,
          stack: stack,
        ),
      ));
    }
  }

  Future<void> _onLoadEmbedder(
    AskPdfLoadEmbedder event,
    Emitter<AskPdfState> emit,
  ) async {
    AppLogger.info('Loading embedder', 'AskPdfBloc');

    try {
      emit(state.copyWith(
        embedderState: EmbedderState.loading,
        clearError: true,
      ));

      await _askPdfService.loadEmbedder();
      emit(state.copyWith(embedderState: EmbedderState.ready));
    } on AppError catch (e) {
      AppLogger.logAppError(e, 'AskPdfBloc');
      emit(state.copyWith(embedderState: EmbedderState.error, error: e));
    } catch (e, stack) {
      AppLogger.error(
        'Embedder loading failed',
        tag: 'AskPdfBloc',
        error: e,
        stackTrace: stack,
      );
      emit(state.copyWith(
        embedderState: EmbedderState.error,
        error: RagError.embedderNotLoaded(stack: stack),
      ));
    }
  }

  Future<void> _onDownloadGemma(
    AskPdfDownloadGemma event,
    Emitter<AskPdfState> emit,
  ) async {
    if (_modelInfo == null) {
      AppLogger.warning('No model info set', 'AskPdfBloc');
      return;
    }

    AppLogger.info('Downloading Gemma model: ${_modelInfo!.name}', 'AskPdfBloc');

    try {
      emit(state.copyWith(
        gemmaState: GemmaModelState.downloading,
        gemmaDownloadProgress: 0.0,
        clearError: true,
      ));

      await _gemmaService.downloadModel(
        _modelInfo!,
        onProgress: (progress) {
          emit(state.copyWith(gemmaDownloadProgress: progress));
        },
      );

      emit(state.copyWith(gemmaState: GemmaModelState.installed));
    } on AppError catch (e) {
      AppLogger.logAppError(e, 'AskPdfBloc');
      emit(state.copyWith(gemmaState: GemmaModelState.error, error: e));
    } catch (e, stack) {
      AppLogger.error(
        'Gemma download failed',
        tag: 'AskPdfBloc',
        error: e,
        stackTrace: stack,
      );
      emit(state.copyWith(
        gemmaState: GemmaModelState.error,
        error: NetworkError.downloadFailed(
          
          original: e,
          stack: stack,
        ),
      ));
    }
  }

  Future<void> _onLoadGemma(
    AskPdfLoadGemma event,
    Emitter<AskPdfState> emit,
  ) async {
    if (_modelInfo == null) {
      AppLogger.warning('No model info set', 'AskPdfBloc');
      return;
    }

    AppLogger.info('Loading Gemma model: ${_modelInfo!.name}', 'AskPdfBloc');

    try {
      emit(state.copyWith(
        gemmaState: GemmaModelState.loading,
        clearError: true,
      ));

      await _gemmaService.loadModel(_modelInfo);
      emit(state.copyWith(gemmaState: GemmaModelState.ready));
    } on AppError catch (e) {
      AppLogger.logAppError(e, 'AskPdfBloc');
      emit(state.copyWith(gemmaState: GemmaModelState.error, error: e));
    } catch (e, stack) {
      AppLogger.error(
        'Gemma loading failed',
        tag: 'AskPdfBloc',
        error: e,
        stackTrace: stack,
      );
      emit(state.copyWith(
        gemmaState: GemmaModelState.error,
        error: ModelError.loadingFailed(
          
          original: e,
          stack: stack,
        ),
      ));
    }
  }

  Future<void> _onSelectFile(
    AskPdfSelectFile event,
    Emitter<AskPdfState> emit,
  ) async {
    AppLogger.info('Loading PDF: ${event.fileName}', 'AskPdfBloc');

    try {
      emit(state.copyWith(
        isLoadingDocument: true,
        documentProcessingCurrent: 0,
        documentProcessingTotal: 0,
        clearError: true,
        messages: [],
        currentSources: [],
      ));

      final docInfo = await _askPdfService.loadPdf(
        event.filePath,
        onProgress: (current, total) {
          add(AskPdfProcessingProgress(current: current, total: total));
        },
      );

      emit(state.copyWith(
        currentDocument: docInfo,
        isLoadingDocument: false,
      ));

      AppLogger.info(
        'PDF loaded: ${docInfo.chunkCount} chunks',
        'AskPdfBloc',
      );
    } on AppError catch (e) {
      AppLogger.logAppError(e, 'AskPdfBloc');
      emit(state.copyWith(isLoadingDocument: false, error: e));
    } catch (e, stack) {
      AppLogger.error(
        'PDF loading failed',
        tag: 'AskPdfBloc',
        error: e,
        stackTrace: stack,
      );
      emit(state.copyWith(
        isLoadingDocument: false,
        error: RagError.pdfExtractionFailed(
          fileName: event.fileName,
          original: e,
          stack: stack,
        ),
      ));
    }
  }

  void _onProcessingProgress(
    AskPdfProcessingProgress event,
    Emitter<AskPdfState> emit,
  ) {
    emit(state.copyWith(
      documentProcessingCurrent: event.current,
      documentProcessingTotal: event.total,
    ));
  }

  Future<void> _onSendQuestion(
    AskPdfSendQuestion event,
    Emitter<AskPdfState> emit,
  ) async {
    if (!_gemmaService.isReady) {
      AppLogger.warning('Model not loaded', 'AskPdfBloc');
      emit(state.copyWith(error: ModelError.notLoaded()));
      return;
    }

    if (!state.hasDocument) {
      AppLogger.warning('No document loaded', 'AskPdfBloc');
      return;
    }

    if (state.isGenerating) return;

    AppLogger.debug('Sending question', 'AskPdfBloc');

    // Create user message
    final userMessage = PdfChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: MessageType.user,
      content: event.question,
      timestamp: DateTime.now(),
    );

    // Create assistant message placeholder
    final assistantMessage = PdfChatMessage(
      id: '${DateTime.now().millisecondsSinceEpoch}_assistant',
      type: MessageType.assistant,
      content: '',
      timestamp: DateTime.now(),
      isStreaming: true,
    );

    emit(state.copyWith(
      messages: [...state.messages, userMessage, assistantMessage],
      isGenerating: true,
      clearError: true,
      currentSources: [],
      isSourcePanelOpen: false,
    ));

    try {
      // Build augmented prompt with sources
      final (prompt, sources) = await _askPdfService.buildAugmentedPromptWithSources(
        userQuery: event.question,
        topK: 4,
        threshold: 0.4,
      );

      _pendingSources = sources;

      // Cancel any existing subscription
      _responseSubscription?.cancel();
      _thinkingResponseSubscription?.cancel();

      // Use thinking-aware generation if supported
      if (_gemmaService.supportsThinking) {
        emit(state.copyWith(isThinking: true, currentThinkingContent: ''));

        _thinkingResponseSubscription = _gemmaService
            .generateResponseWithThinking(prompt)
            .listen(
              (response) {
                if (response.isThinkingPhase && response.thinkingChunk != null) {
                  add(AskPdfThinkingChunk(response.thinkingChunk!));
                } else if (response.textChunk != null) {
                  add(AskPdfStreamChunk(response.textChunk!));
                }
              },
              onDone: () {
                add(const AskPdfThinkingComplete());
                add(AskPdfStreamComplete(sources: _pendingSources));
              },
              onError: (e) => add(AskPdfStreamError(
                e is AppError ? e : ModelError.inferenceError(original: e),
              )),
            );
      } else {
        _responseSubscription = _gemmaService.generateResponse(prompt).listen(
              (chunk) => add(AskPdfStreamChunk(chunk)),
              onDone: () => add(AskPdfStreamComplete(sources: _pendingSources)),
              onError: (e) => add(AskPdfStreamError(
                e is AppError ? e : ModelError.inferenceError(original: e),
              )),
            );
      }
    } on AppError catch (e) {
      AppLogger.logAppError(e, 'AskPdfBloc');
      emit(state.copyWith(isGenerating: false, error: e));
    } catch (e, stack) {
      AppLogger.error(
        'Question failed',
        tag: 'AskPdfBloc',
        error: e,
        stackTrace: stack,
      );
      emit(state.copyWith(
        isGenerating: false,
        error: ModelError.inferenceError(original: e, stack: stack),
      ));
    }
  }

  void _onStreamChunk(AskPdfStreamChunk event, Emitter<AskPdfState> emit) {
    if (state.messages.isEmpty) return;

    final messages = List<PdfChatMessage>.from(state.messages);
    final lastMessage = messages.last;

    if (lastMessage.type == MessageType.assistant) {
      messages[messages.length - 1] = lastMessage.copyWith(
        content: lastMessage.content + event.chunk,
      );
      emit(state.copyWith(messages: messages));
    }
  }

  void _onThinkingChunk(AskPdfThinkingChunk event, Emitter<AskPdfState> emit) {
    final newThinkingContent = state.currentThinkingContent + event.chunk;
    emit(state.copyWith(currentThinkingContent: newThinkingContent));

    if (state.messages.isEmpty) return;

    final messages = List<PdfChatMessage>.from(state.messages);
    final lastMessage = messages.last;

    if (lastMessage.type == MessageType.assistant) {
      messages[messages.length - 1] = lastMessage.copyWith(
        thinkingContent: newThinkingContent,
      );
      emit(state.copyWith(messages: messages));
    }
  }

  void _onThinkingComplete(
    AskPdfThinkingComplete event,
    Emitter<AskPdfState> emit,
  ) {
    emit(state.copyWith(isThinking: false));

    if (state.messages.isEmpty) return;

    final messages = List<PdfChatMessage>.from(state.messages);
    final lastMessage = messages.last;

    if (lastMessage.type == MessageType.assistant) {
      messages[messages.length - 1] = lastMessage.copyWith(
        isThinkingComplete: true,
      );
      emit(state.copyWith(messages: messages));
    }
  }

  void _onStreamComplete(
    AskPdfStreamComplete event,
    Emitter<AskPdfState> emit,
  ) {
    if (state.messages.isEmpty) return;

    final messages = List<PdfChatMessage>.from(state.messages);
    final lastMessage = messages.last;

    if (lastMessage.type == MessageType.assistant) {
      messages[messages.length - 1] = lastMessage.copyWith(
        isStreaming: false,
        sources: event.sources,
      );

      emit(state.copyWith(
        messages: messages,
        isGenerating: false,
        currentSources: event.sources,
        isSourcePanelOpen: event.sources.isNotEmpty,
      ));
    }

    _pendingSources = [];
  }

  void _onStreamError(AskPdfStreamError event, Emitter<AskPdfState> emit) {
    AppLogger.logAppError(event.error, 'AskPdfBloc');
    emit(state.copyWith(
      isGenerating: false,
      isThinking: false,
      error: event.error,
    ));
    _pendingSources = [];
  }

  Future<void> _onClearSession(
    AskPdfClearSession event,
    Emitter<AskPdfState> emit,
  ) async {
    await _askPdfService.clearSession();
    emit(state.copyWith(
      clearDocument: true,
      messages: [],
      currentSources: [],
      isSourcePanelOpen: false,
      clearSelectedSource: true,
    ));
  }

  void _onToggleSourcePanel(
    AskPdfToggleSourcePanel event,
    Emitter<AskPdfState> emit,
  ) {
    emit(state.copyWith(isSourcePanelOpen: !state.isSourcePanelOpen));
  }

  void _onSelectSource(
    AskPdfSelectSource event,
    Emitter<AskPdfState> emit,
  ) {
    emit(state.copyWith(
      selectedSourceIndex: event.sourceIndex,
      clearSelectedSource: event.sourceIndex == null,
      isSourcePanelOpen: true,
    ));
  }

  Future<void> _onStopGeneration(
    AskPdfStopGeneration event,
    Emitter<AskPdfState> emit,
  ) async {
    await _responseSubscription?.cancel();
    await _thinkingResponseSubscription?.cancel();
    _responseSubscription = null;
    _thinkingResponseSubscription = null;

    if (state.messages.isEmpty) {
      emit(state.copyWith(isGenerating: false, isThinking: false));
      return;
    }

    final messages = List<PdfChatMessage>.from(state.messages);
    final lastMessage = messages.last;

    if (lastMessage.type == MessageType.assistant && lastMessage.isStreaming) {
      messages[messages.length - 1] = lastMessage.copyWith(
        isStreaming: false,
        sources: _pendingSources,
      );

      emit(state.copyWith(
        messages: messages,
        isGenerating: false,
        isThinking: false,
        currentSources: _pendingSources,
      ));
    } else {
      emit(state.copyWith(isGenerating: false, isThinking: false));
    }

    _pendingSources = [];
  }

  @override
  Future<void> close() {
    _responseSubscription?.cancel();
    _thinkingResponseSubscription?.cancel();
    return super.close();
  }
}
