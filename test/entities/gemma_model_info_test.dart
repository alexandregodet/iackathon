import 'package:flutter_gemma/flutter_gemma.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:iackathon/domain/entities/gemma_model_info.dart';

void main() {
  group('GemmaModelInfo', () {
    test('creates model with required fields', () {
      const model = GemmaModelInfo(
        id: 'test_model',
        name: 'Test Model',
        description: 'A test model',
        url: 'https://example.com/model.task',
        filename: 'model.task',
        modelType: ModelType.gemmaIt,
        fileType: ModelFileType.task,
        sizeInMb: 500,
      );

      expect(model.id, 'test_model');
      expect(model.name, 'Test Model');
      expect(model.description, 'A test model');
      expect(model.url, 'https://example.com/model.task');
      expect(model.filename, 'model.task');
      expect(model.modelType, ModelType.gemmaIt);
      expect(model.fileType, ModelFileType.task);
      expect(model.sizeInMb, 500);
      expect(model.isMultimodal, false);
      expect(model.requiresAuth, false);
      expect(model.supportsThinking, false);
    });

    test('creates model with optional fields', () {
      const model = GemmaModelInfo(
        id: 'multimodal_model',
        name: 'Multimodal Model',
        description: 'A multimodal model',
        url: 'https://example.com/model.task',
        filename: 'model.task',
        modelType: ModelType.gemmaIt,
        fileType: ModelFileType.task,
        sizeInMb: 2000,
        isMultimodal: true,
        requiresAuth: true,
        supportsThinking: true,
      );

      expect(model.isMultimodal, true);
      expect(model.requiresAuth, true);
      expect(model.supportsThinking, true);
    });

    group('sizeLabel', () {
      test('returns Mo for sizes under 1000', () {
        const model = GemmaModelInfo(
          id: 'small',
          name: 'Small',
          description: 'Small model',
          url: 'url',
          filename: 'file',
          modelType: ModelType.gemmaIt,
          fileType: ModelFileType.task,
          sizeInMb: 500,
        );

        expect(model.sizeLabel, '500 Mo');
      });

      test('returns Go for sizes 1000 or more', () {
        const model = GemmaModelInfo(
          id: 'large',
          name: 'Large',
          description: 'Large model',
          url: 'url',
          filename: 'file',
          modelType: ModelType.gemmaIt,
          fileType: ModelFileType.task,
          sizeInMb: 2500,
        );

        expect(model.sizeLabel, '2.5 Go');
      });

      test('returns 1.0 Go for exactly 1000 Mo', () {
        const model = GemmaModelInfo(
          id: 'medium',
          name: 'Medium',
          description: 'Medium model',
          url: 'url',
          filename: 'file',
          modelType: ModelType.gemmaIt,
          fileType: ModelFileType.task,
          sizeInMb: 1000,
        );

        expect(model.sizeLabel, '1.0 Go');
      });
    });
  });

  group('AvailableModels', () {
    test('all returns all available models', () {
      final all = AvailableModels.all;

      expect(all, isNotEmpty);
      expect(all.length, 4);
      expect(all.map((m) => m.id), contains('gemma3_1b'));
      expect(all.map((m) => m.id), contains('gemma3n_e2b'));
      expect(all.map((m) => m.id), contains('gemma3n_e4b'));
      expect(all.map((m) => m.id), contains('deepseek_r1_1.5b'));
    });

    test('multimodal returns only multimodal models', () {
      final multimodal = AvailableModels.multimodal;

      expect(multimodal, isNotEmpty);
      for (final model in multimodal) {
        expect(model.isMultimodal, true);
      }
      expect(multimodal.length, 2);
    });

    test('textOnly returns only text models', () {
      final textOnly = AvailableModels.textOnly;

      expect(textOnly, isNotEmpty);
      for (final model in textOnly) {
        expect(model.isMultimodal, false);
      }
      expect(textOnly.length, 2);
    });

    test('thinkingModels returns models that support thinking', () {
      final thinking = AvailableModels.thinkingModels;

      expect(thinking, isNotEmpty);
      for (final model in thinking) {
        expect(model.supportsThinking, true);
      }
      expect(thinking.length, 1);
      expect(thinking.first.id, 'deepseek_r1_1.5b');
    });

    test('getById returns correct model', () {
      final model = AvailableModels.getById('gemma3_1b');

      expect(model, isNotNull);
      expect(model!.id, 'gemma3_1b');
      expect(model.name, 'Gemma 3 1B');
    });

    test('getById returns null for unknown id', () {
      final model = AvailableModels.getById('unknown_model');

      expect(model, isNull);
    });

    test('getById returns null for empty string', () {
      final model = AvailableModels.getById('');

      expect(model, isNull);
    });

    test('gemma3_1b has correct properties', () {
      const model = AvailableModels.gemma3_1b;

      expect(model.id, 'gemma3_1b');
      expect(model.name, 'Gemma 3 1B');
      expect(model.sizeInMb, 900);
      expect(model.isMultimodal, false);
      expect(model.supportsThinking, false);
      expect(model.modelType, ModelType.gemmaIt);
    });

    test('deepSeekR1 has correct properties', () {
      const model = AvailableModels.deepSeekR1;

      expect(model.id, 'deepseek_r1_1.5b');
      expect(model.name, 'DeepSeek R1 1.5B');
      expect(model.supportsThinking, true);
      expect(model.isMultimodal, false);
      expect(model.modelType, ModelType.deepSeek);
    });

    test('gemma3NanoE2b is multimodal', () {
      const model = AvailableModels.gemma3NanoE2b;

      expect(model.isMultimodal, true);
      expect(model.sizeInMb, 2000);
    });

    test('gemma3NanoE4b is multimodal', () {
      const model = AvailableModels.gemma3NanoE4b;

      expect(model.isMultimodal, true);
      expect(model.sizeInMb, 4000);
    });
  });
}
