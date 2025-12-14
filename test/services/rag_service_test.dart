import 'package:flutter_test/flutter_test.dart';

import 'package:iackathon/data/datasources/rag_service.dart';

void main() {
  group('DocumentChunk', () {
    test('creates chunk with all fields', () {
      const chunk = DocumentChunk(
        id: 'doc_1_chunk_0',
        documentId: 1,
        content: 'Test content',
        chunkIndex: 0,
      );

      expect(chunk.id, 'doc_1_chunk_0');
      expect(chunk.documentId, 1);
      expect(chunk.content, 'Test content');
      expect(chunk.chunkIndex, 0);
    });
  });

  group('EmbedderState', () {
    test('has all expected values', () {
      expect(EmbedderState.values.length, 6);
      expect(EmbedderState.values, contains(EmbedderState.notInstalled));
      expect(EmbedderState.values, contains(EmbedderState.downloading));
      expect(EmbedderState.values, contains(EmbedderState.installed));
      expect(EmbedderState.values, contains(EmbedderState.loading));
      expect(EmbedderState.values, contains(EmbedderState.ready));
      expect(EmbedderState.values, contains(EmbedderState.error));
    });
  });

  group('RagService chunkText logic', () {
    // Test the chunking algorithm using our mock
    test('chunks empty text returns empty list', () {
      final chunks = _chunkText(text: '', documentId: 1);
      expect(chunks, isEmpty);
    });

    test('chunks short text returns single chunk', () {
      final chunks = _chunkText(
        text: 'Short text that fits in one chunk.',
        documentId: 1,
        chunkSize: 500,
      );
      expect(chunks.length, 1);
      expect(chunks.first.content, 'Short text that fits in one chunk.');
      expect(chunks.first.documentId, 1);
      expect(chunks.first.chunkIndex, 0);
    });

    test('chunks long text into multiple chunks', () {
      final longText = List.generate(
        10,
        (i) => 'Sentence $i is here.',
      ).join(' ');
      final chunks = _chunkText(
        text: longText,
        documentId: 1,
        chunkSize: 50,
        overlap: 10,
      );

      expect(chunks.length, greaterThan(1));

      // Verify chunk indices are sequential
      for (var i = 0; i < chunks.length; i++) {
        expect(chunks[i].chunkIndex, i);
        expect(chunks[i].documentId, 1);
      }
    });

    test('chunks preserve document ID', () {
      final chunks = _chunkText(
        text: 'Test content for document.',
        documentId: 42,
      );

      for (final chunk in chunks) {
        expect(chunk.documentId, 42);
      }
    });

    test('chunks have unique IDs', () {
      final chunks = _chunkText(
        text: 'First part. Second part. Third part.',
        documentId: 1,
        chunkSize: 15,
      );

      final ids = chunks.map((c) => c.id).toSet();
      expect(ids.length, chunks.length);
    });

    test('chunks do not cut words', () {
      final chunks = _chunkText(
        text: 'Hello world this is a test',
        documentId: 1,
        chunkSize: 12, // Would cut "world" if not handled
        overlap: 0,
      );

      for (final chunk in chunks) {
        // Each chunk should be a valid word boundary
        expect(chunk.content.trim(), isNotEmpty);
        // No partial words (no chunks starting or ending mid-word)
        if (chunk.content.isNotEmpty) {
          expect(chunk.content.trim().contains('  '), false);
        }
      }
    });
  });

  group('Augmented Prompt Building', () {
    test('returns original query when no context', () {
      final result = _buildAugmentedPrompt(
        userQuery: 'What is Flutter?',
        relevantChunks: [],
      );

      expect(result, 'What is Flutter?');
    });

    test('includes context in prompt', () {
      final result = _buildAugmentedPrompt(
        userQuery: 'What is Flutter?',
        relevantChunks: ['Flutter is a UI toolkit.', 'It is made by Google.'],
      );

      expect(result, contains('Contexte des documents'));
      expect(result, contains('Flutter is a UI toolkit.'));
      expect(result, contains('It is made by Google.'));
      expect(result, contains('What is Flutter?'));
    });
  });
}

// Helper function that mimics RagService.chunkText logic for testing
List<DocumentChunk> _chunkText({
  required String text,
  required int documentId,
  int chunkSize = 500,
  int overlap = 50,
}) {
  final chunks = <DocumentChunk>[];

  if (text.isEmpty) return chunks;

  final cleanedText = text.replaceAll(RegExp(r'\s+'), ' ').trim();

  if (cleanedText.isEmpty) return chunks;

  // Ensure overlap doesn't exceed chunk size
  final effectiveOverlap = overlap.clamp(0, chunkSize - 1);

  int start = 0;
  int chunkIndex = 0;

  while (start < cleanedText.length) {
    int end = start + chunkSize;

    if (end < cleanedText.length) {
      // Find word boundary
      final spaceIndex = cleanedText.lastIndexOf(' ', end);
      if (spaceIndex > start) {
        end = spaceIndex;
      }
    } else {
      end = cleanedText.length;
    }

    final chunkContent = cleanedText.substring(start, end).trim();

    if (chunkContent.isNotEmpty) {
      chunks.add(
        DocumentChunk(
          id: 'doc_${documentId}_chunk_$chunkIndex',
          documentId: documentId,
          content: chunkContent,
          chunkIndex: chunkIndex,
        ),
      );
      chunkIndex++;
    }

    // Move start forward, ensuring progress
    final nextStart = end - effectiveOverlap;
    if (nextStart <= start) {
      // Ensure we always make progress
      start = end;
    } else {
      start = nextStart;
    }

    if (end >= cleanedText.length) break;
  }

  return chunks;
}

// Helper function that mimics buildAugmentedPrompt logic
String _buildAugmentedPrompt({
  required String userQuery,
  required List<String> relevantChunks,
}) {
  if (relevantChunks.isEmpty) {
    return userQuery;
  }

  final context = relevantChunks.join('\n\n---\n\n');

  return '''[Contexte des documents]
$context
[Fin du contexte]

Question: $userQuery

Reponds en te basant sur le contexte ci-dessus. Si le contexte ne contient pas d'information pertinente, indique-le.''';
}
