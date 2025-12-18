import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// Represents a source chunk from a PDF document with metadata
class PdfSource extends Equatable {
  final String id;
  final int sourceIndex;
  final String content;
  final int pageNumber;
  final double similarityScore;
  final Uint8List? imageBytes;
  final String? imageDescription;

  const PdfSource({
    required this.id,
    required this.sourceIndex,
    required this.content,
    required this.pageNumber,
    this.similarityScore = 0.0,
    this.imageBytes,
    this.imageDescription,
  });

  bool get hasImage => imageBytes != null;

  /// Creates a display label like "[1]" for inline citations
  String get citationLabel => '[${sourceIndex + 1}]';

  PdfSource copyWith({
    String? id,
    int? sourceIndex,
    String? content,
    int? pageNumber,
    double? similarityScore,
    Uint8List? imageBytes,
    String? imageDescription,
  }) {
    return PdfSource(
      id: id ?? this.id,
      sourceIndex: sourceIndex ?? this.sourceIndex,
      content: content ?? this.content,
      pageNumber: pageNumber ?? this.pageNumber,
      similarityScore: similarityScore ?? this.similarityScore,
      imageBytes: imageBytes ?? this.imageBytes,
      imageDescription: imageDescription ?? this.imageDescription,
    );
  }

  @override
  List<Object?> get props => [
        id,
        sourceIndex,
        content,
        pageNumber,
        similarityScore,
        imageBytes,
        imageDescription,
      ];
}

/// Represents a chat message with associated PDF sources
class PdfChatMessage extends Equatable {
  final String id;
  final MessageType type;
  final String content;
  final DateTime timestamp;
  final bool isStreaming;
  final List<PdfSource> sources;
  final String? thinkingContent;
  final bool isThinkingComplete;

  const PdfChatMessage({
    required this.id,
    required this.type,
    required this.content,
    required this.timestamp,
    this.isStreaming = false,
    this.sources = const [],
    this.thinkingContent,
    this.isThinkingComplete = false,
  });

  bool get hasSources => sources.isNotEmpty;
  bool get hasThinking => thinkingContent != null && thinkingContent!.isNotEmpty;

  PdfChatMessage copyWith({
    String? id,
    MessageType? type,
    String? content,
    DateTime? timestamp,
    bool? isStreaming,
    List<PdfSource>? sources,
    String? thinkingContent,
    bool? isThinkingComplete,
  }) {
    return PdfChatMessage(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isStreaming: isStreaming ?? this.isStreaming,
      sources: sources ?? this.sources,
      thinkingContent: thinkingContent ?? this.thinkingContent,
      isThinkingComplete: isThinkingComplete ?? this.isThinkingComplete,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        content,
        timestamp,
        isStreaming,
        sources,
        thinkingContent,
        isThinkingComplete,
      ];
}

enum MessageType { user, assistant }

/// Represents a PDF document loaded in session
class PdfDocumentInfo extends Equatable {
  final String name;
  final String filePath;
  final int pageCount;
  final int chunkCount;
  final DateTime loadedAt;
  final List<Uint8List> pageImages;

  const PdfDocumentInfo({
    required this.name,
    required this.filePath,
    required this.pageCount,
    required this.chunkCount,
    required this.loadedAt,
    this.pageImages = const [],
  });

  bool get hasPageImages => pageImages.isNotEmpty;

  @override
  List<Object?> get props => [
        name,
        filePath,
        pageCount,
        chunkCount,
        loadedAt,
        pageImages,
      ];
}
