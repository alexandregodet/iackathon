import 'package:equatable/equatable.dart';

import '../../../core/errors/app_errors.dart';
import '../../../data/datasources/rag_service.dart';
import '../../../domain/entities/pdf_source.dart';

class AskPdfState extends Equatable {
  // Embedder state
  final EmbedderState embedderState;
  final double embedderDownloadProgress;

  // Document state
  final PdfDocumentInfo? currentDocument;
  final bool isLoadingDocument;
  final int documentProcessingCurrent;
  final int documentProcessingTotal;

  // Chat state
  final List<PdfChatMessage> messages;
  final bool isGenerating;
  final bool isThinking;
  final String currentThinkingContent;

  // Source panel state
  final bool isSourcePanelOpen;
  final int? selectedSourceIndex;
  final List<PdfSource> currentSources;

  // Error state
  final AppError? error;

  const AskPdfState({
    this.embedderState = EmbedderState.notInstalled,
    this.embedderDownloadProgress = 0.0,
    this.currentDocument,
    this.isLoadingDocument = false,
    this.documentProcessingCurrent = 0,
    this.documentProcessingTotal = 0,
    this.messages = const [],
    this.isGenerating = false,
    this.isThinking = false,
    this.currentThinkingContent = '',
    this.isSourcePanelOpen = false,
    this.selectedSourceIndex,
    this.currentSources = const [],
    this.error,
  });

  // Embedder getters
  bool get isEmbedderReady => embedderState == EmbedderState.ready;
  bool get isEmbedderInstalled =>
      embedderState == EmbedderState.installed || isEmbedderReady;
  bool get isEmbedderDownloading => embedderState == EmbedderState.downloading;
  bool get isEmbedderLoading => embedderState == EmbedderState.loading;

  // Document getters
  bool get hasDocument => currentDocument != null;
  String get documentName => currentDocument?.name ?? '';
  int get documentPageCount => currentDocument?.pageCount ?? 0;
  int get documentChunkCount => currentDocument?.chunkCount ?? 0;

  // Processing progress
  double get processingProgress => documentProcessingTotal > 0
      ? documentProcessingCurrent / documentProcessingTotal
      : 0.0;

  // Chat getters
  bool get hasMessages => messages.isNotEmpty;
  PdfChatMessage? get lastMessage => messages.isNotEmpty ? messages.last : null;
  bool get canSendQuestion => isEmbedderReady && hasDocument && !isGenerating;

  // Source getters
  bool get hasSources => currentSources.isNotEmpty;
  PdfSource? get selectedSource => selectedSourceIndex != null &&
          selectedSourceIndex! >= 0 &&
          selectedSourceIndex! < currentSources.length
      ? currentSources[selectedSourceIndex!]
      : null;

  // Error getters
  bool get hasError => error != null;
  String? get errorMessage => error?.userMessage;
  bool get isErrorRecoverable => error?.isRecoverable ?? true;

  AskPdfState copyWith({
    EmbedderState? embedderState,
    double? embedderDownloadProgress,
    PdfDocumentInfo? currentDocument,
    bool clearDocument = false,
    bool? isLoadingDocument,
    int? documentProcessingCurrent,
    int? documentProcessingTotal,
    List<PdfChatMessage>? messages,
    bool? isGenerating,
    bool? isThinking,
    String? currentThinkingContent,
    bool? isSourcePanelOpen,
    int? selectedSourceIndex,
    bool clearSelectedSource = false,
    List<PdfSource>? currentSources,
    AppError? error,
    bool clearError = false,
  }) {
    return AskPdfState(
      embedderState: embedderState ?? this.embedderState,
      embedderDownloadProgress:
          embedderDownloadProgress ?? this.embedderDownloadProgress,
      currentDocument:
          clearDocument ? null : (currentDocument ?? this.currentDocument),
      isLoadingDocument: isLoadingDocument ?? this.isLoadingDocument,
      documentProcessingCurrent:
          documentProcessingCurrent ?? this.documentProcessingCurrent,
      documentProcessingTotal:
          documentProcessingTotal ?? this.documentProcessingTotal,
      messages: messages ?? this.messages,
      isGenerating: isGenerating ?? this.isGenerating,
      isThinking: isThinking ?? this.isThinking,
      currentThinkingContent:
          currentThinkingContent ?? this.currentThinkingContent,
      isSourcePanelOpen: isSourcePanelOpen ?? this.isSourcePanelOpen,
      selectedSourceIndex: clearSelectedSource
          ? null
          : (selectedSourceIndex ?? this.selectedSourceIndex),
      currentSources: currentSources ?? this.currentSources,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
        embedderState,
        embedderDownloadProgress,
        currentDocument,
        isLoadingDocument,
        documentProcessingCurrent,
        documentProcessingTotal,
        messages,
        isGenerating,
        isThinking,
        currentThinkingContent,
        isSourcePanelOpen,
        selectedSourceIndex,
        currentSources,
        error,
      ];
}
