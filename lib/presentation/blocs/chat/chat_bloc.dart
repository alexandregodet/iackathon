import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../data/datasources/gemma_service.dart';
import '../../../domain/entities/chat_message.dart';
import 'chat_event.dart';
import 'chat_state.dart';

@injectable
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final GemmaService _gemmaService;
  StreamSubscription<String>? _responseSubscription;

  ChatBloc(this._gemmaService) : super(const ChatState()) {
    on<ChatInitialize>(_onInitialize);
    on<ChatDownloadModel>(_onDownloadModel);
    on<ChatLoadModel>(_onLoadModel);
    on<ChatSendMessage>(_onSendMessage);
    on<ChatStreamChunk>(_onStreamChunk);
    on<ChatStreamComplete>(_onStreamComplete);
    on<ChatClearConversation>(_onClearConversation);
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
      _responseSubscription?.cancel();
      _responseSubscription = _gemmaService
          .generateResponse(event.message, imageBytes: event.imageBytes)
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

  @override
  Future<void> close() {
    _responseSubscription?.cancel();
    return super.close();
  }
}
