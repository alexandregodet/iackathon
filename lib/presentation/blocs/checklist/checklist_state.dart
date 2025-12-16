import 'package:equatable/equatable.dart';

import '../../../domain/entities/checklist.dart';
import '../../../domain/entities/checklist_response.dart';

class ChecklistState extends Equatable {
  final Checklist? checklist;
  final int currentSectionIndex;
  final Map<String, QuestionResponse> responses;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final String serialNumber;
  final bool isSubmitted;

  const ChecklistState({
    this.checklist,
    this.currentSectionIndex = 0,
    this.responses = const {},
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.serialNumber = '',
    this.isSubmitted = false,
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
      ];
}
