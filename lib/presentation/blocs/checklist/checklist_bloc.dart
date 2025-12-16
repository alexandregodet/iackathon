import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../data/datasources/checklist_service.dart';
import '../../../domain/entities/checklist_response.dart';
import 'checklist_event.dart';
import 'checklist_state.dart';

@injectable
class ChecklistBloc extends Bloc<ChecklistEvent, ChecklistState> {
  final ChecklistService _checklistService;

  ChecklistBloc(this._checklistService) : super(const ChecklistState()) {
    on<ChecklistLoadFromAsset>(_onLoadFromAsset);
    on<ChecklistGoToSection>(_onGoToSection);
    on<ChecklistUpdateResponse>(_onUpdateResponse);
    on<ChecklistAddAttachment>(_onAddAttachment);
    on<ChecklistRemoveAttachment>(_onRemoveAttachment);
    on<ChecklistUpdateComment>(_onUpdateComment);
    on<ChecklistSaveProgress>(_onSaveProgress);
    on<ChecklistSubmit>(_onSubmit);
    on<ChecklistUpdateSerialNumber>(_onUpdateSerialNumber);
  }

  Future<void> _onLoadFromAsset(
    ChecklistLoadFromAsset event,
    Emitter<ChecklistState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final checklist = await _checklistService.loadChecklist(event.assetPath);

      emit(state.copyWith(
        checklist: checklist,
        responses: const {},
        isLoading: false,
        serialNumber: '',
        currentSectionIndex: 0,
        isSubmitted: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Erreur lors du chargement de la checklist: $e',
      ));
    }
  }

  void _onGoToSection(
    ChecklistGoToSection event,
    Emitter<ChecklistState> emit,
  ) {
    if (event.sectionIndex >= 0 && event.sectionIndex < state.totalPages) {
      emit(state.copyWith(currentSectionIndex: event.sectionIndex));
    }
  }

  String get _sessionId => '${state.checklist?.id ?? ''}_${state.serialNumber}';

  Future<void> _onUpdateResponse(
    ChecklistUpdateResponse event,
    Emitter<ChecklistState> emit,
  ) async {
    if (state.checklist == null) return;

    final existingResponse = state.responses[event.questionUuid];
    final now = DateTime.now();

    final newResponse = existingResponse?.copyWith(
          response: event.response,
          updatedAt: now,
        ) ??
        QuestionResponse(
          checklistId: _sessionId,
          questionUuid: event.questionUuid,
          response: event.response,
          createdAt: now,
          updatedAt: now,
        );

    final newResponses = Map<String, QuestionResponse>.from(state.responses);
    newResponses[event.questionUuid] = newResponse;

    emit(state.copyWith(responses: newResponses));

    try {
      await _checklistService.saveResponse(newResponse);
    } catch (e) {
      emit(state.copyWith(error: 'Erreur lors de la sauvegarde: $e'));
    }
  }

  Future<void> _onAddAttachment(
    ChecklistAddAttachment event,
    Emitter<ChecklistState> emit,
  ) async {
    if (state.checklist == null) return;

    emit(state.copyWith(isSaving: true));

    try {
      final filePath = await _checklistService.saveAttachment(
        _sessionId,
        event.questionUuid,
        event.file,
      );

      final existingResponse = state.responses[event.questionUuid];
      final now = DateTime.now();

      final newAttachments = existingResponse != null
          ? [...existingResponse.attachmentPaths, filePath]
          : [filePath];

      final newResponse = existingResponse?.copyWith(
            attachmentPaths: newAttachments,
            updatedAt: now,
          ) ??
          QuestionResponse(
            checklistId: _sessionId,
            questionUuid: event.questionUuid,
            attachmentPaths: newAttachments,
            createdAt: now,
            updatedAt: now,
          );

      final newResponses = Map<String, QuestionResponse>.from(state.responses);
      newResponses[event.questionUuid] = newResponse;

      emit(state.copyWith(responses: newResponses, isSaving: false));

      await _checklistService.saveResponse(newResponse);
    } catch (e) {
      emit(state.copyWith(
        isSaving: false,
        error: 'Erreur lors de l\'ajout de la pièce jointe: $e',
      ));
    }
  }

  Future<void> _onRemoveAttachment(
    ChecklistRemoveAttachment event,
    Emitter<ChecklistState> emit,
  ) async {
    if (state.checklist == null) return;

    final existingResponse = state.responses[event.questionUuid];
    if (existingResponse == null) return;

    try {
      await _checklistService.deleteAttachment(event.filePath);

      final newAttachments = existingResponse.attachmentPaths
          .where((p) => p != event.filePath)
          .toList();

      final newResponse = existingResponse.copyWith(
        attachmentPaths: newAttachments,
        updatedAt: DateTime.now(),
      );

      final newResponses = Map<String, QuestionResponse>.from(state.responses);
      newResponses[event.questionUuid] = newResponse;

      emit(state.copyWith(responses: newResponses));

      await _checklistService.saveResponse(newResponse);
    } catch (e) {
      emit(state.copyWith(error: 'Erreur lors de la suppression: $e'));
    }
  }

  Future<void> _onUpdateComment(
    ChecklistUpdateComment event,
    Emitter<ChecklistState> emit,
  ) async {
    if (state.checklist == null) return;

    final existingResponse = state.responses[event.questionUuid];
    final now = DateTime.now();

    final newResponse = existingResponse?.copyWith(
          comment: event.comment,
          updatedAt: now,
        ) ??
        QuestionResponse(
          checklistId: _sessionId,
          questionUuid: event.questionUuid,
          comment: event.comment,
          createdAt: now,
          updatedAt: now,
        );

    final newResponses = Map<String, QuestionResponse>.from(state.responses);
    newResponses[event.questionUuid] = newResponse;

    emit(state.copyWith(responses: newResponses));

    try {
      await _checklistService.saveResponse(newResponse);
    } catch (e) {
      emit(state.copyWith(error: 'Erreur lors de la sauvegarde: $e'));
    }
  }

  Future<void> _onSaveProgress(
    ChecklistSaveProgress event,
    Emitter<ChecklistState> emit,
  ) async {
    emit(state.copyWith(isSaving: true));

    try {
      for (final response in state.responses.values) {
        await _checklistService.saveResponse(response);
      }
      emit(state.copyWith(isSaving: false));
    } catch (e) {
      emit(state.copyWith(
        isSaving: false,
        error: 'Erreur lors de la sauvegarde: $e',
      ));
    }
  }

  Future<void> _onSubmit(
    ChecklistSubmit event,
    Emitter<ChecklistState> emit,
  ) async {
    emit(state.copyWith(isSaving: true));

    try {
      for (final response in state.responses.values) {
        await _checklistService.saveResponse(response);
      }
      emit(state.copyWith(isSaving: false, isSubmitted: true));
    } catch (e) {
      emit(state.copyWith(
        isSaving: false,
        error: 'Erreur lors de la soumission: $e',
      ));
    }
  }

  void _onUpdateSerialNumber(
    ChecklistUpdateSerialNumber event,
    Emitter<ChecklistState> emit,
  ) {
    emit(state.copyWith(serialNumber: event.serialNumber));
  }
}
