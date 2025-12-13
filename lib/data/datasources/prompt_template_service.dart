import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import 'database.dart';

@singleton
class PromptTemplateService {
  final AppDatabase _db;

  PromptTemplateService(this._db);

  Future<List<PromptTemplate>> getAllTemplates() async {
    return await _db.select(_db.promptTemplates).get();
  }

  Stream<List<PromptTemplate>> watchAllTemplates() {
    return _db.select(_db.promptTemplates).watch();
  }

  Future<List<PromptTemplate>> getTemplatesByCategory(String category) async {
    return await (_db.select(_db.promptTemplates)
          ..where((t) => t.category.equals(category)))
        .get();
  }

  Future<PromptTemplate> createTemplate({
    required String name,
    required String content,
    String? category,
  }) async {
    final id = await _db.into(_db.promptTemplates).insert(
          PromptTemplatesCompanion.insert(
            name: name,
            content: content,
            category: Value(category),
          ),
        );
    return await (_db.select(_db.promptTemplates)
          ..where((t) => t.id.equals(id)))
        .getSingle();
  }

  Future<void> updateTemplate({
    required int id,
    required String name,
    required String content,
    String? category,
  }) async {
    await (_db.update(_db.promptTemplates)..where((t) => t.id.equals(id)))
        .write(
      PromptTemplatesCompanion(
        name: Value(name),
        content: Value(content),
        category: Value(category),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteTemplate(int id) async {
    await (_db.delete(_db.promptTemplates)..where((t) => t.id.equals(id))).go();
  }

  Future<List<String>> getAllCategories() async {
    final templates = await getAllTemplates();
    final categories = templates
        .map((t) => t.category)
        .where((c) => c != null)
        .cast<String>()
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }
}
