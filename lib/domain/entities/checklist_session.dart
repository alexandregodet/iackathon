import 'package:equatable/equatable.dart';

import 'checklist_question.dart';
import 'checklist_response.dart';
import 'checklist_section.dart';

enum ChecklistMode { inactive, active, completed }

class ChecklistSession extends Equatable {
  final String sessionId;
  final ChecklistMode mode;
  final ChecklistSection? currentSection;
  final int currentQuestionIndex;
  final Map<String, ChecklistResponse> responses;
  final DateTime startedAt;
  final DateTime? completedAt;

  const ChecklistSession({
    required this.sessionId,
    this.mode = ChecklistMode.inactive,
    this.currentSection,
    this.currentQuestionIndex = 0,
    this.responses = const {},
    required this.startedAt,
    this.completedAt,
  });

  bool get isActive => mode == ChecklistMode.active;
  bool get isCompleted => mode == ChecklistMode.completed;

  ChecklistQuestion? get currentQuestion {
    if (currentSection == null) return null;
    if (currentQuestionIndex >= currentSection!.questions.length) return null;
    return currentSection!.questions[currentQuestionIndex];
  }

  int get answeredCount => responses.length;
  int get totalQuestions => currentSection?.questions.length ?? 0;

  double get progress =>
      totalQuestions > 0 ? answeredCount / totalQuestions : 0;

  int get progressPercentage => (progress * 100).round();

  /// Questions non repondues
  List<ChecklistQuestion> get unansweredQuestions {
    if (currentSection == null) return [];
    return currentSection!.questions
        .where((q) => !responses.containsKey(q.uuid))
        .toList();
  }

  /// Questions obligatoires non repondues
  List<ChecklistQuestion> get unansweredMandatoryQuestions {
    return unansweredQuestions.where((q) => q.mandatory).toList();
  }

  /// Titres des questions obligatoires non repondues
  List<String> get unansweredMandatoryTitles {
    return unansweredMandatoryQuestions.map((q) => q.title).toList();
  }

  /// Questions optionnelles non repondues
  List<ChecklistQuestion> get unansweredOptionalQuestions {
    return unansweredQuestions.where((q) => !q.mandatory).toList();
  }

  /// Verifie si toutes les questions obligatoires sont repondues
  bool get allMandatoryAnswered => unansweredMandatoryQuestions.isEmpty;

  /// Verifie si toutes les questions sont repondues
  bool get allQuestionsAnswered => unansweredQuestions.isEmpty;

  ChecklistSession copyWith({
    String? sessionId,
    ChecklistMode? mode,
    ChecklistSection? currentSection,
    bool clearSection = false,
    int? currentQuestionIndex,
    Map<String, ChecklistResponse>? responses,
    DateTime? startedAt,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) {
    return ChecklistSession(
      sessionId: sessionId ?? this.sessionId,
      mode: mode ?? this.mode,
      currentSection: clearSection
          ? null
          : (currentSection ?? this.currentSection),
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      responses: responses ?? this.responses,
      startedAt: startedAt ?? this.startedAt,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
    );
  }

  @override
  List<Object?> get props => [
    sessionId,
    mode,
    currentSection,
    currentQuestionIndex,
    responses,
    startedAt,
    completedAt,
  ];
}
