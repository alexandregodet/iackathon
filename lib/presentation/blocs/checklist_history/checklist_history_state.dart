import 'package:equatable/equatable.dart';

import '../../../domain/entities/checklist_summary.dart';

class ChecklistHistoryState extends Equatable {
  final List<ChecklistSummary> summaries;
  final List<ChecklistSummary> filteredSummaries;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final Set<String> expandedItems;

  const ChecklistHistoryState({
    this.summaries = const [],
    this.filteredSummaries = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.expandedItems = const {},
  });

  bool get hasSearch => searchQuery.isNotEmpty;

  List<ChecklistSummary> get displayedSummaries =>
      hasSearch ? filteredSummaries : summaries;

  ChecklistHistoryState copyWith({
    List<ChecklistSummary>? summaries,
    List<ChecklistSummary>? filteredSummaries,
    bool? isLoading,
    String? error,
    String? searchQuery,
    Set<String>? expandedItems,
  }) {
    return ChecklistHistoryState(
      summaries: summaries ?? this.summaries,
      filteredSummaries: filteredSummaries ?? this.filteredSummaries,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      expandedItems: expandedItems ?? this.expandedItems,
    );
  }

  @override
  List<Object?> get props => [
        summaries,
        filteredSummaries,
        isLoading,
        error,
        searchQuery,
        expandedItems,
      ];
}
