# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**IAckathon** is a Flutter application implementing a local AI chat with on-device LLM (Gemma) and RAG (Retrieval-Augmented Generation), fully offline-capable once models are downloaded.

- **Package ID**: `com.iackathon.app`
- **Platforms**: Android (primary), Windows (experimental), Web (limited)
- **Min Android SDK**: 29 (Android 10)

## Essential Commands

### Code Generation
```bash
# Generate Drift database and Injectable DI code (REQUIRED after schema or DI changes)
dart run build_runner build --delete-conflicting-outputs

# Watch mode for continuous generation during development
dart run build_runner watch --delete-conflicting-outputs
```

### Running the App
```bash
# Android (check device ID first with: flutter devices)
flutter run -d <device_id>

# Windows
flutter run -d windows

# Release mode
flutter run --release
```

### Building
```bash
# Android APK (with ProGuard minification enabled in release)
flutter build apk

# Windows executable
flutter build windows
```

### Testing
```bash
# Run all unit tests
flutter test

# Run specific test file
flutter test test/blocs/chat_bloc_test.dart

# Run with coverage
flutter test --coverage

# Run integration tests (E2E)
flutter test integration_test/

# Run specific test suites
flutter test test/entities/
flutter test test/services/
flutter test test/performance/
```

### Linting
```bash
# Analyze code
flutter analyze

# Format code
dart format .
```

## Architecture

### Core Pattern: BLoC (Business Logic Component)
The app follows strict BLoC architecture with clear separation of concerns:

- **Presentation Layer** (`lib/presentation/`): UI components, pages, widgets
- **Business Logic** (`lib/presentation/blocs/`): BLoC classes managing state
- **Data Layer** (`lib/data/datasources/`): Services interfacing with external systems
- **Domain Layer** (`lib/domain/entities/`): Pure business entities (immutable, with copyWith)

### Dependency Injection
Uses `get_it` + `injectable` for DI. All services are annotated with `@singleton` or `@injectable` and registered in `lib/core/di/injection.dart`.

**Important**: After adding new injectable classes, regenerate code:
```bash
dart run build_runner build --delete-conflicting-outputs
```

### State Management Flow
1. UI dispatches events to BLoC (e.g., `ChatSendMessage`)
2. BLoC processes event, interacts with services
3. BLoC emits new state
4. UI rebuilds via `BlocBuilder` or `BlocListener`

Example pattern:
```dart
context.read<ChatBloc>().add(ChatSendMessage(text: message));
```

## Key Services

### GemmaService (lib/data/datasources/gemma_service.dart)
Manages the local LLM lifecycle:
- **Model states**: `notInstalled` → `downloading` → `installed` → `loading` → `ready`
- Downloads models from HuggingFace/custom CDN (~900MB for Gemma 3 1B)
- Handles inference chat sessions with streaming responses
- Supports multimodal models (text + image input)
- **Memory management**: Models consume ~500MB+ RAM when loaded. Use `unloadModel()` to free memory.

### RagService (lib/data/datasources/rag_service.dart)
Handles document processing and semantic search:
- Downloads EmbeddingGemma 300M model (~75MB) for embeddings
- Chunks PDFs (500 chars, 50 char overlap)
- Stores embeddings in SQLite vector store
- Performs similarity search (threshold 0.5) to augment prompts
- **Checklist JSON**: Loads `lib/asset/checklist.json` as RAG context for domain-specific knowledge

### ChatBloc (lib/presentation/blocs/chat/chat_bloc.dart)
Central BLoC orchestrating:
- Model download/load lifecycle
- Message streaming with thinking mode support
- Conversation persistence (Drift database)
- RAG integration (automatic context augmentation)
- Token usage estimation and context management

## Database (Drift)

Schema defined in `lib/data/datasources/database.dart`:

### Tables
- **Conversations**: id, title, createdAt, updatedAt
- **Messages**: id, conversationId, role, content, imageBytes, thinkingContent, createdAt
- **Documents**: id, name, filePath, totalChunks, isActive, createdAt
- **DocumentChunks**: id, documentId, content, chunkIndex
- **Embeddings**: chunkId, embedding (blob)
- **PromptTemplates**: id, name, content, category, createdAt

**After modifying schema**: Run `dart run build_runner build --delete-conflicting-outputs`

## flutter_gemma Integration

Version: `0.11.13`

### Supported Models
- Gemma2, Gemma3 (primary)
- TinyLlama, Llama, Phi, DeepSeek, Qwen

### Model Files
Located in `lib/domain/entities/gemma_model_info.dart`. Each model has:
- `filename`: HuggingFace identifier or filename
- `displayName`: User-facing name
- `size`: Display size
- `quantization`: e.g., "int4, GPU"
- `isMultimodal`: Vision support flag
- `supportsThinking`: Chain-of-thought reasoning flag

### Key Behaviors
- First launch triggers automatic model download (~900MB)
- Models cached in app-specific directory
- GPU acceleration via OpenCL (Android)
- Stream-based response generation
- System prompts prepended to first message in chat session

## Testing Structure

### Unit Tests (`test/`)
- **blocs/chat_bloc_test.dart**: Comprehensive BLoC testing with `bloc_test` package
- **entities/**: Tests for copyWith, equality, computed properties
- **services/**: Logic testing for RAG chunking, token estimation
- **performance/**: Benchmarks for document processing

### Integration Tests (`integration_test/`)
- Full E2E flow testing
- Mock services in `integration_test/mocks/`
- Test app setup in `integration_test/utils/test_app.dart`
- Tests cover: navigation, chat, RAG, multimodal, error handling, theme switching

**Important**: Integration tests use in-memory database and mock services to avoid real model downloads.

## Common Patterns

### Error Handling
Custom error hierarchy in `lib/core/errors/app_errors.dart`:
- `AppError`: Base class with `userMessage` for UI display
- `NetworkError`: Connectivity issues, download failures
- `RagError`: Document processing, embedding errors
- `ModelError`: LLM initialization, inference failures

Always log errors:
```dart
AppLogger.logAppError(error, 'ServiceName');
```

### Streaming Responses
GemmaService provides two streaming modes:
1. **Simple text**: `Stream<String>` via `generateStreamingResponse()`
2. **Thinking mode**: `Stream<GemmaStreamResponse>` with separate thinking/text chunks

ChatBloc handles both via `ChatStreamChunk` and `ChatThinkingChunk` events.

### Token Estimation
Token count estimated in `ChatState.estimatedTokensUsed`:
- Text: ~1 token per 4 characters
- Images: ~512 tokens per image
- Used for context window management (4096 token limit for Gemma 2B)

## Android Specifics

### Permissions (android/app/src/main/AndroidManifest.xml)
- `INTERNET`: Model downloads only
- `ACCESS_NETWORK_STATE`: Connectivity checks

### Build Configuration (android/app/build.gradle.kts)
- `minSdk = 29`
- `applicationId = "com.iackathon.app"`
- **Release build**: ProGuard enabled with custom rules in `proguard-rules.pro`
- `largeHeap = true` in manifest for LLM memory requirements

### ProGuard Rules
When adding new models or native libraries, update `android/app/proguard-rules.pro` to prevent minification issues.

## RAG Checklist Feature

The app loads a maritime inspection checklist from `lib/asset/checklist.json` to provide domain-specific RAG context. This JSON structure contains:
- Sections with compartment inspections
- Multiple-choice questions with validation rules
- Used to augment chat responses with industry-specific knowledge

When modifying checklist structure, ensure RagService can parse the updated schema.

## Development Guidelines

### Before Committing
1. Run `flutter analyze` - should have zero issues
2. Run `dart format .` - format all code
3. Ensure code generation is up to date: `dart run build_runner build --delete-conflicting-outputs`
4. Run tests: `flutter test`

### When Adding Dependencies
1. Update `pubspec.yaml`
2. Run `flutter pub get`
3. If using code generation, run build_runner

### When Modifying Database Schema
1. Edit tables in `database.dart`
2. Regenerate: `dart run build_runner build --delete-conflicting-outputs`
3. Consider migration path for existing users

### When Adding Injectable Services
1. Annotate with `@singleton` or `@injectable`
2. Register in `lib/core/di/injection.dart` if manual registration needed
3. Regenerate: `dart run build_runner build --delete-conflicting-outputs`

## Documentation

Docusaurus-based documentation in `docs/` directory:
```bash
cd docs
npm install
npm start  # Development server at http://localhost:3000
npm run build  # Production build
npm run serve  # Preview production build
```
