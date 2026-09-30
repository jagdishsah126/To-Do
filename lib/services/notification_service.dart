import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:personal_todo/domain/app_settings.dart';
import 'package:personal_todo/domain/task.dart';
import 'package:personal_todo/services/warning_service.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

typedef NotificationActionHandler = Future<void> Function(
  String actionId,
  String? taskId,
);

class NotificationService {
  NotificationService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'task_reminders_lockscreen';
  static const _channelName = 'Task reminders';
  static const _channelDescription =
      'Reminders for scheduled tasks (shown on lock screen)';

  static const actionComplete = 'complete';
  static const actionSnooze = 'snooze';
  static const actionSkip = 'skip';

  bool _ready = false;
  NotificationActionHandler? onAction;

  Future<void> init({NotificationActionHandler? actionHandler}) async {
    onAction = actionHandler;
    tzdata.initializeTimeZones();
    await _configureLocalTimezone();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) async {
        await onAction?.call(response.actionId ?? 'tap', response.payload);
      },
      onDidReceiveBackgroundNotificationResponse: (response) async {
        await onAction?.call(response.actionId ?? 'tap', response.payload);
      },
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        showBadge: true,
        sound: const RawResourceAndroidNotificationSound('notification'),
        enableLights: true,
        ledColor: const Color(0xFF00D4AA),
        ledOnMs: 1000,
        ledOffMs: 500,
      ),
    );

    _ready = true;
  }

  Future<void> _configureLocalTimezone() async {
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (e) {
      tz.setLocalLocation(tz.getLocation('Asia/Kathmandu'));
      WarningService.instance.logWarning('Notification', 'Failed to get local timezone, using Asia/Kathmandu', e);
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

  Future<bool> areNotificationsEnabled() async {
    if (!_ready) return false;
    if (!Platform.isAndroid) return true;

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.areNotificationsEnabled() ?? false;
  }

  Future<void> cancelAll() async {
    if (!_ready) return;
    await _plugin.cancelAll();
  }

  Future<List<int>> getPendingNotificationIds() async {
    if (!_ready) return [];
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final pending = await android?.pendingNotificationRequests() ?? [];
    return pending.map((r) => r.id).toList();
  }

  int notificationIdForTask(String taskId) {
    var hash = 0;
    for (var i = 0; i < taskId.length; i++) {
      hash = ((hash << 5) - hash) + taskId.codeUnitAt(i);
      hash = hash & 0x7fffffff;
    }
    return hash;
  }

  AndroidNotificationDetails get _androidDetails => AndroidNotificationDetails(
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
        actions: <AndroidNotificationAction>[
          const AndroidNotificationAction(
            actionComplete,
            'Complete',
            showsUserInterface: false,
          ),
          const AndroidNotificationAction(
            actionSnooze,
            'Snooze',
            showsUserInterface: false,
          ),
          const AndroidNotificationAction(
            actionSkip,
            'Skip',
            showsUserInterface: false,
          ),
        ],
      );

  DateTime _applyQuietHours(DateTime when, AppSettings settings) {
    if (!settings.quietHoursEnabled) return when;
    if (settings.quietStartMinute == settings.quietEndMinute) return when;

    final minutes = when.hour * 60 + when.minute;
    final start = settings.quietStartMinute;
    final end = settings.quietEndMinute;

    bool inQuiet;
    if (start < end) {
      inQuiet = minutes >= start && minutes < end;
    } else {
      inQuiet = minutes >= start || minutes < end;
    }
    if (!inQuiet) return when;

    // Push to quiet end same day or next day.
    final endHour = end ~/ 60;
    final endMinute = end % 60;
    var adjusted = DateTime(when.year, when.month, when.day, endHour, endMinute);
    if (!adjusted.isAfter(when)) {
      adjusted = adjusted.add(const Duration(days: 1));
    }
    return adjusted;
  }

  Future<void> scheduleTaskReminder(Task task, {AppSettings? settings}) async {
    if (!_ready) return;
    if (task.isCompleted) return;
    if (settings != null && !settings.notificationsEnabled) return;

    final enabled = await areNotificationsEnabled();
    if (!enabled) return;

    var when = task.reminderAt;
    if (settings != null) {
      when = _applyQuietHours(when, settings);
    }
    if (!when.isAfter(DateTime.now())) return;

    final scheduled = tz.TZDateTime.from(when, tz.local);
    await _plugin.zonedSchedule(
      notificationIdForTask(task.id),
      task.title,
      task.description.isEmpty ? 'Task reminder' : task.description,
      scheduled,
      NotificationDetails(android: _androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: task.id,
    );
  }

  Future<void> cancelTaskReminder(String taskId) async {
    if (!_ready) return;
    await _plugin.cancel(notificationIdForTask(taskId));
  }

  Future<void> rescheduleAll(List<Task> tasks, AppSettings settings) async {
    await Future.wait(
      tasks.map((task) async {
        await cancelTaskReminder(task.id);
        await scheduleTaskReminder(task, settings: settings);
      }),
    );
  }

  Future<void> scheduleTestNotification({int seconds = 10}) async {
    if (!_ready) return;
    final when = tz.TZDateTime.now(tz.local).add(Duration(seconds: seconds));
    await _plugin.zonedSchedule(
      999001,
      'Test reminder',
      'Lock-screen notification test.',
      when,
      NotificationDetails(android: _androidDetails),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}
