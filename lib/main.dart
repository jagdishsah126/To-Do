import 'package:flutter/material.dart';
import 'package:personal_todo/app.dart';
import 'package:personal_todo/data/task_repository.dart';
import 'package:personal_todo/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final repository = TaskRepository();
  await repository.init();

  final notifications = NotificationService();
  await notifications.init();
  await notifications.requestPermission();

  runApp(
    TodoApp(
      repository: repository,
      notifications: notifications,
    ),
  );
}
