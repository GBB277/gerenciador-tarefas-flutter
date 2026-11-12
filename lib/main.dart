import 'package:flutter/material.dart';

import 'controllers/task_controller.dart';
import 'screens/home_screen.dart';
import 'services/task_storage.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = TaskController(TaskStorage())..load();
  runApp(TaskApp(controller: controller));
}

class TaskApp extends StatelessWidget {
  const TaskApp({super.key, required this.controller});

  final TaskController controller;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gerenciador de Tarefas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: HomeScreen(controller: controller),
    );
  }
}
