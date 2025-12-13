import 'package:equatable/equatable.dart';

import '../../../data/datasources/gemma_service.dart';
import '../../../data/datasources/rag_service.dart';
import '../../../domain/entities/chat_message.dart';
import '../../../domain/entities/document_info.dart';
import '../../../domain/entities/gemma_model_info.dart';

class ChatState extends Equatable {
  final GemmaModelState modelState;
  final GemmaModelInfo? selectedModel;
  final double downloadProgress;
  final List<ChatMessage> messages;
  final bool isGenerating;
  final String? error;

  // RAG State
  final EmbedderState embedderState;
  final double embedderDownloadProgress;
  final List<DocumentInfo> documents;
  final bool isProcessingDocument;
  final int documentProcessingCurrent;
  final int documentProcessingTotal;
  final String? ragError;

  const ChatState({
    this.modelState = GemmaModelState.notInstalled,
    this.selectedModel,
    this.downloadProgress = 0.0,
    this.messages = const [],
    this.isGenerating = false,
    this.error,
    // RAG defaults
    this.embedderState = EmbedderState.notInstalled,
    this.embedderDownloadProgress = 0.0,
    this.documents = const [],
    this.isProcessingDocument = false,
    this.documentProcessingCurrent = 0,
    this.documentProcessingTotal = 0,
    this.ragError,
  });

  bool get isModelReady => modelState == GemmaModelState.ready;
  bool get isModelInstalled => modelState == GemmaModelState.installed || isModelReady;
  bool get isDownloading => modelState == GemmaModelState.downloading;
  bool get isLoading => modelState == GemmaModelState.loading;
  bool get isMultimodal => selectedModel?.isMultimodal ?? false;
  bool get requiresAuth => selectedModel?.requiresAuth ?? false;

  // RAG getters
  bool get isEmbedderReady => embedderState == EmbedderState.ready;
  bool get isEmbedderInstalled =>
      embedderState == EmbedderState.installed || isEmbedderReady;
  List<DocumentInfo> get activeDocuments =>
      documents.where((d) => d.isActive).toList();
  bool get hasActiveDocuments => activeDocuments.isNotEmpty;
  int get activeDocumentCount => activeDocuments.length;

  ChatState copyWith({
    GemmaModelState? modelState,
    GemmaModelInfo? selectedModel,
    double? downloadProgress,
    List<ChatMessage>? messages,
    bool? isGenerating,
    String? error,
    // RAG
    EmbedderState? embedderState,
    double? embedderDownloadProgress,
    List<DocumentInfo>? documents,
    bool? isProcessingDocument,
    int? documentProcessingCurrent,
    int? documentProcessingTotal,
    String? ragError,
  }) {
    return ChatState(
      modelState: modelState ?? this.modelState,
      selectedModel: selectedModel ?? this.selectedModel,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      messages: messages ?? this.messages,
      isGenerating: isGenerating ?? this.isGenerating,
      error: error,
      // RAG
      embedderState: embedderState ?? this.embedderState,
      embedderDownloadProgress:
          embedderDownloadProgress ?? this.embedderDownloadProgress,
      documents: documents ?? this.documents,
      isProcessingDocument: isProcessingDocument ?? this.isProcessingDocument,
      documentProcessingCurrent:
          documentProcessingCurrent ?? this.documentProcessingCurrent,
      documentProcessingTotal:
          documentProcessingTotal ?? this.documentProcessingTotal,
      ragError: ragError,
    );
  }

  @override
  List<Object?> get props => [
        modelState,
        selectedModel,
        downloadProgress,
        messages,
        isGenerating,
        error,
        // RAG
        embedderState,
        embedderDownloadProgress,
        documents,
        isProcessingDocument,
        documentProcessingCurrent,
        documentProcessingTotal,
        ragError,
      ];
}
