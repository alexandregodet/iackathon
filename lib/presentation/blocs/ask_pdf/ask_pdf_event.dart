import 'package:equatable/equatable.dart';

import '../../../core/errors/app_errors.dart';
import '../../../domain/entities/pdf_source.dart';

abstract class AskPdfEvent extends Equatable {
  const AskPdfEvent();

  @override
  List<Object?> get props => [];
}

/// Initialize the Ask PDF service
class AskPdfInitialize extends AskPdfEvent {
  const AskPdfInitialize();
}

/// Download the embedding model
class AskPdfDownloadEmbedder extends AskPdfEvent {
  const AskPdfDownloadEmbedder();
}

/// Load the embedding model
class AskPdfLoadEmbedder extends AskPdfEvent {
  const AskPdfLoadEmbedder();
}

/// Select and load a PDF file
class AskPdfSelectFile extends AskPdfEvent {
  final String filePath;
  final String fileName;

  const AskPdfSelectFile({
    required this.filePath,
    required this.fileName,
  });

  @override
  List<Object?> get props => [filePath, fileName];
}

/// PDF processing progress update
class AskPdfProcessingProgress extends AskPdfEvent {
  final int current;
  final int total;

  const AskPdfProcessingProgress({
    required this.current,
    required this.total,
  });

  @override
  List<Object?> get props => [current, total];
}

/// Send a question to the AI
class AskPdfSendQuestion extends AskPdfEvent {
  final String question;

  const AskPdfSendQuestion(this.question);

  @override
  List<Object?> get props => [question];
}

/// Stream chunk received from AI
class AskPdfStreamChunk extends AskPdfEvent {
  final String chunk;

  const AskPdfStreamChunk(this.chunk);

  @override
  List<Object?> get props => [chunk];
}

/// Thinking content received
class AskPdfThinkingChunk extends AskPdfEvent {
  final String chunk;

  const AskPdfThinkingChunk(this.chunk);

  @override
  List<Object?> get props => [chunk];
}

/// Thinking phase complete
class AskPdfThinkingComplete extends AskPdfEvent {
  const AskPdfThinkingComplete();
}

/// Stream complete
class AskPdfStreamComplete extends AskPdfEvent {
  final List<PdfSource> sources;

  const AskPdfStreamComplete({this.sources = const []});

  @override
  List<Object?> get props => [sources];
}

/// Stream error
class AskPdfStreamError extends AskPdfEvent {
  final AppError error;

  const AskPdfStreamError(this.error);

  @override
  List<Object?> get props => [error];
}

/// Clear the current session
class AskPdfClearSession extends AskPdfEvent {
  const AskPdfClearSession();
}

/// Toggle source panel visibility
class AskPdfToggleSourcePanel extends AskPdfEvent {
  const AskPdfToggleSourcePanel();
}

/// Select a source to highlight
class AskPdfSelectSource extends AskPdfEvent {
  final int? sourceIndex;

  const AskPdfSelectSource(this.sourceIndex);

  @override
  List<Object?> get props => [sourceIndex];
}

/// Stop generation
class AskPdfStopGeneration extends AskPdfEvent {
  const AskPdfStopGeneration();
}
