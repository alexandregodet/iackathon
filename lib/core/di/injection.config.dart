// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../../data/datasources/checklist_service.dart' as _i307;
import '../../data/datasources/database.dart' as _i104;
import '../../data/datasources/gemma_service.dart' as _i363;
import '../../data/datasources/prompt_template_service.dart' as _i933;
import '../../data/datasources/rag_service.dart' as _i909;
import '../../data/datasources/settings_service.dart' as _i462;
import '../../data/datasources/tts_service.dart' as _i119;
import '../../presentation/blocs/chat/chat_bloc.dart' as _i142;
import '../../presentation/blocs/checklist/checklist_bloc.dart' as _i407;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    gh.singleton<_i104.AppDatabase>(() => _i104.AppDatabase());
    gh.singleton<_i363.GemmaService>(() => _i363.GemmaService());
    gh.singleton<_i909.RagService>(() => _i909.RagService());
    gh.singleton<_i462.SettingsService>(() => _i462.SettingsService());
    gh.singleton<_i119.TtsService>(() => _i119.TtsService());
    gh.singleton<_i933.PromptTemplateService>(
      () => _i933.PromptTemplateService(gh<_i104.AppDatabase>()),
    );
    gh.factory<_i142.ChatBloc>(
      () => _i142.ChatBloc(
        gh<_i363.GemmaService>(),
        gh<_i909.RagService>(),
        gh<_i104.AppDatabase>(),
      ),
    );
    gh.singleton<_i307.ChecklistService>(
      () => _i307.ChecklistService(gh<_i104.AppDatabase>()),
    );
    gh.factory<_i407.ChecklistBloc>(
      () => _i407.ChecklistBloc(
        gh<_i307.ChecklistService>(),
        gh<_i363.GemmaService>(),
      ),
    );
    return this;
  }
}
