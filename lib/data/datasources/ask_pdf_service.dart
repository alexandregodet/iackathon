import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:injectable/injectable.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:pdfx/pdfx.dart';
import 'package:read_pdf_text/read_pdf_text.dart';

import '../../core/errors/app_errors.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/connectivity_checker.dart';
import '../../core/utils/storage_permission_helper.dart';
import '../../domain/entities/pdf_source.dart';
import 'rag_service.dart';

/// Chunk with page metadata for Ask PDF feature
class PageChunk {
  final String id;
  final String content;
  final int pageNumber;
  final int chunkIndex;

  const PageChunk({
    required this.id,
    required this.content,
    required this.pageNumber,
    required this.chunkIndex,
  });
}

/// Search result with source information
class SearchResult {
  final String content;
  final int pageNumber;
  final double score;
  final String chunkId;

  const SearchResult({
    required this.content,
    required this.pageNumber,
    required this.score,
    required this.chunkId,
  });
}

/// Service dedicated to "Ask my PDF" feature
/// Handles PDF processing, embedding, and search with source tracking
@singleton
class AskPdfService {
  EmbeddingModel? _embedder;
  EmbedderState _state = EmbedderState.notInstalled;
  double _downloadProgress = 0.0;
  String? _errorMessage;
  bool _vectorStoreInitialized = false;

  // Current PDF session data
  PdfDocument? _currentDocument;
  String? _currentFilePath;
  String? _currentFileName;
  final List<PageChunk> _currentChunks = [];
  final Map<int, Uint8List> _pageImageCache = {};
  final Map<String, SearchResult> _chunkMetadata = {};

  final _stateController = StreamController<EmbedderState>.broadcast();
  Stream<EmbedderState> get stateStream => _stateController.stream;

  final _progressController = StreamController<double>.broadcast();
  Stream<double> get progressStream => _progressController.stream;

  EmbedderState get state => _state;
  double get downloadProgress => _downloadProgress;
  String? get errorMessage => _errorMessage;
  bool get isReady => _state == EmbedderState.ready && _vectorStoreInitialized;

  // Session getters
  bool get hasDocument => _currentDocument != null;
  String? get currentFileName => _currentFileName;
  String? get currentFilePath => _currentFilePath;
  int get pageCount => _currentDocument?.pagesCount ?? 0;
  int get chunkCount => _currentChunks.length;

  // Embedding model info
  static const String _cdnBaseUrl =
      'https://storage.kast.maintenance-coach.com/cdn/ai_models';
  static const _embeddingModelUrl = '$_cdnBaseUrl/embeddinggemma-300m.tflite';
  static const _tokenizerUrl = '$_cdnBaseUrl/embeddinggemma-sentencepiece.model';
  static const _embeddingModelFilename = 'embeddinggemma-300m.tflite';
  static const _tokenizerFilename = 'embeddinggemma-sentencepiece.model';

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

  /// Tente d'installer l'embedder depuis les fichiers locaux
  /// Retourne true si l'installation locale a reussi
  Future<bool> _tryInstallFromLocal() async {
    AppLogger.info(
      'Tentative d\'installation locale de l\'embedder',
      'AskPdfService',
    );

    // Verifier la permission de stockage
    final hasPermission =
        await StoragePermissionHelper.requestStoragePermission();
    if (!hasPermission) {
      AppLogger.info(
        'Permission de stockage non accordee, fallback CDN',
        'AskPdfService',
      );
      return false;
    }

    // Verifier si les fichiers existent
    final modelPath =
        StoragePermissionHelper.getLocalModelPath(_embeddingModelFilename);
    final tokenizerPath =
        StoragePermissionHelper.getLocalModelPath(_tokenizerFilename);

    final modelFile = File(modelPath);
    final tokenizerFile = File(tokenizerPath);

    if (!await modelFile.exists()) {
      AppLogger.info(
        'Fichier embedder local non trouve: $modelPath, fallback CDN',
        'AskPdfService',
      );
      return false;
    }

    if (!await tokenizerFile.exists()) {
      AppLogger.info(
        'Fichier tokenizer local non trouve: $tokenizerPath, fallback CDN',
        'AskPdfService',
      );
      return false;
    }

    try {
      AppLogger.info(
        'Installation embedder depuis fichiers locaux',
        'AskPdfService',
      );

      await FlutterGemma.installEmbedder()
          .modelFromFile(modelPath)
          .tokenizerFromFile(tokenizerPath)
          .install();

      AppLogger.info(
        'Installation locale de l\'embedder reussie',
        'AskPdfService',
      );
      return true;
    } catch (e) {
      AppLogger.warning(
        'Echec installation locale embedder, fallback CDN: $e',
        'AskPdfService',
      );
      return false;
    }
  }

  Future<void> downloadEmbedder({
    void Function(double)? onProgress,
    bool tryLocalFirst = true,
  }) async {
    AppLogger.info('Demarrage installation embedder', 'AskPdfService');

    // Etape 1: Tenter l'installation locale si demandee
    if (tryLocalFirst) {
      final installedLocally = await _tryInstallFromLocal();
      if (installedLocally) {
        _state = EmbedderState.installed;
        _stateController.add(_state);
        return;
      }
    }

    // Etape 2: Fallback sur le telechargement CDN
    AppLogger.info('Telechargement embedder depuis CDN', 'AskPdfService');

    final hasConnection = await ConnectivityChecker.hasConnection();
    if (!hasConnection) {
      final error = NetworkError.noConnection();
      AppLogger.logAppError(error, 'AskPdfService');
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
            _downloadProgress = progress.toDouble() / 100.0 * 0.8;
            _progressController.add(_downloadProgress);
            onProgress?.call(_downloadProgress);
          })
          .withTokenizerProgress((progress) {
            _downloadProgress = 0.8 + (progress.toDouble() / 100.0 * 0.2);
            _progressController.add(_downloadProgress);
            onProgress?.call(_downloadProgress);
          })
          .install();

      AppLogger.info('Telechargement embedder termine', 'AskPdfService');
      _state = EmbedderState.installed;
      _stateController.add(_state);
    } catch (e, stack) {
      AppLogger.error(
        'Echec telechargement embedder',
        tag: 'AskPdfService',
        error: e,
        stackTrace: stack,
      );
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
    AppLogger.info('Loading embedder', 'AskPdfService');

    try {
      _state = EmbedderState.loading;
      _stateController.add(_state);

      _embedder = await FlutterGemma.getActiveEmbedder();
      await _initializeVectorStore();

      AppLogger.info('Embedder loaded successfully', 'AskPdfService');
      _state = EmbedderState.ready;
      _stateController.add(_state);
    } catch (e, stack) {
      AppLogger.error(
        'Embedder loading failed',
        tag: 'AskPdfService',
        error: e,
        stackTrace: stack,
      );
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
    final vectorDbPath = p.join(dbFolder.path, 'askpdf_vectors.sqlite');
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

  /// Loads a PDF document and processes it for Q&A
  Future<PdfDocumentInfo> loadPdf(
    String filePath, {
    void Function(int current, int total)? onProgress,
  }) async {
    final fileName = filePath.split('/').last.split('\\').last;
    AppLogger.info('Loading PDF: $fileName', 'AskPdfService');

    try {
      // Clear previous session
      await clearSession();

      // Open PDF for image extraction
      _currentDocument = await PdfDocument.openFile(filePath);
      _currentFilePath = filePath;
      _currentFileName = fileName;

      final totalPages = _currentDocument!.pagesCount;
      AppLogger.debug('PDF has $totalPages pages', 'AskPdfService');

      // Extract text from PDF (using read_pdf_text for better text extraction)
      final fullText = await ReadPdfText.getPDFtext(filePath);

      // Create chunks with page estimation
      final chunks = _chunkTextWithPages(
        text: fullText,
        totalPages: totalPages,
      );
      _currentChunks.addAll(chunks);

      // Add chunks to vector store
      for (int i = 0; i < chunks.length; i++) {
        final chunk = chunks[i];
        await _addChunkToVectorStore(chunk);

        // Store metadata for retrieval
        _chunkMetadata[chunk.id] = SearchResult(
          content: chunk.content,
          pageNumber: chunk.pageNumber,
          score: 0.0,
          chunkId: chunk.id,
        );

        onProgress?.call(i + 1, chunks.length);
      }

      AppLogger.info(
        'PDF processed: $totalPages pages, ${chunks.length} chunks',
        'AskPdfService',
      );

      return PdfDocumentInfo(
        name: fileName,
        filePath: filePath,
        pageCount: totalPages,
        chunkCount: chunks.length,
        loadedAt: DateTime.now(),
      );
    } catch (e, stack) {
      AppLogger.error(
        'Error loading PDF',
        tag: 'AskPdfService',
        error: e,
        stackTrace: stack,
      );

      if (e is AppError) rethrow;

      throw RagError.pdfExtractionFailed(
        fileName: fileName,
        original: e,
        stack: stack,
      );
    }
  }

  /// Chunks text and estimates page numbers
  List<PageChunk> _chunkTextWithPages({
    required String text,
    required int totalPages,
    int chunkSize = 500,
    int overlap = 50,
  }) {
    final chunks = <PageChunk>[];

    if (text.isEmpty) return chunks;

    // Clean and normalize text
    final cleanedText = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    final totalLength = cleanedText.length;
    final charsPerPage = totalLength ~/ totalPages;

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
        // Estimate page number based on position
        final midPoint = start + (end - start) ~/ 2;
        final estimatedPage = charsPerPage > 0
            ? (midPoint ~/ charsPerPage).clamp(0, totalPages - 1) + 1
            : 1;

        chunks.add(
          PageChunk(
            id: 'askpdf_chunk_$chunkIndex',
            content: chunkContent,
            pageNumber: estimatedPage,
            chunkIndex: chunkIndex,
          ),
        );
        chunkIndex++;
      }

      // Move start with overlap
      start = end - overlap;
      if (start <= 0 && end >= cleanedText.length) break;
      if (end >= cleanedText.length) break;
    }

    return chunks;
  }

  Future<void> _addChunkToVectorStore(PageChunk chunk) async {
    if (!isReady) {
      throw RagError.serviceNotReady();
    }

    final embedding = await _embedder!.generateEmbedding(chunk.content);

    await FlutterGemmaPlugin.instance.addDocumentWithEmbedding(
      id: chunk.id,
      content: chunk.content,
      embedding: embedding,
      metadata: '{"page": ${chunk.pageNumber}, "index": ${chunk.chunkIndex}}',
    );
  }

  // ============== SEARCH & RETRIEVAL ==============

  /// Searches for relevant chunks and returns sources with page info
  Future<List<PdfSource>> searchWithSources({
    required String query,
    int topK = 3,
    double threshold = 0.5,
  }) async {
    if (!isReady) {
      throw RagError.serviceNotReady();
    }

    final results = await FlutterGemmaPlugin.instance.searchSimilar(
      query: query,
      topK: topK,
      threshold: threshold,
    );

    AppLogger.debug(
      'Search found ${results.length} results',
      'AskPdfService',
    );

    final sources = <PdfSource>[];

    for (int i = 0; i < results.length; i++) {
      final result = results[i];
      final metadata = _chunkMetadata[result.id];

      // Get page image if available
      Uint8List? pageImage;
      if (metadata != null && _currentDocument != null) {
        pageImage = await _getPageImage(metadata.pageNumber);
      }

      sources.add(
        PdfSource(
          id: result.id,
          sourceIndex: i,
          content: result.content,
          pageNumber: metadata?.pageNumber ?? 1,
          similarityScore: result.similarity,
          imageBytes: pageImage,
        ),
      );
    }

    return sources;
  }

  /// Builds an augmented prompt with source citations
  Future<(String prompt, List<PdfSource> sources)> buildAugmentedPromptWithSources({
    required String userQuery,
    int topK = 3,
    double threshold = 0.5,
  }) async {
    final sources = await searchWithSources(
      query: userQuery,
      topK: topK,
      threshold: threshold,
    );

    if (sources.isEmpty) {
      return (userQuery, <PdfSource>[]);
    }

    // Build context with citations
    final contextParts = <String>[];
    for (final source in sources) {
      contextParts.add(
        '${source.citationLabel} (Page ${source.pageNumber}): ${source.content}',
      );
    }

    final context = contextParts.join('\n\n');

    final prompt = '''Tu es un assistant qui repond aux questions en te basant sur le document PDF fourni.

[SOURCES DU DOCUMENT]
$context
[FIN DES SOURCES]

INSTRUCTIONS:
- Reponds a la question en te basant UNIQUEMENT sur les sources ci-dessus
- Cite tes sources en utilisant les numeros entre crochets [1], [2], etc.
- Chaque affirmation doit etre suivie de sa source
- Si l'information n'est pas dans les sources, dis-le clairement
- Reponds en francais

Question: $userQuery''';

    return (prompt, sources);
  }

  /// Gets or renders a page image
  Future<Uint8List?> _getPageImage(int pageNumber, {double scale = 1.5}) async {
    if (_currentDocument == null) return null;

    // Check cache
    if (_pageImageCache.containsKey(pageNumber)) {
      return _pageImageCache[pageNumber];
    }

    try {
      final page = await _currentDocument!.getPage(pageNumber);
      final pageImage = await page.render(
        width: page.width * scale,
        height: page.height * scale,
        format: PdfPageImageFormat.png,
        backgroundColor: '#FFFFFF',
      );
      await page.close();

      if (pageImage != null) {
        _pageImageCache[pageNumber] = pageImage.bytes;
        return pageImage.bytes;
      }

      return null;
    } catch (e) {
      AppLogger.warning('Failed to render page $pageNumber', 'AskPdfService');
      return null;
    }
  }

  /// Renders a specific page as image
  Future<Uint8List?> renderPage(int pageNumber, {double scale = 2.0}) async {
    return _getPageImage(pageNumber, scale: scale);
  }

  // ============== SESSION MANAGEMENT ==============

  /// Clears the current PDF session
  Future<void> clearSession() async {
    AppLogger.debug('Clearing PDF session', 'AskPdfService');

    // Close PDF document
    if (_currentDocument != null) {
      await _currentDocument!.close();
      _currentDocument = null;
    }

    _currentFilePath = null;
    _currentFileName = null;
    _currentChunks.clear();
    _pageImageCache.clear();
    _chunkMetadata.clear();

    // Clear vector store for this session
    // Note: This clears all vectors, which is fine for session-only mode
    try {
      // Re-initialize vector store (this effectively clears it)
      _vectorStoreInitialized = false;
      await _initializeVectorStore();
    } catch (e) {
      AppLogger.warning('Could not clear vector store', 'AskPdfService');
    }
  }

  void dispose() {
    clearSession();
    _stateController.close();
    _progressController.close();
  }
}
