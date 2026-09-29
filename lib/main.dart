import 'package:flutter/material.dart';
import 'package:personal_todo/app.dart';
import 'package:personal_todo/data/task_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = TaskRepository();
  await repository.init();
  runApp(TodoApp(repository: repository));
}
