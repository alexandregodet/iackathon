import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:injectable/injectable.dart';

import '../../core/errors/app_errors.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/connectivity_checker.dart';
import '../../core/utils/storage_permission_helper.dart';
import '../../domain/entities/gemma_model_info.dart';

enum GemmaModelState {
  notInstalled,
  downloading,
  installed,
  loading,
  ready,
  error,
}

class GemmaStreamResponse {
  final String? thinkingChunk;
  final String? textChunk;
  final bool isThinkingPhase;

  const GemmaStreamResponse({
    this.thinkingChunk,
    this.textChunk,
    this.isThinkingPhase = false,
  });
}

@singleton
class GemmaService {
  InferenceModel? _model;
  InferenceChat? _chat;
  GemmaModelState _state = GemmaModelState.notInstalled;
  double _downloadProgress = 0.0;
  String? _errorMessage;
  GemmaModelInfo? _currentModel;
  String? _huggingFaceToken;
  String? _systemPrompt;
  bool _systemPromptSent = false;

  GemmaModelState get state => _state;
  double get downloadProgress => _downloadProgress;
  String? get errorMessage => _errorMessage;
  bool get isReady => _state == GemmaModelState.ready;
  GemmaModelInfo? get currentModel => _currentModel;
  bool get isMultimodal => _currentModel?.isMultimodal ?? false;
  bool get supportsThinking => _currentModel?.supportsThinking ?? false;
  String? get systemPrompt => _systemPrompt;

  void setSystemPrompt(String? prompt) {
    _systemPrompt = prompt?.trim().isEmpty == true ? null : prompt?.trim();
  }

  final _stateController = StreamController<GemmaModelState>.broadcast();
  Stream<GemmaModelState> get stateStream => _stateController.stream;

  final _progressController = StreamController<double>.broadcast();
  Stream<double> get progressStream => _progressController.stream;

  void setHuggingFaceToken(String? token) {
    _huggingFaceToken = token;
  }

  Future<void> checkModelStatus(GemmaModelInfo modelInfo) async {
    _currentModel = modelInfo;
    final isInstalled = await FlutterGemma.isModelInstalled(modelInfo.filename);
    _state =
        isInstalled ? GemmaModelState.installed : GemmaModelState.notInstalled;
    _stateController.add(_state);
  }

  /// Tente d'installer le modele depuis un fichier local
  /// Retourne true si l'installation locale a reussi
  Future<bool> _tryInstallFromLocal(GemmaModelInfo modelInfo) async {
    AppLogger.info(
      'Tentative d\'installation locale pour ${modelInfo.name}',
      'GemmaService',
    );

    // Verifier la permission de stockage
    final hasPermission =
        await StoragePermissionHelper.requestStoragePermission();
    if (!hasPermission) {
      AppLogger.info(
        'Permission de stockage non accordee, fallback CDN',
        'GemmaService',
      );
      return false;
    }

    // Verifier si le fichier existe
    final localPath =
        StoragePermissionHelper.getLocalModelPath(modelInfo.filename);
    final file = File(localPath);

    if (!await file.exists()) {
      AppLogger.info(
        'Fichier local non trouve: $localPath, fallback CDN',
        'GemmaService',
      );
      return false;
    }

    try {
      AppLogger.info(
        'Installation depuis fichier local: $localPath',
        'GemmaService',
      );

      await FlutterGemma.installModel(
        modelType: modelInfo.modelType,
        fileType: modelInfo.fileType,
      ).fromFile(localPath).install();

      AppLogger.info(
        'Installation locale reussie pour ${modelInfo.name}',
        'GemmaService',
      );
      return true;
    } catch (e) {
      AppLogger.warning(
        'Echec installation locale, fallback CDN: $e',
        'GemmaService',
      );
      return false;
    }
  }

  Future<void> downloadModel(
    GemmaModelInfo modelInfo, {
    void Function(double)? onProgress,
    String? token,
    bool tryLocalFirst = true,
  }) async {
    _currentModel = modelInfo;

    // Etape 1: Tenter l'installation locale si demandee
    if (tryLocalFirst) {
      final installedLocally = await _tryInstallFromLocal(modelInfo);
      if (installedLocally) {
        _state = GemmaModelState.installed;
        _stateController.add(_state);
        return;
      }
    }

    // Etape 2: Fallback sur le telechargement CDN
    AppLogger.info(
      'Demarrage du telechargement de ${modelInfo.name}',
      'GemmaService',
    );

    // Verifier la connectivite avant de telecharger
    final hasConnection = await ConnectivityChecker.hasConnection();
    if (!hasConnection) {
      final error = NetworkError.noConnection();
      AppLogger.logAppError(error, 'GemmaService');
      _state = GemmaModelState.error;
      _errorMessage = error.userMessage;
      _stateController.add(_state);
      throw error;
    }

    try {
      _state = GemmaModelState.downloading;
      _stateController.add(_state);

      final authToken = token ?? _huggingFaceToken;

      var builder = FlutterGemma.installModel(
        modelType: modelInfo.modelType,
        fileType: modelInfo.fileType,
      ).fromNetwork(
        modelInfo.url,
        token: modelInfo.requiresAuth ? authToken : null,
      );

      builder = builder.withProgress((progress) {
        _downloadProgress = progress.toDouble() / 100.0;
        _progressController.add(_downloadProgress);
        onProgress?.call(_downloadProgress);
      });

      await builder.install();

      AppLogger.info(
        'Telechargement termine pour ${modelInfo.name}',
        'GemmaService',
      );
      _state = GemmaModelState.installed;
      _stateController.add(_state);
    } catch (e, stack) {
      AppLogger.error(
        'Echec du telechargement',
        tag: 'GemmaService',
        error: e,
        stackTrace: stack,
      );
      _state = GemmaModelState.error;

      if (e is AppError) {
        _errorMessage = e.userMessage;
        rethrow;
      }

      final error = NetworkError.downloadFailed(
        modelName: modelInfo.name,
        original: e,
        stack: stack,
      );
      _errorMessage = error.userMessage;
      throw error;
    }
  }

  Future<void> loadModel([GemmaModelInfo? modelInfo]) async {
    AppLogger.info('Chargement du modele en memoire', 'GemmaService');

    try {
      if (modelInfo != null) {
        _currentModel = modelInfo;
      }

      if (_currentModel == null) {
        throw ModelError.notSelected();
      }

      _state = GemmaModelState.loading;
      _stateController.add(_state);

      // First, ensure the model is set as active by re-installing from local cache
      // This is needed because getActiveModel requires the model to be "set"
      // even if the file already exists on disk
      await _ensureModelActive(_currentModel!);

      _model = await FlutterGemma.getActiveModel(
        maxTokens: 8192,
        supportImage: _currentModel!.isMultimodal,
        maxNumImages: _currentModel!.isMultimodal ? 1 : null,
      );

      _chat = await _model!.createChat(
        modelType: _currentModel!.modelType,
        supportImage: _currentModel!.isMultimodal,
        isThinking: _currentModel!.supportsThinking,
      );

      AppLogger.info('Modele charge avec succes', 'GemmaService');
      _state = GemmaModelState.ready;
      _stateController.add(_state);
    } catch (e, stack) {
      AppLogger.error(
        'Echec du chargement du modele',
        tag: 'GemmaService',
        error: e,
        stackTrace: stack,
      );
      _state = GemmaModelState.error;

      if (e is AppError) {
        _errorMessage = e.userMessage;
        rethrow;
      }

      final error = ModelError.loadingFailed(original: e, stack: stack);
      _errorMessage = error.userMessage;
      throw error;
    }
  }

  /// Ensures the model is set as active in FlutterGemma
  /// This is needed because isModelInstalled only checks if file exists,
  /// but getActiveModel requires the model to be properly registered
  Future<void> _ensureModelActive(GemmaModelInfo modelInfo) async {
    AppLogger.info('Activation du modele ${modelInfo.name}', 'GemmaService');

    // Try to find and install from local cache first
    final localPath =
        StoragePermissionHelper.getLocalModelPath(modelInfo.filename);
    final localFile = File(localPath);

    if (await localFile.exists()) {
      AppLogger.info('Installation depuis cache local: $localPath', 'GemmaService');
      await FlutterGemma.installModel(
        modelType: modelInfo.modelType,
        fileType: modelInfo.fileType,
      ).fromFile(localPath).install();
      return;
    }

    // Try flutter_gemma's internal cache
    final isInstalled = await FlutterGemma.isModelInstalled(modelInfo.filename);
    if (isInstalled) {
      AppLogger.info(
        'Modele deja installe, re-activation depuis cache interne',
        'GemmaService',
      );
      // Re-install to set as active (uses cached file)
      await FlutterGemma.installModel(
        modelType: modelInfo.modelType,
        fileType: modelInfo.fileType,
      ).fromNetwork(modelInfo.url).install();
    }
  }

  Stream<String> generateResponse(
    String userMessage, {
    Uint8List? imageBytes,
  }) async* {
    if (_chat == null || !isReady) {
      final error = ModelError.notLoaded();
      AppLogger.logAppError(error, 'GemmaService');
      throw error;
    }

    AppLogger.debug(
      'Generation de reponse pour: ${userMessage.substring(0, min(50, userMessage.length))}...',
      'GemmaService',
    );

    String finalMessage = userMessage;
    if (_systemPrompt != null && !_systemPromptSent) {
      finalMessage =
          '[Instructions systeme]\n$_systemPrompt\n[Fin des instructions]\n\n$userMessage';
      _systemPromptSent = true;
    }

    try {
      if (imageBytes != null && isMultimodal) {
        await _chat!.addQuery(
          Message.withImage(
            text: finalMessage,
            imageBytes: imageBytes,
            isUser: true,
          ),
        );
      } else {
        await _chat!.addQuery(Message.text(text: finalMessage, isUser: true));
      }

      await for (final response in _chat!.generateChatResponseAsync()) {
        if (response is TextResponse) {
          yield response.token;
        }
      }
      AppLogger.debug('Generation terminee', 'GemmaService');
    } catch (e, stack) {
      AppLogger.error(
        'Erreur pendant la generation',
        tag: 'GemmaService',
        error: e,
        stackTrace: stack,
      );
      if (e is AppError) rethrow;
      throw ModelError.inferenceError(original: e, stack: stack);
    }
  }

  Stream<GemmaStreamResponse> generateResponseWithThinking(
    String userMessage, {
    Uint8List? imageBytes,
  }) async* {
    if (_chat == null || !isReady) {
      final error = ModelError.notLoaded();
      AppLogger.logAppError(error, 'GemmaService');
      throw error;
    }

    AppLogger.debug(
      'Generation avec reflexion pour: ${userMessage.substring(0, min(50, userMessage.length))}...',
      'GemmaService',
    );

    String finalMessage = userMessage;
    if (_systemPrompt != null && !_systemPromptSent) {
      finalMessage =
          '[Instructions systeme]\n$_systemPrompt\n[Fin des instructions]\n\n$userMessage';
      _systemPromptSent = true;
    }

    try {
      if (imageBytes != null && isMultimodal) {
        await _chat!.addQuery(
          Message.withImage(
            text: finalMessage,
            imageBytes: imageBytes,
            isUser: true,
          ),
        );
      } else {
        await _chat!.addQuery(Message.text(text: finalMessage, isUser: true));
      }

      await for (final response in _chat!.generateChatResponseAsync()) {
        if (response is ThinkingResponse) {
          yield GemmaStreamResponse(
            thinkingChunk: response.content,
            isThinkingPhase: true,
          );
        } else if (response is TextResponse) {
          yield GemmaStreamResponse(
            textChunk: response.token,
            isThinkingPhase: false,
          );
        }
      }
      AppLogger.debug('Generation avec reflexion terminee', 'GemmaService');
    } catch (e, stack) {
      AppLogger.error(
        'Erreur pendant la generation',
        tag: 'GemmaService',
        error: e,
        stackTrace: stack,
      );
      if (e is AppError) rethrow;
      throw ModelError.inferenceError(original: e, stack: stack);
    }
  }

  Future<String> generateResponseSync(String userMessage) async {
    if (_chat == null || !isReady) {
      final error = ModelError.notLoaded();
      AppLogger.logAppError(error, 'GemmaService');
      throw error;
    }

    try {
      await _chat!.addQuery(Message.text(text: userMessage, isUser: true));
      final response = await _chat!.generateChatResponse();
      if (response is TextResponse) {
        return response.token;
      }
      return '';
    } catch (e, stack) {
      AppLogger.error(
        'Erreur pendant la generation sync',
        tag: 'GemmaService',
        error: e,
        stackTrace: stack,
      );
      if (e is AppError) rethrow;
      throw ModelError.inferenceError(original: e, stack: stack);
    }
  }

  Future<void> clearChat() async {
    _systemPromptSent = false;
    if (_model != null && _currentModel != null) {
      _chat = await _model!.createChat(
        modelType: _currentModel!.modelType,
        supportImage: _currentModel!.isMultimodal,
        isThinking: _currentModel!.supportsThinking,
      );
    }
  }

  Future<void> unloadModel() async {
    _model?.close();
    _model = null;
    _chat = null;
    _state = GemmaModelState.installed;
    _stateController.add(_state);
  }

  void dispose() {
    _model?.close();
    _stateController.close();
    _progressController.close();
  }
}
