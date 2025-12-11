import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import '../../../domain/entities/gemma_model_info.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class ChatInitialize extends ChatEvent {
  final GemmaModelInfo modelInfo;

  const ChatInitialize(this.modelInfo);

  @override
  List<Object?> get props => [modelInfo];
}

class ChatDownloadModel extends ChatEvent {
  final String? huggingFaceToken;

  const ChatDownloadModel({this.huggingFaceToken});

  @override
  List<Object?> get props => [huggingFaceToken];
}

class ChatLoadModel extends ChatEvent {
  const ChatLoadModel();
}

class ChatSendMessage extends ChatEvent {
  final String message;
  final Uint8List? imageBytes;

  const ChatSendMessage(this.message, {this.imageBytes});

  @override
  List<Object?> get props => [message, imageBytes];
}

class ChatStreamChunk extends ChatEvent {
  final String chunk;

  const ChatStreamChunk(this.chunk);

  @override
  List<Object?> get props => [chunk];
}

class ChatStreamComplete extends ChatEvent {
  const ChatStreamComplete();
}

class ChatClearConversation extends ChatEvent {
  const ChatClearConversation();
}
