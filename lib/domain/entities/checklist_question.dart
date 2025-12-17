import 'package:equatable/equatable.dart';

enum QuestionType { multipleChoice, checkbox, text }

class ChecklistQuestion extends Equatable {
  final String uuid;
  final QuestionType type;
  final String title;
  final String hint;
  final bool mandatory;
  final bool commentEnabled;
  final bool attachmentEnabled;
  final List<String> choices;
  final bool multipleAnswer;
  final String? defaultValue;

  const ChecklistQuestion({
    required this.uuid,
    required this.type,
    required this.title,
    this.hint = '',
    this.mandatory = false,
    this.commentEnabled = false,
    this.attachmentEnabled = false,
    this.choices = const [],
    this.multipleAnswer = false,
    this.defaultValue,
  });

  /// Formule la question de maniere naturelle pour Gemma
  String get questionPrompt {
    switch (type) {
      case QuestionType.multipleChoice:
        return 'Quel est l\'etat de "$title"? Les options sont: ${choices.join(", ")}.';
      case QuestionType.checkbox:
        return 'Y a-t-il un probleme de securite pour "$title"?';
      case QuestionType.text:
        return 'Decrivez l\'etat de "$title".';
    }
  }

  /// Question courte pour la conversation
  String get shortPrompt {
    switch (type) {
      case QuestionType.multipleChoice:
        return 'Et pour "$title"?';
      case QuestionType.checkbox:
        return 'Probleme de securite pour "$title"?';
      case QuestionType.text:
        return 'Description de "$title"?';
    }
  }

  /// Parse le type depuis la string JSON
  static QuestionType parseType(String type) {
    switch (type) {
      case 'multiple-choice':
        return QuestionType.multipleChoice;
      case 'checkbox':
        return QuestionType.checkbox;
      default:
        return QuestionType.text;
    }
  }

  /// Factory depuis JSON
  factory ChecklistQuestion.fromJson(Map<String, dynamic> json) {
    return ChecklistQuestion(
      uuid: json['uuid'] as String,
      type: parseType(json['type'] as String? ?? 'text'),
      title: json['title'] as String,
      hint: json['hint'] as String? ?? '',
      mandatory: json['mandatory'] as bool? ?? false,
      commentEnabled: json['comment'] as bool? ?? false,
      attachmentEnabled: json['attachment'] as bool? ?? false,
      choices:
          (json['choices'] as List<dynamic>?)
              ?.map((c) => c as String)
              .toList() ??
          [],
      multipleAnswer: json['multipleAnswer'] as bool? ?? false,
      defaultValue: json['defaultValue'] as String?,
    );
  }

  /// Convertit en JSON
  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'type': type.name,
      'title': title,
      'hint': hint,
      'mandatory': mandatory,
      'comment': commentEnabled,
      'attachment': attachmentEnabled,
      'choices': choices,
      'multipleAnswer': multipleAnswer,
      'defaultValue': defaultValue,
    };
  }

  ChecklistQuestion copyWith({
    String? uuid,
    QuestionType? type,
    String? title,
    String? hint,
    bool? mandatory,
    bool? commentEnabled,
    bool? attachmentEnabled,
    List<String>? choices,
    bool? multipleAnswer,
    String? defaultValue,
  }) {
    return ChecklistQuestion(
      uuid: uuid ?? this.uuid,
      type: type ?? this.type,
      title: title ?? this.title,
      hint: hint ?? this.hint,
      mandatory: mandatory ?? this.mandatory,
      commentEnabled: commentEnabled ?? this.commentEnabled,
      attachmentEnabled: attachmentEnabled ?? this.attachmentEnabled,
      choices: choices ?? this.choices,
      multipleAnswer: multipleAnswer ?? this.multipleAnswer,
      defaultValue: defaultValue ?? this.defaultValue,
    );
  }

  @override
  List<Object?> get props => [
    uuid,
    type,
    title,
    hint,
    mandatory,
    commentEnabled,
    attachmentEnabled,
    choices,
    multipleAnswer,
    defaultValue,
  ];
}
