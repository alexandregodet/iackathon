---
sidebar_position: 6
title: Base de donnees
description: Schema et utilisation de Drift pour la persistance
---

# Base de donnees

IAckathon utilise **Drift** (anciennement Moor) pour la persistance des donnees dans une base SQLite locale.

## Vue d'ensemble

```dart
@DriftDatabase(tables: [Conversations, Messages, Documents, PromptTemplates])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;
}
```

## Schema

### Tables

#### Conversations

Stocke les metadonnees des conversations :

```dart
class Conversations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 255)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
```

#### Messages

Stocke les messages de chaque conversation :

```dart
class Messages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get conversationId =>
      integer().references(Conversations, #id, onDelete: KeyAction.cascade)();
  TextColumn get role => text().withLength(min: 1, max: 50)();
  TextColumn get content => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
```

#### Documents

Metadonnees des documents PDF importes :

```dart
class Documents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get filePath => text()();
  IntColumn get totalChunks => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastUsedAt => dateTime().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();
}
```

#### PromptTemplates

Modeles de prompts sauvegardes :

```dart
class PromptTemplates extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get content => text()();
  TextColumn get category => text().withLength(min: 1, max: 50).nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
```

## Diagramme des relations

```
+------------------+       +------------------+
|  Conversations   |       |    Documents     |
+------------------+       +------------------+
| id (PK)          |       | id (PK)          |
| title            |       | name             |
| createdAt        |       | filePath         |
| updatedAt        |       | totalChunks      |
+------------------+       | isActive         |
        |                  +------------------+
        | 1:N
        v
+------------------+       +------------------+
|    Messages      |       | PromptTemplates  |
+------------------+       +------------------+
| id (PK)          |       | id (PK)          |
| conversationId   |       | name             |
| role             |       | content          |
| content          |       | category         |
| createdAt        |       | createdAt        |
+------------------+       +------------------+
```

## Connexion

### Production

```dart
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'iackathon.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
```

### Tests

```dart
// Constructeur pour les tests avec base en memoire
AppDatabase.forTesting(super.executor);

// Usage dans les tests
final testDb = AppDatabase.forTesting(NativeDatabase.memory());
```

## Migrations

Gestion des mises a jour du schema :

```dart
@override
MigrationStrategy get migration {
  return MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        // Migration v1 -> v2 : ajout table Documents
        await m.createTable(documents);
      }
      if (from < 3) {
        // Migration v2 -> v3 : ajout table PromptTemplates
        await m.createTable(promptTemplates);
      }
    },
  );
}
```

## Queries courantes

### Conversations

```dart
// Toutes les conversations (plus recentes d'abord)
Future<List<Conversation>> getAllConversations() {
  return (select(conversations)
    ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
    .get();
}

// Creer une conversation
Future<int> createConversation(String title) {
  return into(conversations).insert(
    ConversationsCompanion.insert(title: title),
  );
}

// Mettre a jour le titre
Future<void> updateConversationTitle(int id, String title) {
  return (update(conversations)..where((t) => t.id.equals(id)))
      .write(ConversationsCompanion(
        title: Value(title),
        updatedAt: Value(DateTime.now()),
      ));
}

// Supprimer (les messages sont supprimes en cascade)
Future<void> deleteConversation(int id) {
  return (delete(conversations)..where((t) => t.id.equals(id))).go();
}
```

### Messages

```dart
// Messages d'une conversation
Future<List<Message>> getMessagesForConversation(int conversationId) {
  return (select(messages)
    ..where((t) => t.conversationId.equals(conversationId))
    ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
    .get();
}

// Ajouter un message
Future<int> insertMessage({
  required int conversationId,
  required String role,
  required String content,
}) {
  return into(messages).insert(
    MessagesCompanion.insert(
      conversationId: conversationId,
      role: role,
      content: content,
    ),
  );
}
```

### Documents

```dart
// Documents actifs
Future<List<Document>> getActiveDocuments() {
  return (select(documents)..where((d) => d.isActive.equals(true))).get();
}

// Toggle activation
Future<void> toggleDocumentActive(int id, bool isActive) {
  return (update(documents)..where((d) => d.id.equals(id)))
      .write(DocumentsCompanion(isActive: Value(isActive)));
}
```

### PromptTemplates

```dart
// Stream de tous les templates (reactive)
Stream<List<PromptTemplate>> watchAllTemplates() {
  return select(promptTemplates).watch();
}

// Creer un template
Future<PromptTemplate> createTemplate({
  required String name,
  required String content,
  String? category,
}) async {
  final id = await into(promptTemplates).insert(
    PromptTemplatesCompanion.insert(
      name: name,
      content: content,
      category: Value(category),
    ),
  );
  return (select(promptTemplates)..where((t) => t.id.equals(id))).getSingle();
}
```

## Streams reactifs

Drift supporte les streams pour les mises a jour en temps reel :

```dart
// Dans un widget
StreamBuilder<List<PromptTemplate>>(
  stream: database.watchAllTemplates(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) {
      return const CircularProgressIndicator();
    }

    final templates = snapshot.data!;
    return ListView.builder(
      itemCount: templates.length,
      itemBuilder: (context, index) => TemplateCard(templates[index]),
    );
  },
)
```

## Generation de code

Le code des queries est genere automatiquement :

```bash
# Generer le code
flutter pub run build_runner build

# En mode watch (regeneration automatique)
flutter pub run build_runner watch
```

Fichiers generes :
- `database.g.dart` : Classes de donnees et methodes de query

## Bonnes pratiques

### 1. Utiliser des transactions

```dart
Future<void> createConversationWithMessage(
  String title,
  String message,
) async {
  await transaction(() async {
    final convId = await createConversation(title);
    await insertMessage(
      conversationId: convId,
      role: 'user',
      content: message,
    );
  });
}
```

### 2. Fermer la base correctement

```dart
@override
Future<void> close() async {
  // Cleanup si necessaire
  await super.close();
}
```

### 3. Gerer les erreurs

```dart
try {
  await database.insertMessage(...);
} on SqliteException catch (e) {
  if (e.extendedResultCode == 19) {
    // Violation de contrainte
  }
  rethrow;
}
```
