import 'package:flutter_gemma/flutter_gemma.dart';

class GemmaModelInfo {
  final String id;
  final String name;
  final String description;
  final String url;
  final String filename;
  final ModelType modelType;
  final ModelFileType fileType;
  final int sizeInMb;
  final bool isMultimodal;
  final bool requiresAuth;

  const GemmaModelInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.url,
    required this.filename,
    required this.modelType,
    required this.fileType,
    required this.sizeInMb,
    this.isMultimodal = false,
    this.requiresAuth = false,
  });

  String get sizeLabel {
    if (sizeInMb >= 1000) {
      return '${(sizeInMb / 1000).toStringAsFixed(1)} Go';
    }
    return '$sizeInMb Mo';
  }
}

class AvailableModels {
  static const String _cdnBaseUrl = 'https://storage.kast.maintenance-coach.com/cdn/ai_models';

  static const gemma3_1b = GemmaModelInfo(
    id: 'gemma3_1b',
    name: 'Gemma 3 1B',
    description: 'Modele leger et rapide, texte uniquement',
    url: '$_cdnBaseUrl/gemma3-1b-it-int4.task',
    filename: 'gemma3-1b-it-int4.task',
    modelType: ModelType.gemmaIt,
    fileType: ModelFileType.task,
    sizeInMb: 900,
    isMultimodal: false,
    requiresAuth: false,
  );

  static const gemma3NanoE2b = GemmaModelInfo(
    id: 'gemma3n_e2b',
    name: 'Gemma 3 Nano E2B',
    description: 'Multimodal (texte + vision), 2B params effectifs',
    url: '$_cdnBaseUrl/gemma-3n-E2B-it-int4.task',
    filename: 'gemma-3n-E2B-it-int4.task',
    modelType: ModelType.gemmaIt,
    fileType: ModelFileType.task,
    sizeInMb: 2000,
    isMultimodal: true,
    requiresAuth: false,
  );

  static const gemma3NanoE4b = GemmaModelInfo(
    id: 'gemma3n_e4b',
    name: 'Gemma 3 Nano E4B',
    description: 'Multimodal (texte + vision), 4B params effectifs',
    url: '$_cdnBaseUrl/gemma-3n-E4B-it-int4.task',
    filename: 'gemma-3n-E4B-it-int4.task',
    modelType: ModelType.gemmaIt,
    fileType: ModelFileType.task,
    sizeInMb: 4000,
    isMultimodal: true,
    requiresAuth: false,
  );

  static List<GemmaModelInfo> get all => [
        gemma3_1b,
        gemma3NanoE2b,
        gemma3NanoE4b,
      ];

  static List<GemmaModelInfo> get multimodal =>
      all.where((m) => m.isMultimodal).toList();

  static List<GemmaModelInfo> get textOnly =>
      all.where((m) => !m.isMultimodal).toList();

  static GemmaModelInfo? getById(String id) {
    try {
      return all.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }
}
