import 'package:equatable/equatable.dart';

import '../../../domain/entities/checklist_question.dart';
import '../../../domain/entities/checklist_section.dart';
import '../../../domain/entities/checklist_session.dart';

class ChecklistState extends Equatable {
  final bool isInitialized;
  final List<ChecklistSection> availableSections;
  final ChecklistSession? session;
  final String? lastLlmResponse;
  final String? generatedReport;
  final bool isProcessing;
  final String? error;

  const ChecklistState({
    this.isInitialized = false,
    this.availableSections = const [],
    this.session,
    this.lastLlmResponse,
    this.generatedReport,
    this.isProcessing = false,
    this.error,
  });

  bool get hasActiveSession => session?.isActive ?? false;

  ChecklistSection? get currentSection => session?.currentSection;

  ChecklistQuestion? get currentQuestion => session?.currentQuestion;

  double get progress => session?.progress ?? 0;

  int get progressPercentage => session?.progressPercentage ?? 0;

  int get answeredCount => session?.answeredCount ?? 0;

  int get totalQuestions => session?.totalQuestions ?? 0;

  bool get allMandatoryAnswered => session?.allMandatoryAnswered ?? false;

  ChecklistState copyWith({
    bool? isInitialized,
    List<ChecklistSection>? availableSections,
    ChecklistSession? session,
    bool clearSession = false,
    String? lastLlmResponse,
    bool clearLastLlmResponse = false,
    String? generatedReport,
    bool clearReport = false,
    bool? isProcessing,
    String? error,
    bool clearError = false,
  }) {
    return ChecklistState(
      isInitialized: isInitialized ?? this.isInitialized,
      availableSections: availableSections ?? this.availableSections,
      session: clearSession ? null : (session ?? this.session),
      lastLlmResponse: clearLastLlmResponse
          ? null
          : (lastLlmResponse ?? this.lastLlmResponse),
      generatedReport: clearReport
          ? null
          : (generatedReport ?? this.generatedReport),
      isProcessing: isProcessing ?? this.isProcessing,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [
    isInitialized,
    availableSections,
    session,
    lastLlmResponse,
    generatedReport,
    isProcessing,
    error,
  ];
}
