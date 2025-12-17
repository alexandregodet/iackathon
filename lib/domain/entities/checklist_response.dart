import 'package:equatable/equatable.dart';

class QuestionResponse extends Equatable {
  final int? id;
  final String checklistId;
  final String questionUuid;
  final String? serialNumber;
  final String? response;
  final List<String> attachmentPaths;
  final String? comment;
  final List<Map<String, dynamic>>? aiTags;
  final String? aiDescription;
  final Map<String, dynamic>? aiDefectBbox;
  final DateTime createdAt;
  final DateTime updatedAt;

  const QuestionResponse({
    this.id,
    required this.checklistId,
    required this.questionUuid,
    this.serialNumber,
    this.response,
    this.attachmentPaths = const [],
    this.comment,
    this.aiTags,
    this.aiDescription,
    this.aiDefectBbox,
    required this.createdAt,
    required this.updatedAt,
  });

  QuestionResponse copyWith({
    int? id,
    String? checklistId,
    String? questionUuid,
    String? serialNumber,
    String? response,
    List<String>? attachmentPaths,
    String? comment,
    List<Map<String, dynamic>>? aiTags,
    String? aiDescription,
    Map<String, dynamic>? aiDefectBbox,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return QuestionResponse(
      id: id ?? this.id,
      checklistId: checklistId ?? this.checklistId,
      questionUuid: questionUuid ?? this.questionUuid,
      serialNumber: serialNumber ?? this.serialNumber,
      response: response ?? this.response,
      attachmentPaths: attachmentPaths ?? this.attachmentPaths,
      comment: comment ?? this.comment,
      aiTags: aiTags ?? this.aiTags,
      aiDescription: aiDescription ?? this.aiDescription,
      aiDefectBbox: aiDefectBbox ?? this.aiDefectBbox,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        checklistId,
        questionUuid,
        serialNumber,
        response,
        attachmentPaths,
        comment,
        aiTags,
        aiDescription,
        aiDefectBbox,
        createdAt,
        updatedAt,
      ];
}
