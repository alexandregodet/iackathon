import 'package:flutter/material.dart';
import 'package:flutter_gemma/flutter_gemma.dart';

import 'core/di/injection.dart';
import 'core/theme/app_theme.dart';
import 'presentation/pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterGemma.initialize();
  await configureDependencies();
  runApp(const IackathonApp());
}

class IackathonApp extends StatelessWidget {
  const IackathonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IAckathon',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const HomePage(),
    );
  }
}
