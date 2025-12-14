import 'dart:async';

import 'package:mocktail/mocktail.dart';

import 'package:iackathon/data/datasources/rag_service.dart';

class MockRagService extends Mock implements RagService {
  EmbedderState _state = EmbedderState.ready;
  bool _vectorStoreInitialized = true;
  final List<DocumentChunk> _storedChunks = [];

  final _stateController = StreamController<EmbedderState>.broadcast();
  final _progressController = StreamController<double>.broadcast();

  @override
  EmbedderState get state => _state;

  @override
  double get downloadProgress => 1.0;

  @override
  String? get errorMessage => null;

  @override
  bool get isReady => _state == EmbedderState.ready && _vectorStoreInitialized;

  @override
  Stream<EmbedderState> get stateStream => _stateController.stream;

  @override
  Stream<double> get progressStream => _progressController.stream;

  /// Set the embedder state
  void setEmbedderState(EmbedderState newState) {
    _state = newState;
    _stateController.add(_state);
  }

  @override
  Future<void> checkEmbedderStatus() async {
    _state = EmbedderState.installed;
    _stateController.add(_state);
  }

  @override
  Future<void> downloadEmbedder({void Function(double)? onProgress}) async {
    _state = EmbedderState.downloading;
    _stateController.add(_state);

    for (var i = 0; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 10));
      onProgress?.call(i / 10);
    }

    _state = EmbedderState.installed;
    _stateController.add(_state);
  }

  @override
  Future<void> loadEmbedder() async {
    _state = EmbedderState.loading;
    _stateController.add(_state);

    await Future.delayed(const Duration(milliseconds: 50));

    _vectorStoreInitialized = true;
    _state = EmbedderState.ready;
    _stateController.add(_state);
  }

  @override
  Future<void> ensureReady() async {
    if (isReady) return;

    await checkEmbedderStatus();
    if (_state == EmbedderState.notInstalled) {
      await downloadEmbedder();
    }
    if (_state == EmbedderState.installed) {
      await loadEmbedder();
    }
  }

  @override
  Future<String> extractTextFromPdf(String filePath) async {
    // Return mock PDF content
    return '''
    This is mock PDF content extracted from the file.
    It contains several paragraphs of text that can be used for testing.
    The RAG system will chunk this content and generate embeddings.
    This allows testing the document processing pipeline without real PDFs.
    ''';
  }

  @override
  List<DocumentChunk> chunkText({
    required String text,
    required int documentId,
    int chunkSize = 500,
    int overlap = 50,
  }) {
    // Simple mock chunking
    final chunks = <DocumentChunk>[];
    final sentences = text.split('.');

    for (var i = 0; i < sentences.length; i++) {
      final content = sentences[i].trim();
      if (content.isNotEmpty) {
        chunks.add(
          DocumentChunk(
            id: 'doc_${documentId}_chunk_$i',
            documentId: documentId,
            content: content,
            chunkIndex: i,
          ),
        );
      }
    }

    return chunks;
  }

  @override
  Future<List<double>> generateEmbedding(String text) async {
    // Return mock embedding (256 dimensions)
    return List.generate(256, (i) => (i.hashCode ^ text.hashCode) / 1000000.0);
  }

  @override
  Future<void> addChunkToVectorStore(DocumentChunk chunk) async {
    _storedChunks.add(chunk);
  }

  @override
  Future<void> addDocumentChunks(
    List<DocumentChunk> chunks, {
    void Function(int current, int total)? onProgress,
  }) async {
    for (var i = 0; i < chunks.length; i++) {
      await addChunkToVectorStore(chunks[i]);
      onProgress?.call(i + 1, chunks.length);
    }
  }

  @override
  Future<List<String>> searchSimilar({
    required String query,
    int topK = 3,
    double threshold = 0.5,
  }) async {
    // Return mock search results from stored chunks
    final results = _storedChunks.take(topK).map((c) => c.content).toList();
    if (results.isEmpty) {
      return ['Mock relevant context for: $query'];
    }
    return results;
  }

  @override
  Future<String> buildAugmentedPrompt({
    required String userQuery,
    int topK = 3,
    double threshold = 0.5,
  }) async {
    final relevantChunks = await searchSimilar(
      query: userQuery,
      topK: topK,
      threshold: threshold,
    );

    if (relevantChunks.isEmpty) {
      return userQuery;
    }

    final context = relevantChunks.join('\n\n---\n\n');

    return '''[Contexte des documents]
$context
[Fin du contexte]

Question: $userQuery

Reponds en te basant sur le contexte ci-dessus.''';
  }

  @override
  void dispose() {
    _stateController.close();
    _progressController.close();
  }

  /// Clear stored chunks (for test reset)
  void clearStoredChunks() {
    _storedChunks.clear();
  }
}
