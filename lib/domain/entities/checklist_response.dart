import 'package:equatable/equatable.dart';

class ChecklistResponse extends Equatable {
  final String questionUuid;
  final String sectionUuid;
  final List<String> selectedChoices;
  final bool? checkboxValue;
  final String? textValue;
  final String? comment;
  final DateTime answeredAt;
  final String? rawUserInput;

  const ChecklistResponse({
    required this.questionUuid,
    required this.sectionUuid,
    this.selectedChoices = const [],
    this.checkboxValue,
    this.textValue,
    this.comment,
    required this.answeredAt,
    this.rawUserInput,
  });

  bool get hasAnswer =>
      selectedChoices.isNotEmpty ||
      checkboxValue != null ||
      (textValue?.isNotEmpty ?? false);

  /// Formatte la reponse pour affichage
  String get displayValue {
    if (selectedChoices.isNotEmpty) {
      return selectedChoices.join(', ');
    }
    if (checkboxValue != null) {
      return checkboxValue! ? 'Oui' : 'Non';
    }
    return textValue ?? 'N/A';
  }

  /// Convertit en JSON pour le rapport
  Map<String, dynamic> toReportJson() {
    return {
      'questionUuid': questionUuid,
      'answer':
          checkboxValue ??
          (selectedChoices.isNotEmpty ? selectedChoices : textValue),
      'comment': comment,
      'timestamp': answeredAt.toIso8601String(),
    };
  }

  /// Convertit en JSON complet
  Map<String, dynamic> toJson() {
    return {
      'questionUuid': questionUuid,
      'sectionUuid': sectionUuid,
      'selectedChoices': selectedChoices,
      'checkboxValue': checkboxValue,
      'textValue': textValue,
      'comment': comment,
      'answeredAt': answeredAt.toIso8601String(),
      'rawUserInput': rawUserInput,
    };
  }

  /// Factory depuis JSON
  factory ChecklistResponse.fromJson(Map<String, dynamic> json) {
    return ChecklistResponse(
      questionUuid: json['questionUuid'] as String,
      sectionUuid: json['sectionUuid'] as String,
      selectedChoices:
          (json['selectedChoices'] as List<dynamic>?)
              ?.map((c) => c as String)
              .toList() ??
          [],
      checkboxValue: json['checkboxValue'] as bool?,
      textValue: json['textValue'] as String?,
      comment: json['comment'] as String?,
      answeredAt: DateTime.parse(json['answeredAt'] as String),
      rawUserInput: json['rawUserInput'] as String?,
    );
  }

  ChecklistResponse copyWith({
    String? questionUuid,
    String? sectionUuid,
    List<String>? selectedChoices,
    bool? checkboxValue,
    bool clearCheckboxValue = false,
    String? textValue,
    bool clearTextValue = false,
    String? comment,
    bool clearComment = false,
    DateTime? answeredAt,
    String? rawUserInput,
  }) {
    return ChecklistResponse(
      questionUuid: questionUuid ?? this.questionUuid,
      sectionUuid: sectionUuid ?? this.sectionUuid,
      selectedChoices: selectedChoices ?? this.selectedChoices,
      checkboxValue: clearCheckboxValue
          ? null
          : (checkboxValue ?? this.checkboxValue),
      textValue: clearTextValue ? null : (textValue ?? this.textValue),
      comment: clearComment ? null : (comment ?? this.comment),
      answeredAt: answeredAt ?? this.answeredAt,
      rawUserInput: rawUserInput ?? this.rawUserInput,
    );
  }

  @override
  List<Object?> get props => [
    questionUuid,
    sectionUuid,
    selectedChoices,
    checkboxValue,
    textValue,
    comment,
    answeredAt,
    rawUserInput,
  ];
}
