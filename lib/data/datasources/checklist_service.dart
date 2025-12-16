import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/checklist.dart';
import '../../domain/entities/checklist_response.dart';
import 'database.dart';

@singleton
class ChecklistService {
  final AppDatabase _database;

  ChecklistService(this._database);

  Future<Checklist> loadChecklist(String assetPath) async {
    final jsonString = await rootBundle.loadString(assetPath);
    final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
    return Checklist.fromJson(jsonMap);
  }

  Future<List<QuestionResponse>> loadResponses(String checklistId) async {
    final rows = await (_database.select(_database.checklistResponses)
          ..where((t) => t.checklistId.equals(checklistId)))
        .get();

    return rows.map((row) {
      List<String> attachments = [];
      if (row.attachmentPaths != null && row.attachmentPaths!.isNotEmpty) {
        attachments = (json.decode(row.attachmentPaths!) as List<dynamic>).cast<String>();
      }
      return QuestionResponse(
        id: row.id,
        checklistId: row.checklistId,
        questionUuid: row.questionUuid,
        response: row.response,
        attachmentPaths: attachments,
        comment: row.comment,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );
    }).toList();
  }

  Future<QuestionResponse?> loadResponse(String checklistId, String questionUuid) async {
    final rows = await (_database.select(_database.checklistResponses)
          ..where((t) => t.checklistId.equals(checklistId) & t.questionUuid.equals(questionUuid)))
        .get();

    if (rows.isEmpty) return null;
    final row = rows.first;

    List<String> attachments = [];
    if (row.attachmentPaths != null && row.attachmentPaths!.isNotEmpty) {
      attachments = (json.decode(row.attachmentPaths!) as List<dynamic>).cast<String>();
    }

    return QuestionResponse(
      id: row.id,
      checklistId: row.checklistId,
      questionUuid: row.questionUuid,
      response: row.response,
      attachmentPaths: attachments,
      comment: row.comment,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  Future<QuestionResponse> saveResponse(QuestionResponse response) async {
    final attachmentsJson = response.attachmentPaths.isNotEmpty
        ? json.encode(response.attachmentPaths)
        : null;

    final existingRows = await (_database.select(_database.checklistResponses)
          ..where((t) =>
              t.checklistId.equals(response.checklistId) &
              t.questionUuid.equals(response.questionUuid)))
        .get();
    final existingRow = existingRows.isNotEmpty ? existingRows.first : null;

    if (existingRow != null) {
      await (_database.update(_database.checklistResponses)
            ..where((t) => t.id.equals(existingRow.id)))
          .write(ChecklistResponsesCompanion(
        response: Value(response.response),
        attachmentPaths: Value(attachmentsJson),
        comment: Value(response.comment),
        updatedAt: Value(DateTime.now()),
      ));

      return response.copyWith(
        id: existingRow.id,
        updatedAt: DateTime.now(),
      );
    } else {
      final id = await _database.into(_database.checklistResponses).insert(
            ChecklistResponsesCompanion.insert(
              checklistId: response.checklistId,
              questionUuid: response.questionUuid,
              response: Value(response.response),
              attachmentPaths: Value(attachmentsJson),
              comment: Value(response.comment),
            ),
          );

      return response.copyWith(
        id: id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  Future<String> saveAttachment(String checklistId, String questionUuid, XFile file) async {
    final appDir = await getApplicationDocumentsDirectory();
    final attachmentsDir = Directory(p.join(appDir.path, 'checklist_attachments', checklistId));
    if (!await attachmentsDir.exists()) {
      await attachmentsDir.create(recursive: true);
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = p.extension(file.path);
    final fileName = '${questionUuid}_$timestamp$extension';
    final destPath = p.join(attachmentsDir.path, fileName);

    await file.saveTo(destPath);

    return destPath;
  }

  Future<void> deleteAttachment(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> deleteAllResponses(String checklistId) async {
    final responses = await loadResponses(checklistId);
    for (final response in responses) {
      for (final attachmentPath in response.attachmentPaths) {
        await deleteAttachment(attachmentPath);
      }
    }

    await (_database.delete(_database.checklistResponses)
          ..where((t) => t.checklistId.equals(checklistId)))
        .go();
  }
}
