import 'package:equatable/equatable.dart';

abstract class ChecklistHistoryEvent extends Equatable {
  const ChecklistHistoryEvent();

  @override
  List<Object?> get props => [];
}

class ChecklistHistoryLoad extends ChecklistHistoryEvent {
  const ChecklistHistoryLoad();
}

class ChecklistHistorySearch extends ChecklistHistoryEvent {
  final String query;

  const ChecklistHistorySearch(this.query);

  @override
  List<Object?> get props => [query];
}

class ChecklistHistoryClearSearch extends ChecklistHistoryEvent {
  const ChecklistHistoryClearSearch();
}
