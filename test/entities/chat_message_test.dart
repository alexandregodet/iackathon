import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:iackathon/domain/entities/chat_message.dart';

void main() {
  group('ChatMessage', () {
    final testTimestamp = DateTime(2024, 1, 1, 12, 0);

    test('creates message with required fields', () {
      final message = ChatMessage(
        id: '1',
        role: MessageRole.user,
        content: 'Hello',
        timestamp: testTimestamp,
      );

      expect(message.id, '1');
      expect(message.role, MessageRole.user);
      expect(message.content, 'Hello');
      expect(message.timestamp, testTimestamp);
      expect(message.isStreaming, false);
      expect(message.imageBytes, null);
      expect(message.thinkingContent, null);
      expect(message.isThinkingComplete, false);
    });

    test('creates message with optional fields', () {
      final imageData = Uint8List.fromList([1, 2, 3]);
      final message = ChatMessage(
        id: '2',
        role: MessageRole.assistant,
        content: 'Response',
        timestamp: testTimestamp,
        isStreaming: true,
        imageBytes: imageData,
        thinkingContent: 'Thinking...',
        isThinkingComplete: true,
      );

      expect(message.isStreaming, true);
      expect(message.imageBytes, imageData);
      expect(message.thinkingContent, 'Thinking...');
      expect(message.isThinkingComplete, true);
    });

    test('hasImage returns correct value', () {
      final messageWithoutImage = ChatMessage(
        id: '1',
        role: MessageRole.user,
        content: 'Hello',
        timestamp: testTimestamp,
      );

      final messageWithImage = ChatMessage(
        id: '2',
        role: MessageRole.user,
        content: 'Hello',
        timestamp: testTimestamp,
        imageBytes: Uint8List.fromList([1, 2, 3]),
      );

      expect(messageWithoutImage.hasImage, false);
      expect(messageWithImage.hasImage, true);
    });

    test('hasThinking returns correct value', () {
      final messageWithoutThinking = ChatMessage(
        id: '1',
        role: MessageRole.assistant,
        content: 'Response',
        timestamp: testTimestamp,
      );

      final messageWithEmptyThinking = ChatMessage(
        id: '2',
        role: MessageRole.assistant,
        content: 'Response',
        timestamp: testTimestamp,
        thinkingContent: '',
      );

      final messageWithThinking = ChatMessage(
        id: '3',
        role: MessageRole.assistant,
        content: 'Response',
        timestamp: testTimestamp,
        thinkingContent: 'Let me think...',
      );

      expect(messageWithoutThinking.hasThinking, false);
      expect(messageWithEmptyThinking.hasThinking, false);
      expect(messageWithThinking.hasThinking, true);
    });

    test('copyWith preserves unchanged values', () {
      final original = ChatMessage(
        id: '1',
        role: MessageRole.user,
        content: 'Hello',
        timestamp: testTimestamp,
        isStreaming: true,
      );

      final copied = original.copyWith(content: 'Updated');

      expect(copied.id, '1');
      expect(copied.role, MessageRole.user);
      expect(copied.content, 'Updated');
      expect(copied.timestamp, testTimestamp);
      expect(copied.isStreaming, true);
    });

    test('copyWith updates all fields', () {
      final original = ChatMessage(
        id: '1',
        role: MessageRole.user,
        content: 'Hello',
        timestamp: testTimestamp,
      );

      final newTimestamp = DateTime(2024, 2, 1);
      final newImage = Uint8List.fromList([4, 5, 6]);

      final copied = original.copyWith(
        id: '2',
        role: MessageRole.assistant,
        content: 'New content',
        timestamp: newTimestamp,
        isStreaming: true,
        imageBytes: newImage,
        thinkingContent: 'Thinking...',
        isThinkingComplete: true,
      );

      expect(copied.id, '2');
      expect(copied.role, MessageRole.assistant);
      expect(copied.content, 'New content');
      expect(copied.timestamp, newTimestamp);
      expect(copied.isStreaming, true);
      expect(copied.imageBytes, newImage);
      expect(copied.thinkingContent, 'Thinking...');
      expect(copied.isThinkingComplete, true);
    });

    test('equality works correctly', () {
      final message1 = ChatMessage(
        id: '1',
        role: MessageRole.user,
        content: 'Hello',
        timestamp: testTimestamp,
      );

      final message2 = ChatMessage(
        id: '1',
        role: MessageRole.user,
        content: 'Hello',
        timestamp: testTimestamp,
      );

      final message3 = ChatMessage(
        id: '2',
        role: MessageRole.user,
        content: 'Hello',
        timestamp: testTimestamp,
      );

      expect(message1, message2);
      expect(message1, isNot(message3));
    });
  });

  group('MessageRole', () {
    test('has correct values', () {
      expect(MessageRole.values.length, 2);
      expect(MessageRole.values, contains(MessageRole.user));
      expect(MessageRole.values, contains(MessageRole.assistant));
    });
  });
}
