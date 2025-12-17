import 'dart:convert';
import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../data/datasources/checklist_service.dart';
import '../../../data/datasources/gemma_service.dart';
import '../../../domain/entities/checklist_response.dart';
import '../../../domain/entities/gemma_model_info.dart';
import 'checklist_event.dart';
import 'checklist_state.dart';

@injectable
class ChecklistBloc extends Bloc<ChecklistEvent, ChecklistState> {
  final ChecklistService _checklistService;
  final GemmaService _gemmaService;

  ChecklistBloc(this._checklistService, this._gemmaService)
      : super(const ChecklistState()) {
    on<ChecklistLoadFromAsset>(_onLoadFromAsset);
    on<ChecklistGoToSection>(_onGoToSection);
    on<ChecklistUpdateResponse>(_onUpdateResponse);
    on<ChecklistAddAttachment>(_onAddAttachment);
    on<ChecklistRemoveAttachment>(_onRemoveAttachment);
    on<ChecklistUpdateComment>(_onUpdateComment);
    on<ChecklistSaveProgress>(_onSaveProgress);
    on<ChecklistSubmit>(_onSubmit);
    on<ChecklistUpdateSerialNumber>(_onUpdateSerialNumber);
    on<ChecklistAnalyzeWithAI>(_onAnalyzeWithAI);
    on<ChecklistUpdateTags>(_onUpdateTags);
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
          serialNumber: state.serialNumber,
          response: event.response,
          updatedAt: now,
        ) ??
        QuestionResponse(
          checklistId: _sessionId,
          questionUuid: event.questionUuid,
          serialNumber: state.serialNumber,
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
            serialNumber: state.serialNumber,
            attachmentPaths: newAttachments,
            updatedAt: now,
          ) ??
          QuestionResponse(
            checklistId: _sessionId,
            questionUuid: event.questionUuid,
            serialNumber: state.serialNumber,
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
        serialNumber: state.serialNumber,
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
          serialNumber: state.serialNumber,
          comment: event.comment,
          updatedAt: now,
        ) ??
        QuestionResponse(
          checklistId: _sessionId,
          questionUuid: event.questionUuid,
          serialNumber: state.serialNumber,
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

  /// Prompt pour l'analyse IA des défauts - peut être modifié selon les besoins
  static const String _aiAnalysisPrompt = '''Tu es un assistant de maintenance industrielle qui analyse une photo d'intervention et son contexte. Objectif: identifier le défaut principal visible et générer 3 à 5 tags en français pour le décrire. Priorité visuelle: si la photo contient un encadré/surlignage/cadre indiquant la zone du défaut, analyse uniquement cette zone et ignore le reste; sinon analyse l'ensemble et concentre-toi sur le défaut le plus saillant. Contraintes tags: total 3 à 5; au moins 2 tags courts (1 à 2 mots) et au moins 2 tags sous forme de phrase (5 à 12 mots); tags concrets orientés défaut/symptôme; éviter doublons, variations de casse, et termes vagues (ex "problème", "anomalie"). Sortie: retourner uniquement un JSON valide sans autre texte, format: {"tags":[{"tag":"string","type":"mot_cle|phrase","bbox":{"x":0,"y":0,"w":0,"h":0} }], "defect_bbox":{"x":0,"y":0,"w":0,"h":0}, "description":"Paragraphe en français décrivant l'image et le défaut dans son contexte."} Règles bbox: coordonnées en pixels dans l'image d'origine, (x,y) coin haut-gauche, w largeur, h hauteur; defect_bbox = meilleure estimation de la zone du défaut; chaque tag peut reprendre defect_bbox ou une sous-zone; si indéterminable avec confiance, mettre defect_bbox=null et bbox=null.''';

  Future<void> _onAnalyzeWithAI(
    ChecklistAnalyzeWithAI event,
    Emitter<ChecklistState> emit,
  ) async {
    // Mark question as being analyzed
    final analyzing = Set<String>.from(state.analyzingQuestions)
      ..add(event.questionUuid);
    emit(state.copyWith(analyzingQuestions: analyzing));

    try {
      // Ensure model is ready before analysis
      if (!_gemmaService.isReady) {
        // Always check model status to get accurate state
        await _gemmaService.checkModelStatus(AvailableModels.gemma3NanoE4b);

        // If model is not installed, download it (tries local first, then CDN)
        if (_gemmaService.state == GemmaModelState.notInstalled) {
          await _gemmaService.downloadModel(AvailableModels.gemma3NanoE4b);
        }

        // Load the model into memory
        if (_gemmaService.state == GemmaModelState.installed) {
          await _gemmaService.loadModel(AvailableModels.gemma3NanoE4b);
        }

        // Final check - if still not ready, throw error
        if (!_gemmaService.isReady) {
          throw Exception('Impossible de charger le modèle IA');
        }
      }

      // Read image bytes
      final imageFile = File(event.imagePath);
      final imageBytes = await imageFile.readAsBytes();

      // Build the prompt with context
      final prompt = '''$_aiAnalysisPrompt

Entrées contextuelles: section_title=${event.sectionTitle}; section_description=${event.sectionDescription}; question=${event.questionTitle}; suggestion=${event.questionHint ?? ''}; answer=${event.answer}; image=<image attachée>.''';

      // Generate response with image
      final responseBuffer = StringBuffer();
      await for (final chunk
          in _gemmaService.generateResponse(prompt, imageBytes: imageBytes)) {
        responseBuffer.write(chunk);
      }

      final responseText = responseBuffer.toString().trim();

      // Try to parse JSON from response
      AiAnalysisResult? result;
      try {
        // Find JSON in response (might have extra text)
        final jsonStart = responseText.indexOf('{');
        final jsonEnd = responseText.lastIndexOf('}');
        if (jsonStart != -1 && jsonEnd != -1 && jsonEnd > jsonStart) {
          final jsonStr = responseText.substring(jsonStart, jsonEnd + 1);
          final jsonData = json.decode(jsonStr) as Map<String, dynamic>;
          result = AiAnalysisResult.fromJson(jsonData);
        }
      } catch (e) {
        // If JSON parsing fails, create a simple result with the response as description
        result = AiAnalysisResult(
          tags: [],
          description: responseText,
        );
      }

      if (result != null) {
        final newResults =
            Map<String, AiAnalysisResult>.from(state.aiAnalysisResults);
        newResults[event.questionUuid] = result;

        final newAnalyzing = Set<String>.from(state.analyzingQuestions)
          ..remove(event.questionUuid);

        // Update the response with AI-generated metadata
        final existingResponse = state.responses[event.questionUuid];
        final now = DateTime.now();

        final newResponse = existingResponse?.copyWith(
              serialNumber: state.serialNumber,
              comment: result.description,
              aiTags: result.tags,
              aiDescription: result.description,
              aiDefectBbox: result.defectBbox,
              updatedAt: now,
            ) ??
            QuestionResponse(
              checklistId: _sessionId,
              questionUuid: event.questionUuid,
              serialNumber: state.serialNumber,
              comment: result.description,
              aiTags: result.tags,
              aiDescription: result.description,
              aiDefectBbox: result.defectBbox,
              createdAt: now,
              updatedAt: now,
            );

        final newResponses = Map<String, QuestionResponse>.from(state.responses);
        newResponses[event.questionUuid] = newResponse;

        emit(state.copyWith(
          analyzingQuestions: newAnalyzing,
          aiAnalysisResults: newResults,
          responses: newResponses,
        ));

        // Save the updated response with AI metadata
        await _checklistService.saveResponse(newResponse);
      }
    } catch (e) {
      final newAnalyzing = Set<String>.from(state.analyzingQuestions)
        ..remove(event.questionUuid);

      emit(state.copyWith(
        analyzingQuestions: newAnalyzing,
        error: 'Erreur lors de l\'analyse IA: $e',
      ));
    }
  }

  Future<void> _onUpdateTags(
    ChecklistUpdateTags event,
    Emitter<ChecklistState> emit,
  ) async {
    if (state.checklist == null) return;

    try {
      // Find the first response to store the consolidated tags
      // We'll store all tags on the first response that exists
      String? targetQuestionUuid;
      for (final section in state.checklist!.answers.sections) {
        for (final question in section.questions) {
          if (state.responses.containsKey(question.uuid)) {
            targetQuestionUuid = question.uuid;
            break;
          }
        }
        if (targetQuestionUuid != null) break;
      }

      if (targetQuestionUuid == null) return;

      final existingResponse = state.responses[targetQuestionUuid];
      if (existingResponse == null) return;

      final now = DateTime.now();
      final newResponse = existingResponse.copyWith(
        aiTags: event.tags,
        updatedAt: now,
      );

      final newResponses = Map<String, QuestionResponse>.from(state.responses);
      newResponses[targetQuestionUuid] = newResponse;

      emit(state.copyWith(responses: newResponses));

      await _checklistService.saveResponse(newResponse);
    } catch (e) {
      emit(state.copyWith(error: 'Erreur lors de la sauvegarde des tags: $e'));
    }
  }
}
