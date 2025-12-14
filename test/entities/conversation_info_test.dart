import 'package:flutter_test/flutter_test.dart';

import 'package:iackathon/domain/entities/conversation_info.dart';

void main() {
  group('ConversationInfo', () {
    final testCreatedAt = DateTime(2024, 1, 1, 10, 0);
    final testUpdatedAt = DateTime(2024, 1, 1, 12, 0);

    test('creates conversation with required fields', () {
      final conv = ConversationInfo(
        id: 1,
        title: 'Test Conversation',
        createdAt: testCreatedAt,
        updatedAt: testUpdatedAt,
      );

      expect(conv.id, 1);
      expect(conv.title, 'Test Conversation');
      expect(conv.createdAt, testCreatedAt);
      expect(conv.updatedAt, testUpdatedAt);
      expect(conv.messageCount, 0);
      expect(conv.lastMessage, isNull);
    });

    test('creates conversation with optional fields', () {
      final conv = ConversationInfo(
        id: 2,
        title: 'Active Conversation',
        createdAt: testCreatedAt,
        updatedAt: testUpdatedAt,
        messageCount: 15,
        lastMessage: 'Hello, how are you?',
      );

      expect(conv.messageCount, 15);
      expect(conv.lastMessage, 'Hello, how are you?');
    });

    group('copyWith', () {
      test('preserves unchanged values', () {
        final original = ConversationInfo(
          id: 1,
          title: 'Original',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          messageCount: 5,
          lastMessage: 'Last message',
        );

        final copied = original.copyWith(title: 'Updated');

        expect(copied.id, 1);
        expect(copied.title, 'Updated');
        expect(copied.createdAt, testCreatedAt);
        expect(copied.updatedAt, testUpdatedAt);
        expect(copied.messageCount, 5);
        expect(copied.lastMessage, 'Last message');
      });

      test('updates all fields', () {
        final original = ConversationInfo(
          id: 1,
          title: 'Original',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        final newCreatedAt = DateTime(2024, 2, 1);
        final newUpdatedAt = DateTime(2024, 2, 15);

        final copied = original.copyWith(
          id: 2,
          title: 'New Title',
          createdAt: newCreatedAt,
          updatedAt: newUpdatedAt,
          messageCount: 10,
          lastMessage: 'New last message',
        );

        expect(copied.id, 2);
        expect(copied.title, 'New Title');
        expect(copied.createdAt, newCreatedAt);
        expect(copied.updatedAt, newUpdatedAt);
        expect(copied.messageCount, 10);
        expect(copied.lastMessage, 'New last message');
      });

      test('updates only id', () {
        final original = ConversationInfo(
          id: 1,
          title: 'Test',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        final copied = original.copyWith(id: 99);

        expect(copied.id, 99);
        expect(copied.title, 'Test');
      });

      test('updates only messageCount', () {
        final original = ConversationInfo(
          id: 1,
          title: 'Test',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          messageCount: 0,
        );

        final copied = original.copyWith(messageCount: 100);

        expect(copied.messageCount, 100);
      });

      test('updates only lastMessage', () {
        final original = ConversationInfo(
          id: 1,
          title: 'Test',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        final copied = original.copyWith(lastMessage: 'Hello');

        expect(copied.lastMessage, 'Hello');
      });
    });

    group('equality', () {
      test('equal conversations are equal', () {
        final conv1 = ConversationInfo(
          id: 1,
          title: 'Test',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          messageCount: 5,
          lastMessage: 'Hello',
        );

        final conv2 = ConversationInfo(
          id: 1,
          title: 'Test',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          messageCount: 5,
          lastMessage: 'Hello',
        );

        expect(conv1, conv2);
        expect(conv1.hashCode, conv2.hashCode);
      });

      test('different id makes unequal', () {
        final conv1 = ConversationInfo(
          id: 1,
          title: 'Test',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        final conv2 = ConversationInfo(
          id: 2,
          title: 'Test',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(conv1, isNot(conv2));
      });

      test('different title makes unequal', () {
        final conv1 = ConversationInfo(
          id: 1,
          title: 'Test 1',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        final conv2 = ConversationInfo(
          id: 1,
          title: 'Test 2',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(conv1, isNot(conv2));
      });

      test('different messageCount makes unequal', () {
        final conv1 = ConversationInfo(
          id: 1,
          title: 'Test',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          messageCount: 5,
        );

        final conv2 = ConversationInfo(
          id: 1,
          title: 'Test',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          messageCount: 10,
        );

        expect(conv1, isNot(conv2));
      });

      test('different lastMessage makes unequal', () {
        final conv1 = ConversationInfo(
          id: 1,
          title: 'Test',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          lastMessage: 'Hello',
        );

        final conv2 = ConversationInfo(
          id: 1,
          title: 'Test',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          lastMessage: 'Goodbye',
        );

        expect(conv1, isNot(conv2));
      });

      test('null vs non-null lastMessage makes unequal', () {
        final conv1 = ConversationInfo(
          id: 1,
          title: 'Test',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          lastMessage: null,
        );

        final conv2 = ConversationInfo(
          id: 1,
          title: 'Test',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          lastMessage: 'Hello',
        );

        expect(conv1, isNot(conv2));
      });
    });

    group('props', () {
      test('props contains all fields', () {
        final conv = ConversationInfo(
          id: 1,
          title: 'Test',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
          messageCount: 5,
          lastMessage: 'Hello',
        );

        expect(conv.props, [
          1,
          'Test',
          testCreatedAt,
          testUpdatedAt,
          5,
          'Hello',
        ]);
      });

      test('props handles null lastMessage', () {
        final conv = ConversationInfo(
          id: 1,
          title: 'Test',
          createdAt: testCreatedAt,
          updatedAt: testUpdatedAt,
        );

        expect(conv.props.last, isNull);
      });
    });
  });
}
