import 'package:equatable/equatable.dart';

import 'checklist_question.dart';

class ChecklistSection extends Equatable {
  final String uuid;
  final String title;
  final String description;
  final List<ChecklistQuestion> questions;

  const ChecklistSection({
    required this.uuid,
    required this.title,
    this.description = '',
    required this.questions,
  });

  /// Extrait les mots-cles pour la detection de section
  /// Ex: "2 Deck - Engine Room" -> ["engine room", "engine", "deck 2", "salle des machines"]
  List<String> get sectionKeywords {
    final keywords = <String>[];

    // Titre complet en minuscule
    keywords.add(title.toLowerCase());

    // Extrait le nom de la piece apres le tiret
    if (title.contains(' - ')) {
      final parts = title.split(' - ');
      if (parts.length > 1) {
        keywords.add(parts.last.toLowerCase());
      }
    }

    // Extrait le numero de deck
    final deckMatch = RegExp(
      r'(\d+)\s*deck',
      caseSensitive: false,
    ).firstMatch(title);
    if (deckMatch != null) {
      keywords.add('deck ${deckMatch.group(1)}');
      keywords.add('pont ${deckMatch.group(1)}');
    }

    // Traductions communes anglais -> francais
    final translations = <String, List<String>>{
      'engine room': ['salle des machines', 'machine', 'moteur'],
      'bridge': ['passerelle', 'pont de commande'],
      'cargo hold': ['cale', 'soute'],
      'deck': ['pont'],
      'cabin': ['cabine'],
      'galley': ['cuisine', 'cambuse'],
      'mess': ['carre', 'refectoire'],
    };

    for (final entry in translations.entries) {
      if (title.toLowerCase().contains(entry.key)) {
        keywords.addAll(entry.value);
      }
    }

    return keywords;
  }

  int get totalQuestions => questions.length;

  int get mandatoryQuestions => questions.where((q) => q.mandatory).length;

  /// Factory depuis JSON
  factory ChecklistSection.fromJson(Map<String, dynamic> json) {
    final questionsJson = json['questions'] as List<dynamic>? ?? [];
    final questions = questionsJson
        .map((q) => ChecklistQuestion.fromJson(q as Map<String, dynamic>))
        .toList();

    return ChecklistSection(
      uuid: json['uuid'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      questions: questions,
    );
  }

  /// Convertit en JSON
  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'title': title,
      'description': description,
      'questions': questions.map((q) => q.toJson()).toList(),
    };
  }

  ChecklistSection copyWith({
    String? uuid,
    String? title,
    String? description,
    List<ChecklistQuestion>? questions,
  }) {
    return ChecklistSection(
      uuid: uuid ?? this.uuid,
      title: title ?? this.title,
      description: description ?? this.description,
      questions: questions ?? this.questions,
    );
  }

  @override
  List<Object?> get props => [uuid, title, description, questions];
}
