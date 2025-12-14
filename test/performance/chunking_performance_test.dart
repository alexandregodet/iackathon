import 'package:flutter_test/flutter_test.dart';

import 'package:iackathon/data/datasources/rag_service.dart';

/// Performance tests for RAG chunking algorithm
void main() {
  group('Chunking Performance', () {
    test('chunks large document within acceptable time', () {
      // Generate a large document (~100KB)
      final largeText = List.generate(
        1000,
        (i) =>
            'This is paragraph number $i. It contains multiple sentences. '
            'Each sentence has some content to simulate real text. '
            'The RAG system needs to handle documents of various sizes.',
      ).join('\n\n');

      final stopwatch = Stopwatch()..start();

      final chunks = _chunkText(
        text: largeText,
        documentId: 1,
        chunkSize: 500,
        overlap: 50,
      );

      stopwatch.stop();

      // Should complete in under 100ms
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
      expect(chunks.length, greaterThan(100));

      // ignore: avoid_print
      print(
        'Chunked ${largeText.length} chars into ${chunks.length} chunks '
        'in ${stopwatch.elapsedMilliseconds}ms',
      );
    });

    test('handles very large document', () {
      // Generate a very large document (~1MB)
      final veryLargeText = List.generate(
        10000,
        (i) =>
            'Paragraph $i with substantial content that simulates '
            'real-world document text including technical details. ',
      ).join(' ');

      final stopwatch = Stopwatch()..start();

      final chunks = _chunkText(
        text: veryLargeText,
        documentId: 1,
        chunkSize: 500,
        overlap: 50,
      );

      stopwatch.stop();

      // Should complete in under 500ms even for large docs
      expect(stopwatch.elapsedMilliseconds, lessThan(500));

      // ignore: avoid_print
      print(
        'Chunked ${veryLargeText.length} chars into ${chunks.length} chunks '
        'in ${stopwatch.elapsedMilliseconds}ms',
      );
    });

    test('chunk size affects number of chunks predictably', () {
      final text = 'Word ' * 1000; // 5000 characters

      final chunks100 = _chunkText(
        text: text,
        documentId: 1,
        chunkSize: 100,
        overlap: 0,
      );
      final chunks500 = _chunkText(
        text: text,
        documentId: 1,
        chunkSize: 500,
        overlap: 0,
      );
      final chunks1000 = _chunkText(
        text: text,
        documentId: 1,
        chunkSize: 1000,
        overlap: 0,
      );

      // Smaller chunks = more chunks
      expect(chunks100.length, greaterThan(chunks500.length));
      expect(chunks500.length, greaterThan(chunks1000.length));
    });

    test('overlap increases coverage', () {
      final text = 'Word ' * 100;

      final chunksNoOverlap = _chunkText(
        text: text,
        documentId: 1,
        chunkSize: 50,
        overlap: 0,
      );

      final chunksWithOverlap = _chunkText(
        text: text,
        documentId: 1,
        chunkSize: 50,
        overlap: 25,
      );

      // More overlap means more chunks (redundancy for context)
      expect(
        chunksWithOverlap.length,
        greaterThanOrEqualTo(chunksNoOverlap.length),
      );
    });
  });

  group('Token Estimation Performance', () {
    test('estimates tokens quickly for long messages', () {
      final longMessages = List.generate(
        100,
        (i) => _MockMessage(
          content: 'This is message $i with some content. ' * 50,
          thinkingContent: i % 5 == 0 ? 'Thinking about this...' : null,
        ),
      );

      final stopwatch = Stopwatch()..start();

      final tokens = _estimateTokens(longMessages);

      stopwatch.stop();

      // Should complete in under 10ms
      expect(stopwatch.elapsedMilliseconds, lessThan(10));
      expect(tokens, greaterThan(0));

      // ignore: avoid_print
      print(
        'Estimated $tokens tokens from ${longMessages.length} messages '
        'in ${stopwatch.elapsedMilliseconds}ms',
      );
    });
  });
}

// Helper function that mimics RagService.chunkText logic
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

// Helper class for token estimation test
class _MockMessage {
  final String content;
  final String? thinkingContent;

  _MockMessage({required this.content, this.thinkingContent});
}

// Helper function that mimics ChatState token estimation
int _estimateTokens(List<_MockMessage> messages) {
  int totalChars = 0;
  for (final msg in messages) {
    totalChars += msg.content.length;
    if (msg.thinkingContent != null) {
      totalChars += msg.thinkingContent!.length;
    }
  }
  return (totalChars / 4).ceil();
}
