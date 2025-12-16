import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';

abstract class ChecklistEvent extends Equatable {
  const ChecklistEvent();

  @override
  List<Object?> get props => [];
}

class ChecklistLoadFromAsset extends ChecklistEvent {
  final String assetPath;

  const ChecklistLoadFromAsset(this.assetPath);

  @override
  List<Object?> get props => [assetPath];
}

class ChecklistGoToSection extends ChecklistEvent {
  final int sectionIndex;

  const ChecklistGoToSection(this.sectionIndex);

  @override
  List<Object?> get props => [sectionIndex];
}

class ChecklistUpdateResponse extends ChecklistEvent {
  final String questionUuid;
  final String? response;

  const ChecklistUpdateResponse({
    required this.questionUuid,
    this.response,
  });

  @override
  List<Object?> get props => [questionUuid, response];
}

class ChecklistAddAttachment extends ChecklistEvent {
  final String questionUuid;
  final XFile file;

  const ChecklistAddAttachment({
    required this.questionUuid,
    required this.file,
  });

  @override
  List<Object?> get props => [questionUuid, file];
}

class ChecklistRemoveAttachment extends ChecklistEvent {
  final String questionUuid;
  final String filePath;

  const ChecklistRemoveAttachment({
    required this.questionUuid,
    required this.filePath,
  });

  @override
  List<Object?> get props => [questionUuid, filePath];
}

class ChecklistUpdateComment extends ChecklistEvent {
  final String questionUuid;
  final String? comment;

  const ChecklistUpdateComment({
    required this.questionUuid,
    this.comment,
  });

  @override
  List<Object?> get props => [questionUuid, comment];
}

class ChecklistSaveProgress extends ChecklistEvent {
  const ChecklistSaveProgress();
}

class ChecklistSubmit extends ChecklistEvent {
  const ChecklistSubmit();
}

class ChecklistUpdateSerialNumber extends ChecklistEvent {
  final String serialNumber;

  const ChecklistUpdateSerialNumber(this.serialNumber);

  @override
  List<Object?> get props => [serialNumber];
}
