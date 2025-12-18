import 'dart:typed_data';

import 'package:injectable/injectable.dart';
import 'package:pdfx/pdfx.dart';

import '../../core/errors/app_errors.dart';
import '../../core/utils/app_logger.dart';

/// Service for extracting images from PDF documents
@singleton
class PdfImageService {
  PdfDocument? _currentDocument;
  String? _currentFilePath;
  final Map<int, Uint8List> _pageImageCache = {};

  /// Opens a PDF document for image extraction
  Future<int> openDocument(String filePath) async {
    AppLogger.debug('Opening PDF for image extraction: $filePath', 'PdfImageService');

    try {
      // Close previous document if any
      await closeDocument();

      _currentDocument = await PdfDocument.openFile(filePath);
      _currentFilePath = filePath;
      _pageImageCache.clear();

      AppLogger.info(
        'PDF opened: ${_currentDocument!.pagesCount} pages',
        'PdfImageService',
      );

      return _currentDocument!.pagesCount;
    } catch (e, stack) {
      AppLogger.error(
        'Error opening PDF for images',
        tag: 'PdfImageService',
        error: e,
        stackTrace: stack,
      );
      throw RagError.pdfExtractionFailed(
        fileName: filePath.split('/').last.split('\\').last,
        original: e,
        stack: stack,
      );
    }
  }

  /// Renders a specific page as an image
  Future<Uint8List?> renderPage(int pageNumber, {double scale = 2.0}) async {
    if (_currentDocument == null) {
      AppLogger.warning('No document loaded', 'PdfImageService');
      return null;
    }

    // Check cache first
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
    } catch (e, stack) {
      AppLogger.error(
        'Error rendering page $pageNumber',
        tag: 'PdfImageService',
        error: e,
        stackTrace: stack,
      );
      return null;
    }
  }

  /// Renders all pages as thumbnails (smaller images for preview)
  Future<List<Uint8List>> renderAllThumbnails({double scale = 0.5}) async {
    if (_currentDocument == null) {
      return [];
    }

    final thumbnails = <Uint8List>[];
    final pageCount = _currentDocument!.pagesCount;

    for (int i = 1; i <= pageCount; i++) {
      try {
        final page = await _currentDocument!.getPage(i);
        final pageImage = await page.render(
          width: page.width * scale,
          height: page.height * scale,
          format: PdfPageImageFormat.png,
          backgroundColor: '#FFFFFF',
        );
        await page.close();

        if (pageImage != null) {
          thumbnails.add(pageImage.bytes);
        }
      } catch (e) {
        AppLogger.warning('Failed to render thumbnail for page $i', 'PdfImageService');
      }
    }

    return thumbnails;
  }

  /// Extracts a region from a page (for highlighting specific content)
  Future<Uint8List?> extractPageRegion({
    required int pageNumber,
    required double x,
    required double y,
    required double width,
    required double height,
    double scale = 2.0,
  }) async {
    // For now, just return the full page
    // Region extraction would require more complex image manipulation
    return renderPage(pageNumber, scale: scale);
  }

  /// Gets the page count of the current document
  int get pageCount => _currentDocument?.pagesCount ?? 0;

  /// Gets the current file path
  String? get currentFilePath => _currentFilePath;

  /// Checks if a document is loaded
  bool get hasDocument => _currentDocument != null;

  /// Closes the current document and clears cache
  Future<void> closeDocument() async {
    if (_currentDocument != null) {
      await _currentDocument!.close();
      _currentDocument = null;
      _currentFilePath = null;
      _pageImageCache.clear();
      AppLogger.debug('PDF document closed', 'PdfImageService');
    }
  }

  /// Clears the page image cache
  void clearCache() {
    _pageImageCache.clear();
  }

  void dispose() {
    closeDocument();
  }
}
