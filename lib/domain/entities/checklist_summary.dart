import 'package:equatable/equatable.dart';

/// Resume d'une checklist completee par un technicien
class ChecklistSummary extends Equatable {
  final String checklistId;
  final String checklistTitle;
  final String serialNumber;
  final DateTime completedAt;
  final int totalFields;
  final int filledFields;
  final List<String> allTags;

  const ChecklistSummary({
    required this.checklistId,
    required this.checklistTitle,
    required this.serialNumber,
    required this.completedAt,
    required this.totalFields,
    required this.filledFields,
    required this.allTags,
  });

  double get completionPercent =>
      totalFields > 0 ? filledFields / totalFields : 0.0;

  @override
  List<Object?> get props => [
        checklistId,
        checklistTitle,
        serialNumber,
        completedAt,
        totalFields,
        filledFields,
        allTags,
      ];
}
