import 'package:flutter/material.dart';
import 'package:personal_todo/data/task_repository.dart';
import 'package:personal_todo/features/today/today_page.dart';

class TodoApp extends StatelessWidget {
  const TodoApp({super.key, required this.repository});

  final TaskRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal Todo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1F6F5F),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      home: TodayPage(repository: repository),
    );
  }
}
