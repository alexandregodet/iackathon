import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:injectable/injectable.dart';

import '../../core/utils/app_logger.dart';
import '../../domain/entities/checklist_question.dart';
import '../../domain/entities/checklist_response.dart';
import '../../domain/entities/checklist_section.dart';
import '../../domain/entities/checklist_session.dart';

/// Resultat de la classification avec niveau de confiance
class ClassificationResult {
  final String choice;
  final bool isConfident;
  final List<String> probableChoices;
  final String? comment;
  final String rawResponse;

  ClassificationResult({
    required this.choice,
    required this.isConfident,
    this.probableChoices = const [],
    this.comment,
    required this.rawResponse,
  });
}

/// Resultat de la classification checkbox avec niveau de confiance
class CheckboxClassificationResult {
  final bool value;
  final bool isConfident;
  final String rawResponse;

  CheckboxClassificationResult({
    required this.value,
    required this.isConfident,
    required this.rawResponse,
  });
}

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
  /// avec indication du niveau de confiance
  String buildClassificationPrompt(
    String userInput,
    ChecklistQuestion question,
  ) {
    final choicesStr = question.choices.join(', ');

    return '''Classe cette reponse d'inspection.

QUESTION: "${question.title}"
CHOIX: $choicesStr

REPONSE: "$userInput"

Reponds avec:
CHOIX: [le choix qui correspond le mieux]
COMMENTAIRE: [details supplementaires donnes par l'utilisateur, ou AUCUN]''';
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
- Determine si tu es SUR ou INCERTAIN de ta reponse

REPONDS EXACTEMENT DANS CE FORMAT:
CONFIANCE: [SUR ou INCERTAIN]
REPONSE: [OUI ou NON]''';
  }

  /// Parse la reponse de Gemma pour extraire le choix et le commentaire
  ClassificationResult? parseGemmaClassification(
    String gemmaResponse,
    ChecklistQuestion question,
  ) {
    final response = gemmaResponse.trim();
    final lowerResponse = response.toLowerCase();

    // Extraire le choix
    String? choice;

    // Chercher apres "CHOIX:" ou "choix:"
    final choixMatch = RegExp(r'choix\s*:\s*(.+)', caseSensitive: false)
        .firstMatch(response);
    if (choixMatch != null) {
      final choixValue = choixMatch.group(1)?.trim().split('\n').first ?? '';
      for (final c in question.choices) {
        if (choixValue.toLowerCase().contains(c.toLowerCase())) {
          choice = c;
          break;
        }
      }
    }

    // Si pas trouve avec le format, chercher directement dans la reponse
    if (choice == null) {
      for (final c in question.choices) {
        if (lowerResponse.contains(c.toLowerCase())) {
          choice = c;
          break;
        }
      }
    }

    // Si toujours pas trouve, retourner null (declenchera le mode incertain)
    if (choice == null) return null;

    // Extraire le commentaire
    String? comment;
    final commentMatch = RegExp(
      r'commentaire\s*:\s*(.+)',
      caseSensitive: false,
    ).firstMatch(response);

    if (commentMatch != null) {
      final commentValue = commentMatch.group(1)?.trim().split('\n').first ?? '';
      // Ignorer si "AUCUN" ou vide
      if (commentValue.isNotEmpty &&
          !commentValue.toLowerCase().contains('aucun') &&
          commentValue.toLowerCase() != 'aucun' &&
          commentValue != '-') {
        comment = commentValue;
      }
    }

    return ClassificationResult(
      choice: choice,
      isConfident: true, // Toujours confiant si on a trouve un choix
      probableChoices: [],
      comment: comment,
      rawResponse: response,
    );
  }

  /// Parse la reponse de Gemma pour une checkbox avec confiance
  CheckboxClassificationResult? parseGemmaCheckboxClassification(
    String gemmaResponse,
  ) {
    final response = gemmaResponse.toLowerCase().trim();

    // Detecter le niveau de confiance
    bool isConfident = true;
    if (response.contains('incertain')) {
      isConfident = false;
    } else if (!response.contains('sur')) {
      isConfident = false;
    }

    // Detecter la reponse
    bool? value;
    if (response.contains('oui') || response.contains('yes')) {
      value = true;
    } else if (response.contains('non') || response.contains('no')) {
      value = false;
    }

    if (value == null) return null;

    return CheckboxClassificationResult(
      value: value,
      isConfident: isConfident,
      rawResponse: gemmaResponse,
    );
  }

  /// Formate les choix pour affichage a l'utilisateur
  String formatChoicesForUser(ChecklistQuestion question) {
    final buffer = StringBuffer();
    buffer.writeln('Quel est l\'etat de "${question.title}"?');
    buffer.writeln();
    for (var i = 0; i < question.choices.length; i++) {
      buffer.writeln('${i + 1}. ${question.choices[i]}');
    }
    buffer.writeln();
    buffer.writeln('Repondez librement ou avec le numero du choix.');
    return buffer.toString();
  }

  /// Detecte si l'utilisateur demande tous les choix
  bool isAskingForAllChoices(String userInput) {
    final triggers = [
      'tous les choix',
      'toutes les options',
      'autres choix',
      'autre choix',
      'voir tout',
      'all choices',
      'more options',
      'plus de choix',
      'liste complete',
    ];
    final input = userInput.toLowerCase();
    return triggers.any((t) => input.contains(t));
  }

  /// Tente de parser une selection directe de l'utilisateur (numero ou nom)
  String? parseDirectChoice(String userInput, ChecklistQuestion question) {
    final input = userInput.trim().toLowerCase();

    // Essayer de parser un numero
    final number = int.tryParse(input);
    if (number != null && number >= 1 && number <= question.choices.length) {
      return question.choices[number - 1];
    }

    // Essayer de matcher un nom de choix exact
    for (final choice in question.choices) {
      if (input == choice.toLowerCase()) {
        return choice;
      }
    }

    return null;
  }

  /// Cree une ChecklistResponse a partir du choix classifie
  ChecklistResponse? createResponseFromChoice(
    String userInput,
    ChecklistQuestion question,
    String choice, {
    String? comment,
  }) {
    if (_currentSession?.currentSection == null) return null;

    return ChecklistResponse(
      questionUuid: question.uuid,
      sectionUuid: _currentSession!.currentSection!.uuid,
      selectedChoices: [choice],
      answeredAt: DateTime.now(),
      rawUserInput: userInput,
      comment: comment,
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
