import 'package:equatable/equatable.dart';

class QuestionResponse extends Equatable {
  final int? id;
  final String checklistId;
  final String questionUuid;
  final String? response;
  final List<String> attachmentPaths;
  final String? comment;
  final DateTime createdAt;
  final DateTime updatedAt;

  const QuestionResponse({
    this.id,
    required this.checklistId,
    required this.questionUuid,
    this.response,
    this.attachmentPaths = const [],
    this.comment,
    required this.createdAt,
    required this.updatedAt,
  });

  QuestionResponse copyWith({
    int? id,
    String? checklistId,
    String? questionUuid,
    String? response,
    List<String>? attachmentPaths,
    String? comment,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return QuestionResponse(
      id: id ?? this.id,
      checklistId: checklistId ?? this.checklistId,
      questionUuid: questionUuid ?? this.questionUuid,
      response: response ?? this.response,
      attachmentPaths: attachmentPaths ?? this.attachmentPaths,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, checklistId, questionUuid, response, attachmentPaths, comment, createdAt, updatedAt];
}
