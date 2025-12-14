import 'package:flutter_test/flutter_test.dart';

import 'package:iackathon/core/errors/app_errors.dart';

void main() {
  group('NetworkError', () {
    test('noConnection creates correct error', () {
      final error = NetworkError.noConnection();

      expect(error.code, 'NETWORK_NO_CONNECTION');
      expect(error.message, 'No network connection available');
      expect(error.userMessage, contains('Pas de connexion internet'));
      expect(error.isRecoverable, true);
      expect(error.originalError, isNull);
      expect(error.stackTrace, isNull);
    });

    test('noConnection with original error', () {
      final original = Exception('Original error');
      final stack = StackTrace.current;
      final error = NetworkError.noConnection(original: original, stack: stack);

      expect(error.originalError, original);
      expect(error.stackTrace, stack);
    });

    test('downloadFailed creates correct error', () {
      final error = NetworkError.downloadFailed(modelName: 'Gemma');

      expect(error.code, 'NETWORK_DOWNLOAD_FAILED');
      expect(error.message, contains('Gemma'));
      expect(error.userMessage, contains('Echec du telechargement'));
      expect(error.isRecoverable, true);
    });

    test('downloadFailed without model name', () {
      final error = NetworkError.downloadFailed();

      expect(error.userMessage, contains('du modele'));
    });

    test('timeout creates correct error', () {
      final error = NetworkError.timeout();

      expect(error.code, 'NETWORK_TIMEOUT');
      expect(error.message, 'Network request timed out');
      expect(error.userMessage, contains('expire'));
      expect(error.isRecoverable, true);
    });

    test('toString returns formatted string', () {
      final error = NetworkError.noConnection();

      expect(error.toString(), '[NETWORK_NO_CONNECTION] No network connection available');
    });
  });

  group('ModelError', () {
    test('notSelected creates correct error', () {
      final error = ModelError.notSelected();

      expect(error.code, 'MODEL_NOT_SELECTED');
      expect(error.message, 'No model selected');
      expect(error.userMessage, contains('Aucun modele selectionne'));
      expect(error.isRecoverable, true);
    });

    test('notLoaded creates correct error', () {
      final error = ModelError.notLoaded();

      expect(error.code, 'MODEL_NOT_LOADED');
      expect(error.message, 'Model is not loaded into memory');
      expect(error.userMessage, contains('pas charge'));
      expect(error.isRecoverable, true);
    });

    test('notInstalled creates correct error', () {
      final error = ModelError.notInstalled();

      expect(error.code, 'MODEL_NOT_INSTALLED');
      expect(error.message, 'Model is not installed on device');
      expect(error.userMessage, contains('pas installe'));
      expect(error.isRecoverable, true);
    });

    test('loadingFailed creates correct error', () {
      final original = Exception('Load failed');
      final error = ModelError.loadingFailed(original: original);

      expect(error.code, 'MODEL_LOADING_FAILED');
      expect(error.message, 'Failed to load model into memory');
      expect(error.userMessage, contains('Echec du chargement'));
      expect(error.originalError, original);
      expect(error.isRecoverable, true);
    });

    test('inferenceTimeout creates correct error', () {
      final error = ModelError.inferenceTimeout();

      expect(error.code, 'MODEL_INFERENCE_TIMEOUT');
      expect(error.message, 'Model inference timed out');
      expect(error.userMessage, contains('ne repond pas'));
      expect(error.isRecoverable, true);
    });

    test('inferenceError creates correct error', () {
      final error = ModelError.inferenceError();

      expect(error.code, 'MODEL_INFERENCE_ERROR');
      expect(error.message, 'Error during model inference');
      expect(error.userMessage, contains('Erreur lors de la generation'));
      expect(error.isRecoverable, true);
    });

    test('corrupted creates non-recoverable error', () {
      final error = ModelError.corrupted();

      expect(error.code, 'MODEL_CORRUPTED');
      expect(error.message, 'Model file appears corrupted');
      expect(error.userMessage, contains('corrompu'));
      expect(error.isRecoverable, false);
    });

    test('isRecoverable is false only for corrupted', () {
      expect(ModelError.notSelected().isRecoverable, true);
      expect(ModelError.notLoaded().isRecoverable, true);
      expect(ModelError.notInstalled().isRecoverable, true);
      expect(ModelError.loadingFailed().isRecoverable, true);
      expect(ModelError.inferenceTimeout().isRecoverable, true);
      expect(ModelError.inferenceError().isRecoverable, true);
      expect(ModelError.corrupted().isRecoverable, false);
    });
  });

  group('RagError', () {
    test('embedderNotLoaded creates correct error', () {
      final error = RagError.embedderNotLoaded();

      expect(error.code, 'RAG_EMBEDDER_NOT_LOADED');
      expect(error.message, 'Embedder model is not loaded');
      expect(error.userMessage, contains('embedding'));
      expect(error.isRecoverable, true);
    });

    test('embedderNotInstalled creates correct error', () {
      final error = RagError.embedderNotInstalled();

      expect(error.code, 'RAG_EMBEDDER_NOT_INSTALLED');
      expect(error.message, 'Embedder model is not installed');
      expect(error.userMessage, contains('pas installe'));
      expect(error.isRecoverable, true);
    });

    test('pdfExtractionFailed creates correct error', () {
      final error = RagError.pdfExtractionFailed(fileName: 'document.pdf');

      expect(error.code, 'RAG_PDF_EXTRACTION_FAILED');
      expect(error.message, contains('document.pdf'));
      expect(error.userMessage, contains('document.pdf'));
      expect(error.isRecoverable, true);
    });

    test('pdfExtractionFailed without filename', () {
      final error = RagError.pdfExtractionFailed();

      expect(error.userMessage, contains('le fichier'));
    });

    test('embeddingFailed creates correct error', () {
      final error = RagError.embeddingFailed();

      expect(error.code, 'RAG_EMBEDDING_FAILED');
      expect(error.message, 'Failed to generate embedding');
      expect(error.userMessage, contains('traitement'));
      expect(error.isRecoverable, true);
    });

    test('serviceNotReady creates correct error', () {
      final error = RagError.serviceNotReady();

      expect(error.code, 'RAG_SERVICE_NOT_READY');
      expect(error.message, 'RAG service is not ready');
      expect(error.userMessage, contains('pas pret'));
      expect(error.isRecoverable, true);
    });

    test('all RagErrors are recoverable', () {
      expect(RagError.embedderNotLoaded().isRecoverable, true);
      expect(RagError.embedderNotInstalled().isRecoverable, true);
      expect(RagError.pdfExtractionFailed().isRecoverable, true);
      expect(RagError.embeddingFailed().isRecoverable, true);
      expect(RagError.serviceNotReady().isRecoverable, true);
    });
  });

  group('StorageError', () {
    test('insufficientSpace creates correct error', () {
      final error = StorageError.insufficientSpace(requiredMb: 500);

      expect(error.code, 'STORAGE_FULL');
      expect(error.message, contains('500 MB'));
      expect(error.userMessage, contains('500 Mo'));
      expect(error.isRecoverable, false);
    });

    test('insufficientSpace without required size', () {
      final error = StorageError.insufficientSpace();

      expect(error.message, contains('Insufficient storage'));
      expect(error.userMessage, contains("de l'espace"));
    });

    test('databaseError creates correct error', () {
      final original = Exception('DB error');
      final error = StorageError.databaseError(original: original);

      expect(error.code, 'STORAGE_DATABASE_ERROR');
      expect(error.message, 'Database operation failed');
      expect(error.userMessage, contains('base de donnees'));
      expect(error.originalError, original);
      expect(error.isRecoverable, true);
    });

    test('isRecoverable is false for insufficientSpace', () {
      expect(StorageError.insufficientSpace().isRecoverable, false);
    });

    test('isRecoverable is true for databaseError', () {
      expect(StorageError.databaseError().isRecoverable, true);
    });
  });

  group('AppError properties', () {
    test('all errors implement Exception', () {
      expect(NetworkError.noConnection(), isA<Exception>());
      expect(ModelError.notLoaded(), isA<Exception>());
      expect(RagError.embedderNotLoaded(), isA<Exception>());
      expect(StorageError.databaseError(), isA<Exception>());
    });

    test('all errors are AppError', () {
      expect(NetworkError.noConnection(), isA<AppError>());
      expect(ModelError.notLoaded(), isA<AppError>());
      expect(RagError.embedderNotLoaded(), isA<AppError>());
      expect(StorageError.databaseError(), isA<AppError>());
    });

    test('stackTrace is preserved', () {
      final stack = StackTrace.current;
      final error = ModelError.notLoaded(stack: stack);

      expect(error.stackTrace, stack);
    });

    test('originalError is preserved', () {
      final original = FormatException('Test');
      final error = RagError.embeddingFailed(original: original);

      expect(error.originalError, original);
    });
  });
}
