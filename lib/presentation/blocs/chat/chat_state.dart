import 'package:equatable/equatable.dart';

import '../../../core/errors/app_errors.dart';
import '../../../data/datasources/gemma_service.dart';
import '../../../data/datasources/rag_service.dart';
import '../../../domain/entities/chat_message.dart';
import '../../../domain/entities/conversation_info.dart';
import '../../../domain/entities/document_info.dart';
import '../../../domain/entities/gemma_model_info.dart';

class ChatState extends Equatable {
  final GemmaModelState modelState;
  final GemmaModelInfo? selectedModel;
  final double downloadProgress;
  final List<ChatMessage> messages;
  final bool isGenerating;
  final AppError? error;

  // Conversation State
  final List<ConversationInfo> conversations;
  final int? currentConversationId;
  final bool isLoadingConversations;

  // RAG State
  final EmbedderState embedderState;
  final double embedderDownloadProgress;
  final List<DocumentInfo> documents;
  final bool isProcessingDocument;
  final int documentProcessingCurrent;
  final int documentProcessingTotal;
  final AppError? ragError;

  // Thinking State
  final bool isThinking;
  final String currentThinkingContent;

  // Error helpers
  bool get hasError => error != null;
  bool get hasRagError => ragError != null;
  String? get errorMessage => error?.userMessage;
  String? get ragErrorMessage => ragError?.userMessage;
  bool get isErrorRecoverable => error?.isRecoverable ?? true;
  bool get isRagErrorRecoverable => ragError?.isRecoverable ?? true;

  const ChatState({
    this.modelState = GemmaModelState.notInstalled,
    this.selectedModel,
    this.downloadProgress = 0.0,
    this.messages = const [],
    this.isGenerating = false,
    this.error,
    // Conversation defaults
    this.conversations = const [],
    this.currentConversationId,
    this.isLoadingConversations = false,
    // RAG defaults
    this.embedderState = EmbedderState.notInstalled,
    this.embedderDownloadProgress = 0.0,
    this.documents = const [],
    this.isProcessingDocument = false,
    this.documentProcessingCurrent = 0,
    this.documentProcessingTotal = 0,
    this.ragError,
    // Thinking defaults
    this.isThinking = false,
    this.currentThinkingContent = '',
  });

  bool get isModelReady => modelState == GemmaModelState.ready;
  bool get isModelInstalled => modelState == GemmaModelState.installed || isModelReady;
  bool get isDownloading => modelState == GemmaModelState.downloading;
  bool get isLoading => modelState == GemmaModelState.loading;
  bool get isMultimodal => selectedModel?.isMultimodal ?? false;
  bool get requiresAuth => selectedModel?.requiresAuth ?? false;

  // Thinking getters
  bool get supportsThinking => selectedModel?.supportsThinking ?? false;

  // RAG getters
  bool get isEmbedderReady => embedderState == EmbedderState.ready;
  bool get isEmbedderInstalled =>
      embedderState == EmbedderState.installed || isEmbedderReady;
  List<DocumentInfo> get activeDocuments =>
      documents.where((d) => d.isActive).toList();
  bool get hasActiveDocuments => activeDocuments.isNotEmpty;
  int get activeDocumentCount => activeDocuments.length;

  // Conversation getters
  bool get hasCurrentConversation => currentConversationId != null;
  ConversationInfo? get currentConversation => hasCurrentConversation
      ? conversations.cast<ConversationInfo?>().firstWhere(
            (c) => c?.id == currentConversationId,
            orElse: () => null,
          )
      : null;

  // Context usage getters
  static const int maxContextTokens = 8192;
  // Estimation des tokens par image (basé sur résolution 1024x1024)
  static const int tokensPerImage = 512;

  int get estimatedTokensUsed {
    int totalChars = 0;
    int imageCount = 0;
    for (final msg in messages) {
      totalChars += msg.content.length;
      if (msg.thinkingContent != null) {
        totalChars += msg.thinkingContent!.length;
      }
      if (msg.hasImage) {
        imageCount++;
      }
    }
    // ~4 caractères par token + tokens pour les images
    return (totalChars / 4).ceil() + (imageCount * tokensPerImage);
  }

  double get contextUsagePercent =>
      (estimatedTokensUsed / maxContextTokens).clamp(0.0, 1.0);

  bool get isContextNearlyFull => contextUsagePercent > 0.8;

  ChatState copyWith({
    GemmaModelState? modelState,
    GemmaModelInfo? selectedModel,
    double? downloadProgress,
    List<ChatMessage>? messages,
    bool? isGenerating,
    AppError? error,
    bool clearError = false,
    // Conversation
    List<ConversationInfo>? conversations,
    int? currentConversationId,
    bool clearCurrentConversation = false,
    bool? isLoadingConversations,
    // RAG
    EmbedderState? embedderState,
    double? embedderDownloadProgress,
    List<DocumentInfo>? documents,
    bool? isProcessingDocument,
    int? documentProcessingCurrent,
    int? documentProcessingTotal,
    AppError? ragError,
    bool clearRagError = false,
    // Thinking
    bool? isThinking,
    String? currentThinkingContent,
  }) {
    return ChatState(
      modelState: modelState ?? this.modelState,
      selectedModel: selectedModel ?? this.selectedModel,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      messages: messages ?? this.messages,
      isGenerating: isGenerating ?? this.isGenerating,
      error: clearError ? null : (error ?? this.error),
      // Conversation
      conversations: conversations ?? this.conversations,
      currentConversationId: clearCurrentConversation
          ? null
          : (currentConversationId ?? this.currentConversationId),
      isLoadingConversations:
          isLoadingConversations ?? this.isLoadingConversations,
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
      ragError: clearRagError ? null : (ragError ?? this.ragError),
      // Thinking
      isThinking: isThinking ?? this.isThinking,
      currentThinkingContent:
          currentThinkingContent ?? this.currentThinkingContent,
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
        // Conversation
        conversations,
        currentConversationId,
        isLoadingConversations,
        // RAG
        embedderState,
        embedderDownloadProgress,
        documents,
        isProcessingDocument,
        documentProcessingCurrent,
        documentProcessingTotal,
        ragError,
        // Thinking
        isThinking,
        currentThinkingContent,
      ];
}
