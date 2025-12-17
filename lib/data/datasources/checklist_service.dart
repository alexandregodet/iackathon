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
import '../../domain/entities/checklist_summary.dart';
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

      List<Map<String, dynamic>>? aiTags;
      if (row.aiTags != null && row.aiTags!.isNotEmpty) {
        aiTags = (json.decode(row.aiTags!) as List<dynamic>)
            .map((e) => e as Map<String, dynamic>)
            .toList();
      }

      Map<String, dynamic>? aiDefectBbox;
      if (row.aiDefectBbox != null && row.aiDefectBbox!.isNotEmpty) {
        aiDefectBbox = json.decode(row.aiDefectBbox!) as Map<String, dynamic>;
      }

      return QuestionResponse(
        id: row.id,
        checklistId: row.checklistId,
        questionUuid: row.questionUuid,
        serialNumber: row.serialNumber,
        response: row.response,
        attachmentPaths: attachments,
        comment: row.comment,
        aiTags: aiTags,
        aiDescription: row.aiDescription,
        aiDefectBbox: aiDefectBbox,
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

    List<Map<String, dynamic>>? aiTags;
    if (row.aiTags != null && row.aiTags!.isNotEmpty) {
      aiTags = (json.decode(row.aiTags!) as List<dynamic>)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    }

    Map<String, dynamic>? aiDefectBbox;
    if (row.aiDefectBbox != null && row.aiDefectBbox!.isNotEmpty) {
      aiDefectBbox = json.decode(row.aiDefectBbox!) as Map<String, dynamic>;
    }

    return QuestionResponse(
      id: row.id,
      checklistId: row.checklistId,
      questionUuid: row.questionUuid,
      serialNumber: row.serialNumber,
      response: row.response,
      attachmentPaths: attachments,
      comment: row.comment,
      aiTags: aiTags,
      aiDescription: row.aiDescription,
      aiDefectBbox: aiDefectBbox,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  Future<QuestionResponse> saveResponse(QuestionResponse response) async {
    final attachmentsJson = response.attachmentPaths.isNotEmpty
        ? json.encode(response.attachmentPaths)
        : null;

    final aiTagsJson = response.aiTags != null && response.aiTags!.isNotEmpty
        ? json.encode(response.aiTags)
        : null;

    final aiDefectBboxJson = response.aiDefectBbox != null
        ? json.encode(response.aiDefectBbox)
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
        serialNumber: Value(response.serialNumber),
        response: Value(response.response),
        attachmentPaths: Value(attachmentsJson),
        comment: Value(response.comment),
        aiTags: Value(aiTagsJson),
        aiDescription: Value(response.aiDescription),
        aiDefectBbox: Value(aiDefectBboxJson),
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
              serialNumber: Value(response.serialNumber),
              response: Value(response.response),
              attachmentPaths: Value(attachmentsJson),
              comment: Value(response.comment),
              aiTags: Value(aiTagsJson),
              aiDescription: Value(response.aiDescription),
              aiDefectBbox: Value(aiDefectBboxJson),
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

  /// Recupere tous les resumes de checklists completees, groupees par session
  Future<List<ChecklistSummary>> getCompletedChecklists() async {
    // Get all responses ordered by updatedAt desc
    final rows = await (_database.select(_database.checklistResponses)
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();

    // Group responses by checklistId
    final Map<String, List<ChecklistResponse>> grouped = {};
    for (final row in rows) {
      grouped.putIfAbsent(row.checklistId, () => []).add(row);
    }

    final summaries = <ChecklistSummary>[];

    for (final entry in grouped.entries) {
      final checklistId = entry.key;
      final responses = entry.value;

      if (responses.isEmpty) continue;

      // Extract checklist title from checklistId (format: checklistName_serialNumber)
      final parts = checklistId.split('_');
      final checklistTitle = parts.isNotEmpty ? parts.first : checklistId;

      // Get serial number from responses or from checklistId
      String serialNumber = parts.length > 1 ? parts.sublist(1).join('_') : '';
      for (final r in responses) {
        if (r.serialNumber != null && r.serialNumber!.isNotEmpty) {
          serialNumber = r.serialNumber!;
          break;
        }
      }

      // Get latest update date
      DateTime completedAt = responses.first.createdAt;
      for (final r in responses) {
        if (r.updatedAt.isAfter(completedAt)) {
          completedAt = r.updatedAt;
        }
      }

      // Count filled fields
      int filledFields = 0;
      for (final r in responses) {
        if (r.response != null && r.response!.isNotEmpty) {
          filledFields++;
        }
      }

      // Collect all unique tags from all responses
      final allTags = <String>{};
      for (final response in responses) {
        if (response.aiTags != null && response.aiTags!.isNotEmpty) {
          try {
            final tagsList = json.decode(response.aiTags!) as List<dynamic>;
            for (final tagData in tagsList) {
              if (tagData is Map<String, dynamic>) {
                final tag = tagData['tag'] as String?;
                if (tag != null && tag.isNotEmpty) {
                  allTags.add(tag);
                }
              }
            }
          } catch (_) {
            // Ignore JSON parsing errors
          }
        }
      }

      summaries.add(ChecklistSummary(
        checklistId: checklistId,
        checklistTitle: checklistTitle,
        serialNumber: serialNumber,
        completedAt: completedAt,
        totalFields: responses.length,
        filledFields: filledFields,
        allTags: allTags.toList(),
      ));
    }

    // Sort by completedAt descending
    summaries.sort((a, b) => b.completedAt.compareTo(a.completedAt));

    return summaries;
  }

  /// Recherche les checklists qui contiennent un tag specifique
  Future<List<ChecklistSummary>> searchByTag(String tag) async {
    final allSummaries = await getCompletedChecklists();
    final searchLower = tag.toLowerCase();

    return allSummaries.where((summary) {
      return summary.allTags.any(
        (t) => t.toLowerCase().contains(searchLower),
      );
    }).toList();
  }
}
