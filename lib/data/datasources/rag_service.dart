import 'dart:async';

import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:read_pdf_text/read_pdf_text.dart';

import '../../core/errors/app_errors.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/connectivity_checker.dart';

enum EmbedderState {
  notInstalled,
  downloading,
  installed,
  loading,
  ready,
  error,
}

class DocumentChunk {
  final String id;
  final int documentId;
  final String content;
  final int chunkIndex;

  const DocumentChunk({
    required this.id,
    required this.documentId,
    required this.content,
    required this.chunkIndex,
  });
}

@singleton
class RagService {
  EmbeddingModel? _embedder;
  EmbedderState _state = EmbedderState.notInstalled;
  double _downloadProgress = 0.0;
  String? _errorMessage;
  bool _vectorStoreInitialized = false;

  final _stateController = StreamController<EmbedderState>.broadcast();
  Stream<EmbedderState> get stateStream => _stateController.stream;

  final _progressController = StreamController<double>.broadcast();
  Stream<double> get progressStream => _progressController.stream;

  EmbedderState get state => _state;
  double get downloadProgress => _downloadProgress;
  String? get errorMessage => _errorMessage;
  bool get isReady => _state == EmbedderState.ready && _vectorStoreInitialized;

  // Embedding model info (EmbeddingGemma 300M mixed-precision)
  static const String _cdnBaseUrl = 'https://storage.kast.maintenance-coach.com/cdn/ai_models';
  static const _embeddingModelUrl = '$_cdnBaseUrl/embeddinggemma-300m.tflite';
  static const _tokenizerUrl = '$_cdnBaseUrl/embeddinggemma-sentencepiece.model';

  Future<void> checkEmbedderStatus() async {
    try {
      final hasActiveEmbedder = FlutterGemma.hasActiveEmbedder();
      if (hasActiveEmbedder) {
        _state = EmbedderState.installed;
      } else {
        _state = EmbedderState.notInstalled;
      }
      _stateController.add(_state);
    } catch (e) {
      _state = EmbedderState.notInstalled;
      _stateController.add(_state);
    }
  }

  Future<void> downloadEmbedder({
    void Function(double)? onProgress,
  }) async {
    AppLogger.info('Demarrage du telechargement de l\'embedder', 'RagService');

    // Verifier la connectivite avant de telecharger
    final hasConnection = await ConnectivityChecker.hasConnection();
    if (!hasConnection) {
      final error = NetworkError.noConnection();
      AppLogger.logAppError(error, 'RagService');
      _state = EmbedderState.error;
      _errorMessage = error.userMessage;
      _stateController.add(_state);
      throw error;
    }

    try {
      _state = EmbedderState.downloading;
      _downloadProgress = 0.0;
      _stateController.add(_state);

      await FlutterGemma.installEmbedder()
          .modelFromNetwork(_embeddingModelUrl)
          .tokenizerFromNetwork(_tokenizerUrl)
          .withModelProgress((progress) {
            _downloadProgress = progress.toDouble() / 100.0 * 0.8; // 80% for model
            _progressController.add(_downloadProgress);
            onProgress?.call(_downloadProgress);
          })
          .withTokenizerProgress((progress) {
            _downloadProgress = 0.8 + (progress.toDouble() / 100.0 * 0.2); // 20% for tokenizer
            _progressController.add(_downloadProgress);
            onProgress?.call(_downloadProgress);
          })
          .install();

      AppLogger.info('Telechargement de l\'embedder termine', 'RagService');
      _state = EmbedderState.installed;
      _stateController.add(_state);
    } catch (e, stack) {
      AppLogger.error('Echec du telechargement de l\'embedder', tag: 'RagService', error: e, stackTrace: stack);
      _state = EmbedderState.error;

      if (e is AppError) {
        _errorMessage = e.userMessage;
        rethrow;
      }

      final error = NetworkError.downloadFailed(
        modelName: 'embedder',
        original: e,
        stack: stack,
      );
      _errorMessage = error.userMessage;
      throw error;
    }
  }

  Future<void> loadEmbedder() async {
    AppLogger.info('Chargement de l\'embedder en memoire', 'RagService');

    try {
      _state = EmbedderState.loading;
      _stateController.add(_state);

      _embedder = await FlutterGemma.getActiveEmbedder();
      await _initializeVectorStore();

      AppLogger.info('Embedder charge avec succes', 'RagService');
      _state = EmbedderState.ready;
      _stateController.add(_state);
    } catch (e, stack) {
      AppLogger.error('Echec du chargement de l\'embedder', tag: 'RagService', error: e, stackTrace: stack);
      _state = EmbedderState.error;

      if (e is AppError) {
        _errorMessage = e.userMessage;
        rethrow;
      }

      final error = RagError.embedderNotLoaded(stack: stack);
      _errorMessage = error.userMessage;
      throw error;
    }
  }

  Future<void> _initializeVectorStore() async {
    if (_vectorStoreInitialized) return;

    final dbFolder = await getApplicationDocumentsDirectory();
    final vectorDbPath = p.join(dbFolder.path, 'iackathon_vectors.sqlite');
    await FlutterGemmaPlugin.instance.initializeVectorStore(vectorDbPath);
    _vectorStoreInitialized = true;
  }

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

  // ============== PDF PROCESSING ==============

  Future<String> extractTextFromPdf(String filePath) async {
    AppLogger.debug('Extraction du texte PDF: $filePath', 'RagService');

    try {
      final text = await ReadPdfText.getPDFtext(filePath);
      AppLogger.debug('Extraction terminee: ${text.length} caracteres', 'RagService');
      return text;
    } catch (e, stack) {
      AppLogger.error('Erreur extraction PDF', tag: 'RagService', error: e, stackTrace: stack);
      final fileName = filePath.split('/').last.split('\\').last;
      throw RagError.pdfExtractionFailed(fileName: fileName, original: e, stack: stack);
    }
  }

  List<DocumentChunk> chunkText({
    required String text,
    required int documentId,
    int chunkSize = 500,
    int overlap = 50,
  }) {
    final chunks = <DocumentChunk>[];

    if (text.isEmpty) return chunks;

    // Clean and normalize text
    final cleanedText = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    int start = 0;
    int chunkIndex = 0;

    while (start < cleanedText.length) {
      int end = start + chunkSize;

      // Adjust end to not cut words
      if (end < cleanedText.length) {
        final spaceIndex = cleanedText.lastIndexOf(' ', end);
        if (spaceIndex > start) {
          end = spaceIndex;
        }
      } else {
        end = cleanedText.length;
      }

      final chunkContent = cleanedText.substring(start, end).trim();

      if (chunkContent.isNotEmpty) {
        chunks.add(DocumentChunk(
          id: 'doc_${documentId}_chunk_$chunkIndex',
          documentId: documentId,
          content: chunkContent,
          chunkIndex: chunkIndex,
        ));
        chunkIndex++;
      }

      // Move start with overlap
      start = end - overlap;
      if (start <= 0 && end >= cleanedText.length) break;
      if (end >= cleanedText.length) break;
    }

    return chunks;
  }

  // ============== EMBEDDING GENERATION ==============

  Future<List<double>> generateEmbedding(String text) async {
    if (_embedder == null) {
      final error = RagError.embedderNotLoaded();
      AppLogger.logAppError(error, 'RagService');
      throw error;
    }

    try {
      final embedding = await _embedder!.generateEmbedding(text);
      return embedding;
    } catch (e, stack) {
      AppLogger.error('Erreur generation embedding', tag: 'RagService', error: e, stackTrace: stack);
      if (e is AppError) rethrow;
      throw RagError.embeddingFailed(original: e, stack: stack);
    }
  }

  // ============== VECTOR STORE OPERATIONS ==============

  Future<void> addChunkToVectorStore(DocumentChunk chunk) async {
    if (!isReady) {
      final error = RagError.serviceNotReady();
      AppLogger.logAppError(error, 'RagService');
      throw error;
    }

    final embedding = await generateEmbedding(chunk.content);

    await FlutterGemmaPlugin.instance.addDocumentWithEmbedding(
      id: chunk.id,
      content: chunk.content,
      embedding: embedding,
      metadata: '{"document_id": ${chunk.documentId}, "chunk_index": ${chunk.chunkIndex}}',
    );
  }

  Future<void> addDocumentChunks(
    List<DocumentChunk> chunks, {
    void Function(int current, int total)? onProgress,
  }) async {
    for (int i = 0; i < chunks.length; i++) {
      await addChunkToVectorStore(chunks[i]);
      onProgress?.call(i + 1, chunks.length);
    }
  }

  Future<List<String>> searchSimilar({
    required String query,
    int topK = 3,
    double threshold = 0.5,
  }) async {
    if (!isReady) {
      final error = RagError.serviceNotReady();
      AppLogger.logAppError(error, 'RagService');
      throw error;
    }

    final results = await FlutterGemmaPlugin.instance.searchSimilar(
      query: query,
      topK: topK,
      threshold: threshold,
    );

    AppLogger.debug('Recherche similaire: ${results.length} resultats', 'RagService');
    return results.map((r) => r.content).toList();
  }

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

Reponds en te basant sur le contexte ci-dessus. Si le contexte ne contient pas d'information pertinente, indique-le.''';
  }

  Future<VectorStoreStats> getStats() async {
    return await FlutterGemmaPlugin.instance.getVectorStoreStats();
  }

  void dispose() {
    _stateController.close();
    _progressController.close();
  }
}
