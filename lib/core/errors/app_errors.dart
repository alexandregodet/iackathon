/// Classe de base pour toutes les erreurs de l'application
sealed class AppError implements Exception {
  final String code;
  final String message;
  final String userMessage;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppError({
    required this.code,
    required this.message,
    required this.userMessage,
    this.originalError,
    this.stackTrace,
  });

  bool get isRecoverable;

  @override
  String toString() => '[$code] $message';
}

/// Erreurs liees au reseau
class NetworkError extends AppError {
  const NetworkError._({
    required super.code,
    required super.message,
    required super.userMessage,
    super.originalError,
    super.stackTrace,
  });

  @override
  bool get isRecoverable => true;

  factory NetworkError.noConnection({dynamic original, StackTrace? stack}) {
    return NetworkError._(
      code: 'NETWORK_NO_CONNECTION',
      message: 'No network connection available',
      userMessage:
          'Pas de connexion internet. Verifiez votre connexion et reessayez.',
      originalError: original,
      stackTrace: stack,
    );
  }

  factory NetworkError.downloadFailed({
    String? modelName,
    dynamic original,
    StackTrace? stack,
  }) {
    final name = modelName ?? 'du modele';
    return NetworkError._(
      code: 'NETWORK_DOWNLOAD_FAILED',
      message: 'Download failed for model: $modelName',
      userMessage:
          'Echec du telechargement $name. Verifiez votre connexion et reessayez.',
      originalError: original,
      stackTrace: stack,
    );
  }

  factory NetworkError.timeout({dynamic original, StackTrace? stack}) {
    return NetworkError._(
      code: 'NETWORK_TIMEOUT',
      message: 'Network request timed out',
      userMessage: 'La connexion a expire. Reessayez plus tard.',
      originalError: original,
      stackTrace: stack,
    );
  }
}

/// Erreurs liees au modele LLM
class ModelError extends AppError {
  const ModelError._({
    required super.code,
    required super.message,
    required super.userMessage,
    super.originalError,
    super.stackTrace,
  });

  @override
  bool get isRecoverable => code != 'MODEL_CORRUPTED';

  factory ModelError.notSelected({StackTrace? stack}) {
    return ModelError._(
      code: 'MODEL_NOT_SELECTED',
      message: 'No model selected',
      userMessage: 'Aucun modele selectionne. Choisissez un modele d\'abord.',
      stackTrace: stack,
    );
  }

  factory ModelError.notLoaded({StackTrace? stack}) {
    return ModelError._(
      code: 'MODEL_NOT_LOADED',
      message: 'Model is not loaded into memory',
      userMessage:
          'Le modele n\'est pas charge. Chargez le modele pour commencer.',
      stackTrace: stack,
    );
  }

  factory ModelError.notInstalled({StackTrace? stack}) {
    return ModelError._(
      code: 'MODEL_NOT_INSTALLED',
      message: 'Model is not installed on device',
      userMessage: 'Le modele n\'est pas installe. Telechargez-le d\'abord.',
      stackTrace: stack,
    );
  }

  factory ModelError.loadingFailed({dynamic original, StackTrace? stack}) {
    return ModelError._(
      code: 'MODEL_LOADING_FAILED',
      message: 'Failed to load model into memory',
      userMessage:
          'Echec du chargement du modele. Memoire insuffisante ou modele corrompu.',
      originalError: original,
      stackTrace: stack,
    );
  }

  factory ModelError.inferenceTimeout({StackTrace? stack}) {
    return ModelError._(
      code: 'MODEL_INFERENCE_TIMEOUT',
      message: 'Model inference timed out',
      userMessage:
          'Le modele ne repond pas. Essayez un message plus court ou redemarrez l\'application.',
      stackTrace: stack,
    );
  }

  factory ModelError.inferenceError({dynamic original, StackTrace? stack}) {
    return ModelError._(
      code: 'MODEL_INFERENCE_ERROR',
      message: 'Error during model inference',
      userMessage:
          'Erreur lors de la generation. Reessayez ou effacez la conversation.',
      originalError: original,
      stackTrace: stack,
    );
  }

  factory ModelError.corrupted({dynamic original, StackTrace? stack}) {
    return ModelError._(
      code: 'MODEL_CORRUPTED',
      message: 'Model file appears corrupted',
      userMessage:
          'Le fichier du modele est corrompu. Supprimez-le et retelechargez.',
      originalError: original,
      stackTrace: stack,
    );
  }
}

/// Erreurs liees au RAG (documents et embeddings)
class RagError extends AppError {
  const RagError._({
    required super.code,
    required super.message,
    required super.userMessage,
    super.originalError,
    super.stackTrace,
  });

  @override
  bool get isRecoverable => true;

  factory RagError.embedderNotLoaded({StackTrace? stack}) {
    return RagError._(
      code: 'RAG_EMBEDDER_NOT_LOADED',
      message: 'Embedder model is not loaded',
      userMessage:
          'Le modele d\'embedding n\'est pas charge. Chargez-le d\'abord.',
      stackTrace: stack,
    );
  }

  factory RagError.embedderNotInstalled({StackTrace? stack}) {
    return RagError._(
      code: 'RAG_EMBEDDER_NOT_INSTALLED',
      message: 'Embedder model is not installed',
      userMessage:
          'Le modele d\'embedding n\'est pas installe. Telechargez-le d\'abord.',
      stackTrace: stack,
    );
  }

  factory RagError.pdfExtractionFailed({
    String? fileName,
    dynamic original,
    StackTrace? stack,
  }) {
    final name = fileName ?? 'le fichier';
    return RagError._(
      code: 'RAG_PDF_EXTRACTION_FAILED',
      message: 'Failed to extract text from PDF: $fileName',
      userMessage:
          'Impossible de lire $name. Le fichier est peut-etre protege ou corrompu.',
      originalError: original,
      stackTrace: stack,
    );
  }

  factory RagError.embeddingFailed({dynamic original, StackTrace? stack}) {
    return RagError._(
      code: 'RAG_EMBEDDING_FAILED',
      message: 'Failed to generate embedding',
      userMessage: 'Erreur lors du traitement du document. Reessayez.',
      originalError: original,
      stackTrace: stack,
    );
  }

  factory RagError.serviceNotReady({StackTrace? stack}) {
    return RagError._(
      code: 'RAG_SERVICE_NOT_READY',
      message: 'RAG service is not ready',
      userMessage: 'Le service RAG n\'est pas pret. Chargez l\'embedder.',
      stackTrace: stack,
    );
  }
}

/// Erreurs liees au stockage
class StorageError extends AppError {
  const StorageError._({
    required super.code,
    required super.message,
    required super.userMessage,
    super.originalError,
    super.stackTrace,
  });

  @override
  bool get isRecoverable => code != 'STORAGE_FULL';

  factory StorageError.insufficientSpace({int? requiredMb, StackTrace? stack}) {
    final space = requiredMb != null
        ? 'au moins $requiredMb Mo'
        : 'de l\'espace';
    return StorageError._(
      code: 'STORAGE_FULL',
      message:
          'Insufficient storage space${requiredMb != null ? ', need $requiredMb MB' : ''}',
      userMessage: 'Espace de stockage insuffisant. Liberez $space.',
      stackTrace: stack,
    );
  }

  factory StorageError.databaseError({dynamic original, StackTrace? stack}) {
    return StorageError._(
      code: 'STORAGE_DATABASE_ERROR',
      message: 'Database operation failed',
      userMessage: 'Erreur de base de donnees. Redemarrez l\'application.',
      originalError: original,
      stackTrace: stack,
    );
  }
}
