import 'package:flutter_test/flutter_test.dart';

import 'package:iackathon/domain/entities/document_info.dart';

void main() {
  group('DocumentInfo', () {
    final testDate = DateTime(2024, 1, 1, 12, 0);

    test('creates document with required fields', () {
      final doc = DocumentInfo(
        id: 1,
        name: 'test.pdf',
        filePath: '/path/to/test.pdf',
        totalChunks: 10,
        createdAt: testDate,
      );

      expect(doc.id, 1);
      expect(doc.name, 'test.pdf');
      expect(doc.filePath, '/path/to/test.pdf');
      expect(doc.totalChunks, 10);
      expect(doc.createdAt, testDate);
      expect(doc.lastUsedAt, null);
      expect(doc.isActive, false);
    });

    test('creates document with optional fields', () {
      final lastUsed = DateTime(2024, 1, 15);
      final doc = DocumentInfo(
        id: 2,
        name: 'document.pdf',
        filePath: '/documents/document.pdf',
        totalChunks: 25,
        createdAt: testDate,
        lastUsedAt: lastUsed,
        isActive: true,
      );

      expect(doc.lastUsedAt, lastUsed);
      expect(doc.isActive, true);
    });

    test('copyWith preserves unchanged values', () {
      final original = DocumentInfo(
        id: 1,
        name: 'test.pdf',
        filePath: '/path/to/test.pdf',
        totalChunks: 10,
        createdAt: testDate,
        isActive: true,
      );

      final copied = original.copyWith(totalChunks: 20);

      expect(copied.id, 1);
      expect(copied.name, 'test.pdf');
      expect(copied.filePath, '/path/to/test.pdf');
      expect(copied.totalChunks, 20);
      expect(copied.createdAt, testDate);
      expect(copied.isActive, true);
    });

    test('copyWith updates all fields', () {
      final original = DocumentInfo(
        id: 1,
        name: 'test.pdf',
        filePath: '/path/to/test.pdf',
        totalChunks: 10,
        createdAt: testDate,
      );

      final newDate = DateTime(2024, 2, 1);
      final lastUsed = DateTime(2024, 2, 15);

      final copied = original.copyWith(
        id: 2,
        name: 'new.pdf',
        filePath: '/new/path.pdf',
        totalChunks: 30,
        createdAt: newDate,
        lastUsedAt: lastUsed,
        isActive: true,
      );

      expect(copied.id, 2);
      expect(copied.name, 'new.pdf');
      expect(copied.filePath, '/new/path.pdf');
      expect(copied.totalChunks, 30);
      expect(copied.createdAt, newDate);
      expect(copied.lastUsedAt, lastUsed);
      expect(copied.isActive, true);
    });

    test('equality works correctly', () {
      final doc1 = DocumentInfo(
        id: 1,
        name: 'test.pdf',
        filePath: '/path/to/test.pdf',
        totalChunks: 10,
        createdAt: testDate,
      );

      final doc2 = DocumentInfo(
        id: 1,
        name: 'test.pdf',
        filePath: '/path/to/test.pdf',
        totalChunks: 10,
        createdAt: testDate,
      );

      final doc3 = DocumentInfo(
        id: 2,
        name: 'test.pdf',
        filePath: '/path/to/test.pdf',
        totalChunks: 10,
        createdAt: testDate,
      );

      expect(doc1, doc2);
      expect(doc1, isNot(doc3));
    });
  });
}
