import 'package:equatable/equatable.dart';

import '../../../domain/entities/checklist.dart';
import '../../../domain/entities/checklist_response.dart';

class AiAnalysisResult {
  final List<Map<String, dynamic>> tags;
  final Map<String, dynamic>? defectBbox;
  final String description;

  const AiAnalysisResult({
    required this.tags,
    this.defectBbox,
    required this.description,
  });

  factory AiAnalysisResult.fromJson(Map<String, dynamic> json) {
    return AiAnalysisResult(
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      defectBbox: json['defect_bbox'] as Map<String, dynamic>?,
      description: json['description'] as String? ?? '',
    );
  }
}

class ChecklistState extends Equatable {
  final Checklist? checklist;
  final int currentSectionIndex;
  final Map<String, QuestionResponse> responses;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final String serialNumber;
  final bool isSubmitted;
  final Set<String> analyzingQuestions;
  final Map<String, AiAnalysisResult> aiAnalysisResults;

  const ChecklistState({
    this.checklist,
    this.currentSectionIndex = 0,
    this.responses = const {},
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.serialNumber = '',
    this.isSubmitted = false,
    this.analyzingQuestions = const {},
    this.aiAnalysisResults = const {},
  });

  ChecklistSection? get currentSection {
    if (checklist == null || checklist!.answers.sections.isEmpty) return null;
    if (currentSectionIndex >= checklist!.answers.sections.length) return null;
    return checklist!.answers.sections[currentSectionIndex];
  }

  int get totalSections => checklist?.answers.sections.length ?? 0;

  int get totalPages => totalSections + 1;

  bool get isOnContextPage => currentSectionIndex == 0;

  bool get canGoNext => currentSectionIndex < totalPages - 1;

  bool get canGoPrevious => currentSectionIndex > 0;

  bool get canStartChecklist => serialNumber.isNotEmpty;

  double get progressPercent {
    if (checklist == null) return 0.0;
    final allQuestions = checklist!.answers.sections
        .expand((s) => s.questions)
        .toList();
    if (allQuestions.isEmpty) return 0.0;

    final answeredCount = allQuestions.where((q) {
      final response = responses[q.uuid];
      return response != null &&
          response.response != null &&
          response.response!.isNotEmpty;
    }).length;

    return answeredCount / allQuestions.length;
  }

  int get answeredQuestionsCount {
    if (checklist == null) return 0;
    final allQuestions = checklist!.answers.sections
        .expand((s) => s.questions)
        .toList();
    return allQuestions.where((q) {
      final response = responses[q.uuid];
      return response != null &&
          response.response != null &&
          response.response!.isNotEmpty;
    }).length;
  }

  int get totalQuestionsCount {
    if (checklist == null) return 0;
    return checklist!.answers.sections
        .expand((s) => s.questions)
        .length;
  }

  ChecklistState copyWith({
    Checklist? checklist,
    int? currentSectionIndex,
    Map<String, QuestionResponse>? responses,
    bool? isLoading,
    bool? isSaving,
    String? error,
    String? serialNumber,
    bool? isSubmitted,
    Set<String>? analyzingQuestions,
    Map<String, AiAnalysisResult>? aiAnalysisResults,
  }) {
    return ChecklistState(
      checklist: checklist ?? this.checklist,
      currentSectionIndex: currentSectionIndex ?? this.currentSectionIndex,
      responses: responses ?? this.responses,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: error,
      serialNumber: serialNumber ?? this.serialNumber,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      analyzingQuestions: analyzingQuestions ?? this.analyzingQuestions,
      aiAnalysisResults: aiAnalysisResults ?? this.aiAnalysisResults,
    );
  }

  @override
  List<Object?> get props => [
        checklist,
        currentSectionIndex,
        responses,
        isLoading,
        isSaving,
        error,
        serialNumber,
        isSubmitted,
        analyzingQuestions,
        aiAnalysisResults,
      ];
}
