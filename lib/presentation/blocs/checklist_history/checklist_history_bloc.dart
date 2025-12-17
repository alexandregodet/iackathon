import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../data/datasources/checklist_service.dart';
import 'checklist_history_event.dart';
import 'checklist_history_state.dart';

@injectable
class ChecklistHistoryBloc
    extends Bloc<ChecklistHistoryEvent, ChecklistHistoryState> {
  final ChecklistService _checklistService;

  ChecklistHistoryBloc(this._checklistService)
      : super(const ChecklistHistoryState()) {
    on<ChecklistHistoryLoad>(_onLoad);
    on<ChecklistHistorySearch>(_onSearch);
    on<ChecklistHistoryClearSearch>(_onClearSearch);
  }

  Future<void> _onLoad(
    ChecklistHistoryLoad event,
    Emitter<ChecklistHistoryState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final summaries = await _checklistService.getCompletedChecklists();
      emit(state.copyWith(
        summaries: summaries,
        filteredSummaries: summaries,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Erreur lors du chargement: $e',
      ));
    }
  }

  Future<void> _onSearch(
    ChecklistHistorySearch event,
    Emitter<ChecklistHistoryState> emit,
  ) async {
    final query = event.query.trim();

    if (query.isEmpty) {
      emit(state.copyWith(
        searchQuery: '',
        filteredSummaries: state.summaries,
      ));
      return;
    }

    final searchLower = query.toLowerCase();
    final filtered = state.summaries.where((summary) {
      // Search in tags
      final hasMatchingTag = summary.allTags.any(
        (tag) => tag.toLowerCase().contains(searchLower),
      );
      // Also search in serial number and title
      final matchesSerial =
          summary.serialNumber.toLowerCase().contains(searchLower);
      final matchesTitle =
          summary.checklistTitle.toLowerCase().contains(searchLower);

      return hasMatchingTag || matchesSerial || matchesTitle;
    }).toList();

    emit(state.copyWith(
      searchQuery: query,
      filteredSummaries: filtered,
    ));
  }

  void _onClearSearch(
    ChecklistHistoryClearSearch event,
    Emitter<ChecklistHistoryState> emit,
  ) {
    emit(state.copyWith(
      searchQuery: '',
      filteredSummaries: state.summaries,
    ));
  }
}
