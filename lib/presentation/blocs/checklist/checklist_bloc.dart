import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../core/utils/app_logger.dart';
import '../../../data/datasources/checklist_service.dart';
import '../../../data/datasources/gemma_service.dart';
import '../../../domain/entities/checklist_question.dart';
import '../../../domain/entities/checklist_response.dart';
import '../../../domain/entities/checklist_section.dart';
import '../../../domain/entities/checklist_session.dart';
import 'checklist_event.dart';
import 'checklist_state.dart';

@injectable
class ChecklistBloc extends Bloc<ChecklistEvent, ChecklistState> {
  final ChecklistService _checklistService;
  final GemmaService _gemmaService;

  ChecklistBloc(this._checklistService, this._gemmaService)
    : super(const ChecklistState()) {
    on<ChecklistInitialize>(_onInitialize);
    on<ChecklistDetectSection>(_onDetectSection);
    on<ChecklistStartSession>(_onStartSession);
    on<ChecklistProcessAnswer>(_onProcessAnswer);
    on<ChecklistShowRemaining>(_onShowRemaining);
    on<ChecklistGenerateReport>(_onGenerateReport);
    on<ChecklistEndSession>(_onEndSession);
    on<ChecklistNextQuestion>(_onNextQuestion);
    on<ChecklistSkipQuestion>(_onSkipQuestion);
    on<ChecklistClearResponse>(_onClearResponse);
  }

  Future<void> _onInitialize(
    ChecklistInitialize event,
    Emitter<ChecklistState> emit,
  ) async {
    try {
      await _checklistService.loadChecklistFromAsset();

      emit(
        state.copyWith(
          isInitialized: true,
          availableSections: _checklistService.sections,
          clearError: true,
        ),
      );

      AppLogger.info(
        'Checklist initialisee avec ${_checklistService.sections.length} sections',
        'ChecklistBloc',
      );
    } catch (e, stack) {
      AppLogger.error(
        'Erreur initialisation checklist',
        tag: 'ChecklistBloc',
        error: e,
        stackTrace: stack,
      );
      emit(state.copyWith(error: 'Erreur de chargement de la checklist'));
    }
  }

  Future<void> _onDetectSection(
    ChecklistDetectSection event,
    Emitter<ChecklistState> emit,
  ) async {
    final detectedSection = _checklistService.detectSection(event.userInput);

    if (detectedSection != null && !state.hasActiveSession) {
      add(ChecklistStartSession(detectedSection));
    }
  }

  Future<void> _onStartSession(
    ChecklistStartSession event,
    Emitter<ChecklistState> emit,
  ) async {
    final session = _checklistService.startSession(event.section);

    // Met a jour le prompt systeme de Gemma
    _updateSystemPrompt();

    final startMessage = _buildStartMessage(event.section);

    emit(
      state.copyWith(
        session: session,
        lastLlmResponse: startMessage,
        clearError: true,
      ),
    );

    AppLogger.info('Session demarree: ${event.section.title}', 'ChecklistBloc');
  }

  String _buildStartMessage(ChecklistSection section) {
    final firstQuestion = section.questions.first;
    return '''Parfait, nous allons inspecter la section "${section.title}".

Cette section comporte ${section.questions.length} elements a verifier dont ${section.mandatoryQuestions} obligatoires.

Commencons: ${firstQuestion.questionPrompt}''';
  }

  void _updateSystemPrompt() {
    final prompt = _checklistService.buildSystemPrompt();
    _gemmaService.setSystemPrompt(prompt);
  }

  Future<void> _onProcessAnswer(
    ChecklistProcessAnswer event,
    Emitter<ChecklistState> emit,
  ) async {
    if (!state.hasActiveSession) return;

    emit(state.copyWith(isProcessing: true));

    final confirmations = <String>[];

    try {
      // Detecter si plusieurs questions sont mentionnees
      final mentionedQuestions = _checklistService.detectMentionedQuestions(
        event.userInput,
      );

      if (mentionedQuestions.isNotEmpty) {
        // Classifier chaque question mentionnee avec Gemma
        for (final question in mentionedQuestions) {
          final classified = await _classifyAnswerWithGemma(
            event.userInput,
            question,
          );
          if (classified != null) {
            _checklistService.recordResponse(classified);
            confirmations.add('${question.title} = ${classified.displayValue}');
          }
        }
      } else if (state.currentQuestion != null) {
        // Classifier la reponse pour la question courante
        final classified = await _classifyAnswerWithGemma(
          event.userInput,
          state.currentQuestion!,
        );

        if (classified != null) {
          _checklistService.recordResponse(classified);
          confirmations.add(
            '${state.currentQuestion!.title} = ${classified.displayValue}',
          );
        }
      }

      _updateSystemPrompt();

      final session = _checklistService.currentSession!;
      final nextMessage = _buildNextQuestionMessage(session);

      String responseMessage;
      if (confirmations.isNotEmpty) {
        responseMessage =
            'J\'ai bien note: ${confirmations.join(", ")}.\n\n$nextMessage';
      } else {
        responseMessage =
            'Je n\'ai pas pu interpreter votre reponse. ${state.currentQuestion?.questionPrompt ?? nextMessage}';
      }

      emit(
        state.copyWith(
          session: session,
          isProcessing: false,
          lastLlmResponse: responseMessage,
        ),
      );
    } catch (e, stack) {
      AppLogger.error(
        'Erreur classification reponse',
        tag: 'ChecklistBloc',
        error: e,
        stackTrace: stack,
      );
      emit(
        state.copyWith(
          isProcessing: false,
          lastLlmResponse:
              'Erreur lors de l\'analyse. Pouvez-vous reformuler votre reponse?',
        ),
      );
    }
  }

  /// Utilise Gemma pour classifier la reponse de l'utilisateur
  Future<ChecklistResponse?> _classifyAnswerWithGemma(
    String userInput,
    ChecklistQuestion question,
  ) async {
    try {
      if (question.type == QuestionType.text) {
        return _checklistService.createTextResponse(userInput, question);
      }

      if (question.type == QuestionType.checkbox) {
        final classificationPrompt =
            _checklistService.buildCheckboxClassificationPrompt(
          userInput,
          question,
        );

        final gemmaResponse = await _getGemmaResponse(classificationPrompt);
        final checkboxValue = _checklistService.parseGemmaCheckbox(gemmaResponse);

        if (checkboxValue != null) {
          return _checklistService.createCheckboxResponse(
            userInput,
            question,
            checkboxValue,
          );
        }
        return null;
      }

      // Pour les questions a choix multiples
      final classificationPrompt = _checklistService.buildClassificationPrompt(
        userInput,
        question,
      );

      final gemmaResponse = await _getGemmaResponse(classificationPrompt);
      final choice = _checklistService.parseGemmaChoice(gemmaResponse, question);

      if (choice != null) {
        return _checklistService.createResponseFromChoice(
          userInput,
          question,
          choice,
        );
      }

      return null;
    } catch (e, stack) {
      AppLogger.error(
        'Erreur classification Gemma',
        tag: 'ChecklistBloc',
        error: e,
        stackTrace: stack,
      );
      return null;
    }
  }

  /// Obtient une reponse de Gemma de maniere synchrone
  Future<String> _getGemmaResponse(String prompt) async {
    final buffer = StringBuffer();

    await for (final chunk in _gemmaService.generateResponse(prompt)) {
      buffer.write(chunk);
    }

    return buffer.toString();
  }

  String _buildNextQuestionMessage(ChecklistSession session) {
    if (session.currentQuestion != null) {
      return session.currentQuestion!.shortPrompt;
    }

    final unanswered = session.unansweredMandatoryQuestions;
    if (unanswered.isNotEmpty) {
      return 'Excellent! Il reste ${unanswered.length} question(s) obligatoire(s) sans reponse: ${unanswered.map((q) => q.title).join(", ")}.\n\nSouhaitez-vous y revenir?';
    }

    return 'L\'inspection de cette section est complete!\n\nDites "genere le rapport" pour obtenir le JSON, ou "qu\'est-ce qu\'il me reste?" pour voir les questions optionnelles.';
  }

  Future<void> _onShowRemaining(
    ChecklistShowRemaining event,
    Emitter<ChecklistState> emit,
  ) async {
    if (!state.hasActiveSession) {
      emit(
        state.copyWith(
          lastLlmResponse:
              'Aucune session active. Dites dans quelle section vous etes.',
        ),
      );
      return;
    }

    final message = _checklistService.formatRemainingQuestionsForLLM();

    final session = _checklistService.currentSession!;
    final nextQuestion = session.currentQuestion;
    final fullMessage = nextQuestion != null
        ? '$message\n\nVoulez-vous continuer avec "${nextQuestion.title}"?'
        : message;

    emit(state.copyWith(lastLlmResponse: fullMessage));
  }

  Future<void> _onGenerateReport(
    ChecklistGenerateReport event,
    Emitter<ChecklistState> emit,
  ) async {
    if (!state.hasActiveSession) {
      emit(
        state.copyWith(
          lastLlmResponse: 'Aucune session active pour generer un rapport.',
        ),
      );
      return;
    }

    final report = _checklistService.generateReport();
    final jsonReport = const JsonEncoder.withIndent('  ').convert(report);

    emit(
      state.copyWith(
        generatedReport: jsonReport,
        lastLlmResponse:
            'Voici le rapport JSON de l\'inspection:\n\n```json\n$jsonReport\n```',
      ),
    );

    AppLogger.info('Rapport genere', 'ChecklistBloc');
  }

  Future<void> _onEndSession(
    ChecklistEndSession event,
    Emitter<ChecklistState> emit,
  ) async {
    _checklistService.endSession();
    _gemmaService.setSystemPrompt(null);

    emit(
      state.copyWith(
        clearSession: true,
        clearReport: true,
        lastLlmResponse: 'Session d\'inspection terminee. Merci!',
      ),
    );

    AppLogger.info('Session terminee', 'ChecklistBloc');
  }

  Future<void> _onNextQuestion(
    ChecklistNextQuestion event,
    Emitter<ChecklistState> emit,
  ) async {
    if (state.session == null) return;

    final currentIndex = state.session!.currentQuestionIndex;
    final total = state.session!.totalQuestions;

    if (currentIndex + 1 >= total) {
      emit(
        state.copyWith(
          lastLlmResponse: 'Toutes les questions ont ete parcourues.',
        ),
      );
      return;
    }

    final newSession = state.session!.copyWith(
      currentQuestionIndex: currentIndex + 1,
    );

    // Mettre a jour le service
    _checklistService.clearSession();
    final section = state.session!.currentSection!;
    _checklistService.startSession(section);

    emit(
      state.copyWith(
        session: newSession,
        lastLlmResponse:
            newSession.currentQuestion?.questionPrompt ??
            'Toutes les questions ont ete parcourues.',
      ),
    );
  }

  Future<void> _onSkipQuestion(
    ChecklistSkipQuestion event,
    Emitter<ChecklistState> emit,
  ) async {
    add(const ChecklistNextQuestion());
  }

  void _onClearResponse(
    ChecklistClearResponse event,
    Emitter<ChecklistState> emit,
  ) {
    emit(state.copyWith(clearLastLlmResponse: true));
  }
}
