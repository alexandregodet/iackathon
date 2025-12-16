import 'package:equatable/equatable.dart';

class Checklist extends Equatable {
  final String id;
  final String checklistId;
  final String userId;
  final DateTime createdAt;
  final ChecklistAnswers answers;
  final ChecklistContext context;
  final String contractId;
  final ChecklistUser user;
  final ChecklistContract contract;

  const Checklist({
    required this.id,
    required this.checklistId,
    required this.userId,
    required this.createdAt,
    required this.answers,
    required this.context,
    required this.contractId,
    required this.user,
    required this.contract,
  });

  factory Checklist.fromJson(Map<String, dynamic> json) {
    return Checklist(
      id: json['id'] as String,
      checklistId: json['checklistId'] as String,
      userId: json['userId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      answers: ChecklistAnswers.fromJson(json['answers'] as Map<String, dynamic>),
      context: ChecklistContext.fromJson(json['context'] as Map<String, dynamic>),
      contractId: json['contractId'] as String,
      user: ChecklistUser.fromJson(json['user'] as Map<String, dynamic>),
      contract: ChecklistContract.fromJson(json['contract'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'checklistId': checklistId,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'answers': answers.toJson(),
      'context': context.toJson(),
      'contractId': contractId,
      'user': user.toJson(),
      'contract': contract.toJson(),
    };
  }

  @override
  List<Object?> get props => [id, checklistId, userId, createdAt, answers, context, contractId, user, contract];
}

class ChecklistAnswers extends Equatable {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String knowledgeBaseId;
  final bool isFinish;
  final List<ChecklistSection> sections;
  final ChecklistMetadata metadata;

  const ChecklistAnswers({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    required this.knowledgeBaseId,
    required this.isFinish,
    required this.sections,
    required this.metadata,
  });

  factory ChecklistAnswers.fromJson(Map<String, dynamic> json) {
    return ChecklistAnswers(
      id: json['_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      knowledgeBaseId: json['knowledgeBaseId'] as String,
      isFinish: json['isFinish'] as bool,
      sections: (json['sections'] as List<dynamic>)
          .map((s) => ChecklistSection.fromJson(s as Map<String, dynamic>))
          .toList(),
      metadata: ChecklistMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'knowledgeBaseId': knowledgeBaseId,
      'isFinish': isFinish,
      'sections': sections.map((s) => s.toJson()).toList(),
      'metadata': metadata.toJson(),
    };
  }

  ChecklistAnswers copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? knowledgeBaseId,
    bool? isFinish,
    List<ChecklistSection>? sections,
    ChecklistMetadata? metadata,
  }) {
    return ChecklistAnswers(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      knowledgeBaseId: knowledgeBaseId ?? this.knowledgeBaseId,
      isFinish: isFinish ?? this.isFinish,
      sections: sections ?? this.sections,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [id, title, description, createdAt, updatedAt, knowledgeBaseId, isFinish, sections, metadata];
}

class ChecklistSection extends Equatable {
  final String uuid;
  final String title;
  final String description;
  final List<ChecklistQuestion> questions;

  const ChecklistSection({
    required this.uuid,
    required this.title,
    required this.description,
    required this.questions,
  });

  factory ChecklistSection.fromJson(Map<String, dynamic> json) {
    return ChecklistSection(
      uuid: json['uuid'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      questions: (json['questions'] as List<dynamic>)
          .map((q) => ChecklistQuestion.fromJson(q as Map<String, dynamic>))
          .toList(),
    );
  }

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

class ChecklistQuestion extends Equatable {
  final String uuid;
  final int id;
  final String type;
  final String title;
  final bool mandatory;
  final bool attachment;
  final bool comment;
  final bool hideInReport;
  final String? hint;
  final bool responseBelow;
  final String? commentContent;
  final String format;
  final String defaultValue;
  final String response;

  const ChecklistQuestion({
    required this.uuid,
    required this.id,
    required this.type,
    required this.title,
    required this.mandatory,
    required this.attachment,
    required this.comment,
    required this.hideInReport,
    this.hint,
    required this.responseBelow,
    this.commentContent,
    required this.format,
    required this.defaultValue,
    required this.response,
  });

  factory ChecklistQuestion.fromJson(Map<String, dynamic> json) {
    return ChecklistQuestion(
      uuid: json['uuid'] as String,
      id: json['id'] as int,
      type: json['type'] as String,
      title: json['title'] as String,
      mandatory: json['mandatory'] as bool,
      attachment: json['attachment'] as bool,
      comment: json['comment'] as bool,
      hideInReport: json['hideInReport'] as bool,
      hint: json['hint'] as String?,
      responseBelow: json['responseBelow'] as bool,
      commentContent: json['commentContent'] as String?,
      format: json['format'] as String? ?? 'short',
      defaultValue: json['defaultValue'] as String? ?? '',
      response: json['response'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uuid': uuid,
      'id': id,
      'type': type,
      'title': title,
      'mandatory': mandatory,
      'attachment': attachment,
      'comment': comment,
      'hideInReport': hideInReport,
      'hint': hint,
      'responseBelow': responseBelow,
      'commentContent': commentContent,
      'format': format,
      'defaultValue': defaultValue,
      'response': response,
    };
  }

  ChecklistQuestion copyWith({
    String? uuid,
    int? id,
    String? type,
    String? title,
    bool? mandatory,
    bool? attachment,
    bool? comment,
    bool? hideInReport,
    String? hint,
    bool? responseBelow,
    String? commentContent,
    String? format,
    String? defaultValue,
    String? response,
  }) {
    return ChecklistQuestion(
      uuid: uuid ?? this.uuid,
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      mandatory: mandatory ?? this.mandatory,
      attachment: attachment ?? this.attachment,
      comment: comment ?? this.comment,
      hideInReport: hideInReport ?? this.hideInReport,
      hint: hint ?? this.hint,
      responseBelow: responseBelow ?? this.responseBelow,
      commentContent: commentContent ?? this.commentContent,
      format: format ?? this.format,
      defaultValue: defaultValue ?? this.defaultValue,
      response: response ?? this.response,
    );
  }

  @override
  List<Object?> get props => [uuid, id, type, title, mandatory, attachment, comment, hideInReport, hint, responseBelow, commentContent, format, defaultValue, response];
}

class ChecklistContext extends Equatable {
  final DateTime startedAt;
  final String pn;
  final String sn;
  final String lang;
  final String assetNumber;
  final String? sourceWorkOrderId;

  const ChecklistContext({
    required this.startedAt,
    required this.pn,
    required this.sn,
    required this.lang,
    required this.assetNumber,
    this.sourceWorkOrderId,
  });

  factory ChecklistContext.fromJson(Map<String, dynamic> json) {
    return ChecklistContext(
      startedAt: DateTime.parse(json['startedAt'] as String),
      pn: json['pn'] as String,
      sn: json['sn'] as String,
      lang: json['lang'] as String,
      assetNumber: json['assetNumber'] as String,
      sourceWorkOrderId: json['sourceWorkOrderId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'startedAt': startedAt.toIso8601String(),
      'pn': pn,
      'sn': sn,
      'lang': lang,
      'assetNumber': assetNumber,
      'sourceWorkOrderId': sourceWorkOrderId,
    };
  }

  @override
  List<Object?> get props => [startedAt, pn, sn, lang, assetNumber, sourceWorkOrderId];
}

class ChecklistUser extends Equatable {
  final String id;
  final String email;

  const ChecklistUser({
    required this.id,
    required this.email,
  });

  factory ChecklistUser.fromJson(Map<String, dynamic> json) {
    return ChecklistUser(
      id: json['id'] as String,
      email: json['email'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
    };
  }

  @override
  List<Object?> get props => [id, email];
}

class ChecklistContract extends Equatable {
  final String id;
  final String reference;
  final DateTime startDate;
  final DateTime endDate;
  final String? funding;
  final String comment;
  final List<String> languages;
  final String siteId;
  final String erpRefId;
  final String learningCohort;
  final String environment;
  final String scopeId;
  final String clientId;

  const ChecklistContract({
    required this.id,
    required this.reference,
    required this.startDate,
    required this.endDate,
    this.funding,
    required this.comment,
    required this.languages,
    required this.siteId,
    required this.erpRefId,
    required this.learningCohort,
    required this.environment,
    required this.scopeId,
    required this.clientId,
  });

  factory ChecklistContract.fromJson(Map<String, dynamic> json) {
    return ChecklistContract(
      id: json['id'] as String,
      reference: json['reference'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      funding: json['funding'] as String?,
      comment: json['comment'] as String? ?? '',
      languages: (json['languages'] as List<dynamic>).cast<String>(),
      siteId: json['siteId'] as String,
      erpRefId: json['erpRefId'] as String? ?? '',
      learningCohort: json['learningCohort'] as String? ?? '',
      environment: json['environment'] as String,
      scopeId: json['scopeId'] as String,
      clientId: json['clientId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reference': reference,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'funding': funding,
      'comment': comment,
      'languages': languages,
      'siteId': siteId,
      'erpRefId': erpRefId,
      'learningCohort': learningCohort,
      'environment': environment,
      'scopeId': scopeId,
      'clientId': clientId,
    };
  }

  @override
  List<Object?> get props => [id, reference, startDate, endDate, funding, comment, languages, siteId, erpRefId, learningCohort, environment, scopeId, clientId];
}

class ChecklistMetadata extends Equatable {
  final List<String> partNumbers;
  final List<String> codes;
  final Map<String, dynamic> additional;

  const ChecklistMetadata({
    required this.partNumbers,
    required this.codes,
    required this.additional,
  });

  factory ChecklistMetadata.fromJson(Map<String, dynamic> json) {
    return ChecklistMetadata(
      partNumbers: (json['partNumbers'] as List<dynamic>).cast<String>(),
      codes: (json['codes'] as List<dynamic>).cast<String>(),
      additional: json['additional'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'partNumbers': partNumbers,
      'codes': codes,
      'additional': additional,
    };
  }

  @override
  List<Object?> get props => [partNumbers, codes, additional];
}
