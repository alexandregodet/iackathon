import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'injection.config.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureDependencies() async => getIt.init();

/// Reset GetIt for testing purposes
Future<void> resetGetIt() async {
  await getIt.reset();
}

/// Check if GetIt is ready (has registered services)
bool get isGetItReady => getIt.isRegistered<Object>();
