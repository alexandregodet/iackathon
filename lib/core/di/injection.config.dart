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

import '../../data/datasources/database.dart' as _i104;
import '../../data/datasources/gemma_service.dart' as _i363;
import '../../presentation/blocs/chat/chat_bloc.dart' as _i142;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    gh.singleton<_i104.AppDatabase>(() => _i104.AppDatabase());
    gh.singleton<_i363.GemmaService>(() => _i363.GemmaService());
    gh.factory<_i142.ChatBloc>(() => _i142.ChatBloc(gh<_i363.GemmaService>()));
    return this;
  }
}
