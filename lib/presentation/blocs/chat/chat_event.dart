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

// RAG Events
class ChatCheckEmbedder extends ChatEvent {
  const ChatCheckEmbedder();
}

class ChatDownloadEmbedder extends ChatEvent {
  const ChatDownloadEmbedder();
}

class ChatLoadEmbedder extends ChatEvent {
  const ChatLoadEmbedder();
}

class ChatLoadDocuments extends ChatEvent {
  const ChatLoadDocuments();
}

class ChatDocumentSelected extends ChatEvent {
  final String filePath;
  final String fileName;

  const ChatDocumentSelected({
    required this.filePath,
    required this.fileName,
  });

  @override
  List<Object?> get props => [filePath, fileName];
}

class ChatDocumentProcessingProgress extends ChatEvent {
  final int current;
  final int total;

  const ChatDocumentProcessingProgress({
    required this.current,
    required this.total,
  });

  @override
  List<Object?> get props => [current, total];
}

class ChatToggleDocument extends ChatEvent {
  final int documentId;
  final bool isActive;

  const ChatToggleDocument({
    required this.documentId,
    required this.isActive,
  });

  @override
  List<Object?> get props => [documentId, isActive];
}

class ChatRemoveDocument extends ChatEvent {
  final int documentId;

  const ChatRemoveDocument(this.documentId);

  @override
  List<Object?> get props => [documentId];
}

// Conversation Events
class ChatLoadConversations extends ChatEvent {
  const ChatLoadConversations();
}

class ChatCreateConversation extends ChatEvent {
  final String? title;

  const ChatCreateConversation({this.title});

  @override
  List<Object?> get props => [title];
}

class ChatLoadConversation extends ChatEvent {
  final int conversationId;

  const ChatLoadConversation(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class ChatDeleteConversation extends ChatEvent {
  final int conversationId;

  const ChatDeleteConversation(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class ChatRenameConversation extends ChatEvent {
  final int conversationId;
  final String newTitle;

  const ChatRenameConversation({
    required this.conversationId,
    required this.newTitle,
  });

  @override
  List<Object?> get props => [conversationId, newTitle];
}
