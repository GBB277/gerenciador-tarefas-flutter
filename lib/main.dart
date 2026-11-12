import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'controllers/task_controller.dart';
import 'controllers/theme_controller.dart';
import 'screens/home_screen.dart';
import 'services/task_storage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = TaskController(TaskStorage())..load();
  final themeController = ThemeController()..load();
  runApp(TaskApp(controller: controller, themeController: themeController));
}

ThemeData buildTheme(Brightness brightness) {
  return ThemeData(
    useMaterial3: true,
    // Cor base do app. Troque por Colors.teal e salve para ver o hot reload.
    colorSchemeSeed: Colors.indigo,
    brightness: brightness,
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
    ),
  );
}

class TaskApp extends StatelessWidget {
  const TaskApp({
    super.key,
    required this.controller,
    required this.themeController,
  });

  final TaskController controller;
  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, child) {
        return MaterialApp(
          title: 'Tarefas',
          debugShowCheckedModeBanner: false,
          // Português do Brasil no calendário, botões e textos do sistema.
          locale: const Locale('pt', 'BR'),
          supportedLocales: const [Locale('pt', 'BR')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          themeMode: themeController.mode,
          home: HomeScreen(
            controller: controller,
            themeController: themeController,
          ),
        );
      },
    );
  }
}
