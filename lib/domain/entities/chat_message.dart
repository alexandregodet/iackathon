import 'dart:typed_data';

import 'package:equatable/equatable.dart';

enum MessageRole { user, assistant }

class ChatMessage extends Equatable {
  final String id;
  final MessageRole role;
  final String content;
  final DateTime timestamp;
  final bool isStreaming;
  final Uint8List? imageBytes;
  final String? thinkingContent;
  final bool isThinkingComplete;

  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isStreaming = false,
    this.imageBytes,
    this.thinkingContent,
    this.isThinkingComplete = false,
  });

  bool get hasImage => imageBytes != null;
  bool get hasThinking => thinkingContent != null && thinkingContent!.isNotEmpty;

  ChatMessage copyWith({
    String? id,
    MessageRole? role,
    String? content,
    DateTime? timestamp,
    bool? isStreaming,
    Uint8List? imageBytes,
    String? thinkingContent,
    bool? isThinkingComplete,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
      imageBytes: imageBytes ?? this.imageBytes,
      thinkingContent: thinkingContent ?? this.thinkingContent,
      isThinkingComplete: isThinkingComplete ?? this.isThinkingComplete,
    );
  }

  @override
  List<Object?> get props => [
        id,
        role,
        content,
        timestamp,
        isStreaming,
        imageBytes,
        thinkingContent,
        isThinkingComplete,
      ];
}
