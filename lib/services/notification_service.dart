import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:personal_todo/domain/task.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // New channel id so phones that already installed v1 get lock-screen capable settings.
  static const _channelId = 'task_reminders_lockscreen';
  static const _channelName = 'Task reminders';
  static const _channelDescription =
      'Reminders for scheduled tasks (shown on lock screen)';

  bool _ready = false;

  Future<void> init() async {
    tzdata.initializeTimeZones();
    await _configureLocalTimezone();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(initSettings);

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
      ),
    );

    _ready = true;
  }

  Future<void> _configureLocalTimezone() async {
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Kathmandu'));
    }
  }

  Future<bool> requestPermission() async {
    if (!_ready) return false;
    if (!Platform.isAndroid) return true;

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final notificationsEnabled =
        await android?.requestNotificationsPermission() ?? false;
    await android?.requestExactAlarmsPermission();
    return notificationsEnabled;
  }

  int notificationIdForTask(String taskId) {
    return taskId.hashCode & 0x7fffffff;
  }

  AndroidNotificationDetails get _androidDetails => const AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.max,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        fullScreenIntent: true,
        playSound: true,
        enableVibration: true,
        ticker: 'Task reminder',
      );

  Future<void> scheduleTaskReminder(Task task) async {
    if (!_ready) return;
    if (task.isCompleted) return;

    final when = task.scheduledAt;
    if (!when.isAfter(DateTime.now())) {
      return;
    }

    final id = notificationIdForTask(task.id);
    final scheduled = tz.TZDateTime.from(when, tz.local);

    await _plugin.zonedSchedule(
      id,
      task.title,
      task.description.isEmpty ? 'Task reminder' : task.description,
      scheduled,
      NotificationDetails(android: _androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelTaskReminder(String taskId) async {
    if (!_ready) return;
    await _plugin.cancel(notificationIdForTask(taskId));
  }

  /// Quick device test: fires a notification after [seconds].
  Future<void> scheduleTestNotification({int seconds = 10}) async {
    if (!_ready) return;

    final when = tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds));

    await _plugin.zonedSchedule(
      999001,
      'Test reminder',
      'Lock-screen notification test. If you see this while locked, it works.',
      when,
      NotificationDetails(android: _androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}
