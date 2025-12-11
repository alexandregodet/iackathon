import 'package:equatable/equatable.dart';

import '../../../data/datasources/gemma_service.dart';
import '../../../domain/entities/chat_message.dart';
import '../../../domain/entities/gemma_model_info.dart';

class ChatState extends Equatable {
  final GemmaModelState modelState;
  final GemmaModelInfo? selectedModel;
  final double downloadProgress;
  final List<ChatMessage> messages;
  final bool isGenerating;
  final String? error;

  const ChatState({
    this.modelState = GemmaModelState.notInstalled,
    this.selectedModel,
    this.downloadProgress = 0.0,
    this.messages = const [],
    this.isGenerating = false,
    this.error,
  });

  bool get isModelReady => modelState == GemmaModelState.ready;
  bool get isModelInstalled => modelState == GemmaModelState.installed || isModelReady;
  bool get isDownloading => modelState == GemmaModelState.downloading;
  bool get isLoading => modelState == GemmaModelState.loading;
  bool get isMultimodal => selectedModel?.isMultimodal ?? false;
  bool get requiresAuth => selectedModel?.requiresAuth ?? false;

  ChatState copyWith({
    GemmaModelState? modelState,
    GemmaModelInfo? selectedModel,
    double? downloadProgress,
    List<ChatMessage>? messages,
    bool? isGenerating,
    String? error,
  }) {
    return ChatState(
      modelState: modelState ?? this.modelState,
      selectedModel: selectedModel ?? this.selectedModel,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      messages: messages ?? this.messages,
      isGenerating: isGenerating ?? this.isGenerating,
      error: error,
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
      ];
}
