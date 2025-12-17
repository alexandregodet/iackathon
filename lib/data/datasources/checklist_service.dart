import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:injectable/injectable.dart';

import '../../core/utils/app_logger.dart';
import '../../domain/entities/checklist_question.dart';
import '../../domain/entities/checklist_response.dart';
import '../../domain/entities/checklist_section.dart';
import '../../domain/entities/checklist_session.dart';

@singleton
class ChecklistService {
  List<ChecklistSection> _sections = [];
  ChecklistSession? _currentSession;
  String? _checklistTitle;
  String? _checklistDescription;

  List<ChecklistSection> get sections => _sections;
  ChecklistSession? get currentSession => _currentSession;
  bool get hasActiveSession => _currentSession?.isActive ?? false;
  String? get checklistTitle => _checklistTitle;
  String? get checklistDescription => _checklistDescription;
  bool get isLoaded => _sections.isNotEmpty;


  /// Mapping mots-cles questions (generique, extrait dynamiquement)
  final Map<String, List<String>> _questionKeywordsCache = {};

  // ============== CHARGEMENT ==============

  /// Charge la checklist depuis un asset
  Future<void> loadChecklistFromAsset({
    String path = 'lib/asset/checklist.json',
  }) async {
    AppLogger.info('Chargement checklist depuis $path', 'ChecklistService');

    try {
      final jsonString = await rootBundle.loadString(path);
      loadChecklistFromString(jsonString);
    } catch (e, stack) {
      AppLogger.error(
        'Erreur chargement checklist asset',
        tag: 'ChecklistService',
        error: e,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Charge la checklist depuis une string JSON
  void loadChecklistFromString(String jsonString) {
    final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
    loadChecklistFromJson(jsonData);
  }

  /// Charge la checklist depuis un objet JSON
  void loadChecklistFromJson(Map<String, dynamic> json) {
    _checklistTitle = json['title'] as String?;
    _checklistDescription = json['description'] as String?;

    final sectionsJson = json['sections'] as List<dynamic>? ?? [];
    _sections = sectionsJson
        .map((s) => ChecklistSection.fromJson(s as Map<String, dynamic>))
        .toList();

    // Build question keywords cache
    _buildQuestionKeywordsCache();

    AppLogger.info(
      'Checklist chargee: $_checklistTitle avec ${_sections.length} sections',
      'ChecklistService',
    );
  }

  /// Construit le cache des mots-cles pour chaque question
  void _buildQuestionKeywordsCache() {
    _questionKeywordsCache.clear();

    for (final section in _sections) {
      for (final question in section.questions) {
        final keywords = _extractQuestionKeywords(question.title);
        _questionKeywordsCache[question.uuid] = keywords;
      }
    }
  }

  /// Extrait les mots-cles d'un titre de question
  List<String> _extractQuestionKeywords(String title) {
    final keywords = <String>[];
    final lowerTitle = title.toLowerCase();

    keywords.add(lowerTitle);

    // Mots individuels significatifs (> 3 chars)
    final words = lowerTitle.split(RegExp(r'[\s/\-:]+'));
    for (final word in words) {
      if (word.length > 3) {
        keywords.add(word);
      }
    }

    // Traductions communes
    final translations = <String, List<String>>{
      'doors': ['portes', 'porte'],
      'hatches': ['ecoutilles', 'trappes'],
      'cables': ['cables', 'cable', 'fils'],
      'lighting': ['eclairage', 'lumiere', 'lumieres'],
      'deck plates': ['plaques de pont', 'plaques', 'toles'],
      'bilge': ['cale', 'fond de cale'],
      'coatings': ['revetement', 'peinture'],
      'bulkheads': ['cloisons', 'cloison'],
      'deckhead': ['plafond', 'dessus'],
      'safety': ['securite'],
    };

    for (final entry in translations.entries) {
      if (lowerTitle.contains(entry.key)) {
        keywords.addAll(entry.value);
      }
    }

    return keywords;
  }

  // ============== DETECTION DE SECTION ==============

  /// Detecte la section depuis l'input utilisateur
  ChecklistSection? detectSection(String userInput) {
    final input = userInput.toLowerCase();
    AppLogger.debug('detectSection: "$input"', 'ChecklistService');

    // Indicateurs de mention de lieu
    final locationIndicators = [
      'je suis dans',
      'je suis a',
      'je suis au',
      'dans le',
      'dans la',
      'section',
      'compartiment',
      'room',
      'piece',
      'salle',
    ];

    bool hasLocationIndicator = locationIndicators.any(
      (ind) => input.contains(ind),
    );

    AppLogger.debug(
      'hasLocationIndicator=$hasLocationIndicator, hasActiveSession=$hasActiveSession',
      'ChecklistService',
    );

    // Si pas d'indicateur et pas de session active, ne pas detecter
    if (!hasLocationIndicator && !hasActiveSession) {
      return null;
    }

    // Score chaque section par correspondance de mots-cles
    ChecklistSection? bestMatch;
    int bestScore = 0;

    for (final section in _sections) {
      int score = 0;
      for (final keyword in section.sectionKeywords) {
        if (input.contains(keyword)) {
          score += keyword.length;
        }
      }
      AppLogger.debug(
        'Section "${section.title}" score=$score',
        'ChecklistService',
      );
      if (score > bestScore) {
        bestScore = score;
        bestMatch = section;
      }
    }

    AppLogger.debug(
      'bestScore=$bestScore, bestMatch=${bestMatch?.title}',
      'ChecklistService',
    );

    // Seuil minimum de 3 caracteres de match
    return bestScore > 3 ? bestMatch : null;
  }

  // ============== SESSION ==============

  /// Demarre une nouvelle session pour une section
  ChecklistSession startSession(ChecklistSection section) {
    _currentSession = ChecklistSession(
      sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
      mode: ChecklistMode.active,
      currentSection: section,
      currentQuestionIndex: 0,
      startedAt: DateTime.now(),
    );

    AppLogger.info(
      'Session demarree pour ${section.title}',
      'ChecklistService',
    );

    return _currentSession!;
  }

  /// Termine la session courante
  void endSession() {
    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(
        mode: ChecklistMode.completed,
        completedAt: DateTime.now(),
      );
      AppLogger.info('Session terminee', 'ChecklistService');
    }
  }

  /// Efface la session courante
  void clearSession() {
    _currentSession = null;
  }

  // ============== CLASSIFICATION PAR LLM ==============

  /// Construit le prompt pour que Gemma classifie la reponse utilisateur
  String buildClassificationPrompt(
    String userInput,
    ChecklistQuestion question,
  ) {
    final choicesStr = question.choices.join(', ');

    return '''Tu es un assistant d'inspection. Analyse la reponse de l'utilisateur et determine le choix le plus approprie.

QUESTION: "${question.title}"
CHOIX POSSIBLES: [$choicesStr]

REPONSE UTILISATEUR: "$userInput"

INSTRUCTIONS:
- Analyse le sens de la reponse utilisateur
- Choisis UN SEUL choix parmi la liste qui correspond le mieux
- Reponds UNIQUEMENT avec le nom exact du choix (ex: "Satisfactory" ou "Major")
- Si la reponse indique que tout va bien/ok/ras -> "Satisfactory"
- Si la reponse indique un probleme mineur/leger -> "Minor"
- Si la reponse indique un probleme important/defectueux/casse -> "Major"
- Si la reponse indique une urgence/danger/critique -> "Immediate"
- Si la reponse indique a surveiller/attention -> "Monitor"

CHOIX:''';
  }

  /// Construit le prompt pour classifier une reponse checkbox (oui/non)
  String buildCheckboxClassificationPrompt(
    String userInput,
    ChecklistQuestion question,
  ) {
    return '''Tu es un assistant d'inspection. Determine si la reponse indique un probleme de securite.

QUESTION: "${question.title}"
REPONSE UTILISATEUR: "$userInput"

INSTRUCTIONS:
- Analyse si la reponse indique un probleme de securite ou non
- Reponds UNIQUEMENT par "OUI" ou "NON"
- Si l'utilisateur mentionne un danger, probleme de securite, risque -> "OUI"
- Si l'utilisateur dit que c'est ok, pas de probleme, ras -> "NON"

REPONSE:''';
  }

  /// Parse la reponse de Gemma pour extraire le choix
  String? parseGemmaChoice(String gemmaResponse, ChecklistQuestion question) {
    final response = gemmaResponse.trim();

    // Chercher le choix exact dans la reponse
    for (final choice in question.choices) {
      if (response.toLowerCase().contains(choice.toLowerCase())) {
        return choice;
      }
    }

    // Si pas trouve, prendre la premiere ligne non vide
    final lines = response.split('\n').where((l) => l.trim().isNotEmpty);
    if (lines.isNotEmpty) {
      final firstLine = lines.first.trim();
      // Verifier si c'est un choix valide
      for (final choice in question.choices) {
        if (firstLine.toLowerCase() == choice.toLowerCase()) {
          return choice;
        }
      }
    }

    return null;
  }

  /// Parse la reponse de Gemma pour une checkbox
  bool? parseGemmaCheckbox(String gemmaResponse) {
    final response = gemmaResponse.toLowerCase().trim();

    if (response.contains('oui') || response.contains('yes')) {
      return true;
    }
    if (response.contains('non') || response.contains('no')) {
      return false;
    }

    return null;
  }

  /// Cree une ChecklistResponse a partir du choix classifie
  ChecklistResponse? createResponseFromChoice(
    String userInput,
    ChecklistQuestion question,
    String choice,
  ) {
    if (_currentSession?.currentSection == null) return null;

    return ChecklistResponse(
      questionUuid: question.uuid,
      sectionUuid: _currentSession!.currentSection!.uuid,
      selectedChoices: [choice],
      answeredAt: DateTime.now(),
      rawUserInput: userInput,
    );
  }

  /// Cree une ChecklistResponse pour une checkbox
  ChecklistResponse? createCheckboxResponse(
    String userInput,
    ChecklistQuestion question,
    bool value,
  ) {
    if (_currentSession?.currentSection == null) return null;

    return ChecklistResponse(
      questionUuid: question.uuid,
      sectionUuid: _currentSession!.currentSection!.uuid,
      checkboxValue: value,
      answeredAt: DateTime.now(),
      rawUserInput: userInput,
    );
  }

  /// Cree une ChecklistResponse pour du texte libre
  ChecklistResponse? createTextResponse(
    String userInput,
    ChecklistQuestion question,
  ) {
    if (_currentSession?.currentSection == null) return null;

    return ChecklistResponse(
      questionUuid: question.uuid,
      sectionUuid: _currentSession!.currentSection!.uuid,
      textValue: userInput,
      answeredAt: DateTime.now(),
      rawUserInput: userInput,
    );
  }

  // ============== DETECTION DE QUESTIONS ==============

  /// Detecte les questions mentionnees dans l'input utilisateur
  /// Retourne la liste des questions qui semblent etre referencees
  List<ChecklistQuestion> detectMentionedQuestions(String userInput) {
    final results = <ChecklistQuestion>[];
    if (_currentSession?.currentSection == null) return results;

    final input = userInput.toLowerCase();
    final questions = _currentSession!.currentSection!.questions;

    // Pour chaque question, verifier si elle est mentionnee
    for (final question in questions) {
      final keywords = _questionKeywordsCache[question.uuid] ?? [];

      for (final keyword in keywords) {
        if (keyword.length > 3 && input.contains(keyword)) {
          results.add(question);
          break;
        }
      }
    }

    return results;
  }

  // ============== ENREGISTREMENT ==============

  /// Enregistre une reponse et avance dans la session
  void recordResponse(ChecklistResponse response) {
    if (_currentSession == null) return;

    final updatedResponses = Map<String, ChecklistResponse>.from(
      _currentSession!.responses,
    );
    updatedResponses[response.questionUuid] = response;

    // Trouve la prochaine question non repondue
    int nextIndex = _currentSession!.currentQuestionIndex + 1;
    final questions = _currentSession!.currentSection!.questions;

    while (nextIndex < questions.length &&
        updatedResponses.containsKey(questions[nextIndex].uuid)) {
      nextIndex++;
    }

    _currentSession = _currentSession!.copyWith(
      responses: updatedResponses,
      currentQuestionIndex: nextIndex,
    );

    AppLogger.debug(
      'Reponse enregistree: ${response.questionUuid}',
      'ChecklistService',
    );
  }

  // ============== QUESTIONS RESTANTES ==============

  /// Retourne les questions non repondues
  List<ChecklistQuestion> getRemainingQuestions() {
    return _currentSession?.unansweredQuestions ?? [];
  }

  /// Retourne les questions obligatoires non repondues
  List<ChecklistQuestion> getRemainingMandatoryQuestions() {
    return _currentSession?.unansweredMandatoryQuestions ?? [];
  }

  /// Formate les questions restantes pour le LLM
  String formatRemainingQuestionsForLLM() {
    if (_currentSession == null) return 'Aucune session active.';

    final mandatory = getRemainingMandatoryQuestions();
    final optional = _currentSession!.unansweredOptionalQuestions;

    final buffer = StringBuffer();
    buffer.writeln(
      'Il vous reste ${mandatory.length + optional.length} question(s) a verifier:',
    );
    buffer.writeln();

    if (mandatory.isNotEmpty) {
      buffer.writeln('**Obligatoires (${mandatory.length}):**');
      for (final q in mandatory) {
        buffer.writeln('- ${q.title}');
      }
      buffer.writeln();
    }

    if (optional.isNotEmpty) {
      buffer.writeln('**Optionnelles (${optional.length}):**');
      for (final q in optional) {
        buffer.writeln('- ${q.title}');
      }
    }

    return buffer.toString();
  }

  // ============== RAPPORT ==============

  /// Genere le rapport JSON complet
  Map<String, dynamic> generateReport() {
    if (_currentSession == null || _currentSession!.currentSection == null) {
      return {};
    }

    final section = _currentSession!.currentSection!;
    final responses = _currentSession!.responses;

    return {
      'sessionId': _currentSession!.sessionId,
      'generatedAt': DateTime.now().toIso8601String(),
      'checklist': {
        'title': _checklistTitle,
        'description': _checklistDescription,
      },
      'section': {'uuid': section.uuid, 'title': section.title},
      'summary': {
        'totalQuestions': section.questions.length,
        'answeredQuestions': responses.length,
        'completionPercentage': _currentSession!.progressPercentage,
        'allMandatoryAnswered': _currentSession!.allMandatoryAnswered,
      },
      'responses': section.questions.map((q) {
        final response = responses[q.uuid];
        return {
          'questionUuid': q.uuid,
          'questionTitle': q.title,
          'questionType': q.type.name,
          'mandatory': q.mandatory,
          'answered': response != null,
          'response': response?.toReportJson(),
        };
      }).toList(),
      'unansweredMandatory': _currentSession!.unansweredMandatoryTitles,
    };
  }

  // ============== PROMPT SYSTEM ==============

  /// Construit le prompt systeme dynamique pour Gemma
  String buildSystemPrompt() {
    final buffer = StringBuffer();

    buffer.writeln(
      '''Tu es un assistant d'inspection. Tu aides les inspecteurs a completer leurs checklists en francais de maniere conversationnelle.

ROLE:
- Detecter quand l'utilisateur mentionne une section/piece
- Poser les questions une par une de maniere naturelle
- Comprendre les reponses en langage naturel
- Gerer les reponses groupees (ex: "les portes sont defectueuses et l'eclairage ok")
- Repondre quand on te demande "qu'est-ce qu'il me reste?" ou "il reste quoi?"
- Generer un rapport JSON sur demande ("genere le rapport")

COMMANDES SPECIALES:
- "qu'est-ce qu'il me reste?" / "il reste quoi?" -> Liste les questions non repondues
- "genere le rapport" / "export json" -> Produit le JSON final
''',
    );

    // Sections disponibles
    if (_sections.isNotEmpty) {
      buffer.writeln('\nSECTIONS DISPONIBLES:');
      for (final section in _sections) {
        buffer.writeln(
          '- ${section.title} (${section.totalQuestions} questions)',
        );
      }
    }

    // Choix possibles (extraits de la checklist)
    final allChoices = <String>{};
    for (final section in _sections) {
      for (final question in section.questions) {
        allChoices.addAll(question.choices);
      }
    }
    if (allChoices.isNotEmpty) {
      buffer.writeln('\nCHOIX POSSIBLES:');
      for (final choice in allChoices) {
        buffer.writeln('- $choice');
      }
    }

    // Contexte de session
    if (_currentSession?.isActive == true) {
      final section = _currentSession!.currentSection!;
      final remaining = getRemainingQuestions();
      final responses = _currentSession!.responses;

      buffer.writeln('\n--- CONTEXTE ACTUEL ---');
      buffer.writeln('Section: ${section.title}');
      buffer.writeln('Questions restantes: ${remaining.length}');

      if (remaining.isNotEmpty) {
        buffer.writeln('Prochaines questions:');
        for (var i = 0; i < remaining.length && i < 3; i++) {
          buffer.writeln('  - ${remaining[i].title}');
        }
      }

      if (responses.isNotEmpty) {
        buffer.writeln('Reponses enregistrees: ${responses.length}');
      }
    }

    return buffer.toString();
  }
}
