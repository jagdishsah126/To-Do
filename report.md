# Personal Todo — Comprehensive Bug & Code Quality Report

**Project:** Personal Todo (Flutter)  
**Version:** 1.1.0+4  
**Analysis Date:** 2026-09-30  
**Files Analyzed:** 30+ source files (Dart, Kotlin, Gradle, XML, YAML, Markdown)

---

## Table of Contents

1. [Critical Bugs](#critical-bugs)
2. [High Severity Bugs](#high-severity-bugs)
3. [Medium Severity Bugs](#medium-severity-bugs)
4. [Low Severity Issues](#low-severity-issues)
5. [Architecture & Design Issues](#architecture--design-issues)
6. [Missing Features (Planned but Not Implemented)](#missing-features-planned-but-not-implemented)
7. [Security Concerns](#security-concerns)
8. [Performance Issues](#performance-issues)
9. [Testing Gaps](#testing-gaps)
10. [Summary & Recommendations](#summary--recommendations)

---

## Critical Bugs

### BUG-001: `seriesId` Not Propagated to Next Occurrences

**File:** `lib/data/task_repository.dart`  
**Lines:** 147-159, 174-186  
**Severity:** Critical

**Description:**  
When `complete()` or `skip()` generates the next occurrence of a recurring task, the `seriesId` is not passed to `createTask()`. The `createTask()` method sets `seriesId = id` (the new task's own ID) when `recurrence.isRecurring` is true. This means **each occurrence becomes its own series**, breaking the series linkage.

**Impact:**
- Cannot track which occurrences belong to the same series
- Cannot implement "edit this and future occurrences" (V1.2 feature)
- Cannot display occurrence history for a recurring task
- Data model is fundamentally broken for recurring tasks

**Current Code:**
```dart
// Line 150-158 in complete()
return createTask(
  title: task.title,
  description: task.description,
  scheduledAt: nextAt,
  priority: task.priority,
  categoryId: task.categoryId,
  recurrence: task.recurrence,
  reminderMinutesBefore: task.reminderMinutesBefore,
  // BUG: seriesId is not passed!
);
```

**Fix:**
```dart
return createTask(
  title: task.title,
  description: task.description,
  scheduledAt: nextAt,
  priority: task.priority,
  categoryId: task.categoryId,
  recurrence: task.recurrence,
  reminderMinutesBefore: task.reminderMinutesBefore,
  seriesId: task.seriesId ?? task.id,  // Pass the original seriesId
);
```

Also need to add `seriesId` parameter to `createTask()`:
```dart
Future<Task> createTask({
  // ... existing params ...
  String? seriesId,
}) async {
  final now = DateTime.now();
  final id = AppDatabase.instance.uuid.v4();
  final task = Task(
    // ... existing fields ...
    seriesId: seriesId ?? (recurrence.isRecurring ? id : null),
    // ...
  );
  // ...
}
```

---

### BUG-002: `replaceAll()` Not Wrapped in Transaction

**File:** `lib/data/task_repository.dart`  
**Lines:** 232-240  
**Severity:** Critical

**Description:**  
The `replaceAll()` method deletes all tasks and inserts new ones in a batch, but **does not wrap the operation in a transaction**. If the batch fails partway through (e.g., due to a constraint violation or disk error), the database will be in an **inconsistent state** — some tasks deleted but not all new ones inserted.

**Impact:**
- Data loss on import failure
- Corrupted database state
- No rollback capability

**Current Code:**
```dart
Future<void> replaceAll(List<Task> tasks) async {
  final db = await _db;
  final batch = db.batch();
  batch.delete('tasks');
  for (final task in tasks) {
    batch.insert('tasks', task.toMap());
  }
  await batch.commit(noResult: true);
}
```

**Fix:**
```dart
Future<void> replaceAll(List<Task> tasks) async {
  final db = await _db;
  await db.transaction((txn) async {
    await txn.delete('tasks');
    for (final task in tasks) {
      await txn.insert('tasks', task.toMap());
    }
  });
}
```

Same issue exists in `CategoryRepository.replaceAll()` (lines 287-295).

---

### BUG-003: `applyMissedPolicy` with `moveTomorrow` Fails at Month/Year Boundaries

**File:** `lib/data/task_repository.dart`  
**Lines:** 261-271  
**Severity:** Critical

**Description:**  
When `MissedTaskPolicy.moveTomorrow` is applied, the code constructs a DateTime using `now.day + 1`. This fails when today is the **last day of the month** (e.g., Jan 31 → Feb 1, but `DateTime(2026, 1, 32, ...)` is invalid and will throw or produce unexpected results).

**Impact:**
- App crashes or produces incorrect dates at month boundaries
- Missed tasks not properly moved to tomorrow

**Current Code:**
```dart
case MissedTaskPolicy.moveTomorrow:
  final moved = DateTime(
    now.year,
    now.month,
    now.day + 1,  // BUG: Fails on last day of month
    task.scheduledAt.hour,
    task.scheduledAt.minute,
  );
```

**Fix:**
```dart
case MissedTaskPolicy.moveTomorrow:
  final tomorrow = DateTime(now.year, now.month, now.day)
      .add(const Duration(days: 1));
  final moved = DateTime(
    tomorrow.year,
    tomorrow.month,
    tomorrow.day,
    task.scheduledAt.hour,
    task.scheduledAt.minute,
  );
```

---

### BUG-004: Notification Action Handler Has No Exception Handling

**File:** `lib/main.dart`  
**Lines:** 25-51  
**Severity:** Critical

**Description:**  
The notification action handler in `main()` performs async database operations and notification scheduling without any try/catch. If any operation throws (e.g., database error, notification permission revoked), the exception is **unhandled** and could crash the app or leave the database in an inconsistent state.

**Impact:**
- App crashes when notification action fails
- Database inconsistency (e.g., task marked completed but notification not scheduled)
- Poor user experience

**Current Code:**
```dart
actionHandler: (actionId, taskId) async {
  if (taskId == null || taskId.isEmpty) return;
  final settings = await settingsRepo.load();
  switch (actionId) {
    case NotificationService.actionComplete:
      await notifications.cancelTaskReminder(taskId);
      final next = await tasks.complete(taskId);
      if (next != null) {
        await notifications.scheduleTaskReminder(next, settings: settings);
      }
    // ... no try/catch
  }
},
```

**Fix:**
```dart
actionHandler: (actionId, taskId) async {
  try {
    if (taskId == null || taskId.isEmpty) return;
    final settings = await settingsRepo.load();
    switch (actionId) {
      case NotificationService.actionComplete:
        await notifications.cancelTaskReminder(taskId);
        final next = await tasks.complete(taskId);
        if (next != null) {
          await notifications.scheduleTaskReminder(next, settings: settings);
        }
      case NotificationService.actionSnooze:
        await notifications.cancelTaskReminder(taskId);
        final snoozed = await tasks.snooze(taskId, const Duration(minutes: 10));
        if (snoozed != null) {
          await notifications.scheduleTaskReminder(snoozed, settings: settings);
        }
      case NotificationService.actionSkip:
        await notifications.cancelTaskReminder(taskId);
        final next = await tasks.skip(taskId);
        if (next != null) {
          await notifications.scheduleTaskReminder(next, settings: settings);
        }
    }
  } catch (e) {
    // Log error, optionally show a notification about the failure
    debugPrint('Notification action failed: $e');
  }
},
```

---

### BUG-005: `_applyQuietHours` Infinite Loop When Start Equals End

**File:** `lib/services/notification_service.dart`  
**Lines:** 119-142  
**Severity:** Critical

**Description:**  
If `quietStartMinute == quietEndMinute` (e.g., both set to 22:30), the quiet period becomes **24 hours**. The condition `minutes >= start || minutes < end` is always true, so every notification is considered "in quiet hours". The adjustment pushes to `endHour:endMinute` which equals the start, causing the notification to be pushed to the next day, which is also in quiet hours, creating an **infinite loop** of delays.

**Impact:**
- Notifications never fire if quiet hours are misconfigured
- User misses all reminders

**Current Code:**
```dart
DateTime _applyQuietHours(DateTime when, AppSettings settings) {
  if (!settings.quietHoursEnabled) return when;

  final minutes = when.hour * 60 + when.minute;
  final start = settings.quietStartMinute;
  final end = settings.quietEndMinute;

  bool inQuiet;
  if (start < end) {
    inQuiet = minutes >= start && minutes < end;
  } else {
    inQuiet = minutes >= start || minutes < end;  // BUG: Always true when start == end
  }
  // ...
}
```

**Fix:**
```dart
DateTime _applyQuietHours(DateTime when, AppSettings settings) {
  if (!settings.quietHoursEnabled) return when;
  if (settings.quietStartMinute == settings.quietEndMinute) return when; // No quiet period

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
```

---

### BUG-006: Task Editor Forces Both Date and Time Pickers

**File:** `lib/features/task_editor/task_editor_page.dart`  
**Lines:** 210-213  
**Severity:** Critical (UX)

**Description:**  
The date/time ListTile's `onTap` handler calls both `_pickDate()` and `_pickTime()` sequentially. The user **must** pick both a date and a time every time they tap, even if they only want to change one. This is frustrating UX and slows down task creation.

**Impact:**
- Poor user experience
- Slower task creation
- Users may abandon task creation

**Current Code:**
```dart
ListTile(
  contentPadding: EdgeInsets.zero,
  title: const Text('Date & time'),
  subtitle: Text(bsLabel),
  trailing: const Icon(Icons.edit_calendar),
  onTap: () async {
    await _pickDate();
    await _pickTime();  // BUG: Always shows both pickers
  },
),
```

**Fix:**
```dart
ListTile(
  contentPadding: EdgeInsets.zero,
  title: const Text('Date & time'),
  subtitle: Text(bsLabel),
  trailing: const Icon(Icons.edit_calendar),
  onTap: () async {
    await _pickDate();
  },
),
// Add a separate time picker
ListTile(
  contentPadding: EdgeInsets.zero,
  title: const Text('Time'),
  subtitle: Text(_time.format(context)),
  trailing: const Icon(Icons.access_time),
  onTap: () async {
    await _pickTime();
  },
),
```

---

## High Severity Bugs

### BUG-007: Pages List Recreated on Every Build

**File:** `lib/app.dart`  
**Lines:** 51-102  
**Severity:** High

**Description:**  
The `pages` list is created inside the `build()` method. Every time `setState()` is called (e.g., when `_refresh()` is triggered), all four page widgets are **recreated from scratch**, even if their data hasn't changed. This causes unnecessary widget rebuilds and potential state loss in the pages.

**Impact:**
- Unnecessary widget rebuilds
- Potential state loss in pages (e.g., scroll position, form data)
- Performance degradation

**Current Code:**
```dart
@override
Widget build(BuildContext context) {
  final pages = [
    TodayPage(key: ValueKey('today-$_token'), ...),
    UpcomingPage(key: ValueKey('upcoming-$_token'), ...),
    CalendarPage(key: ValueKey('calendar-$_token'), ...),
    SettingsPage(...),
  ];
  // ...
}
```

**Fix:**
```dart
class _TodoAppState extends State<TodoApp> {
  late AppSettings _settings = widget.initialSettings;
  int _index = 0;
  int _token = 0;

  void _refresh() => setState(() => _token++);

  late final List<Widget> _pages = [
    TodayPage(
      key: ValueKey('today-$_token'),
      tasks: widget.tasks,
      categories: widget.categories,
      notifications: widget.notifications,
      settings: _settings,
      onChanged: _refresh,
      onOpenSearch: () async { ... },
    ),
    UpcomingPage(
      key: ValueKey('upcoming-$_token'),
      tasks: widget.tasks,
      categories: widget.categories,
      notifications: widget.notifications,
      settings: _settings,
      onChanged: _refresh,
    ),
    CalendarPage(
      key: ValueKey('calendar-$_token'),
      tasks: widget.tasks,
      categories: widget.categories,
      notifications: widget.notifications,
      settings: _settings,
      onChanged: _refresh,
    ),
    SettingsPage(
      settingsRepo: widget.settingsRepo,
      notifications: widget.notifications,
      backup: widget.backup,
      tasks: widget.tasks,
      settings: _settings,
      onSettingsChanged: (value) {
        setState(() => _settings = value);
        _refresh();
      },
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ...
      home: Scaffold(
        body: _pages[_index],
        // ...
      ),
    );
  }
}
```

---

### BUG-008: No Undo for Swipe-to-Delete

**File:** `lib/features/common/task_tile.dart`  
**Lines:** 39-48  
**Severity:** High

**Description:**  
The `Dismissible` widget's `onDismissed` callback immediately calls `onDelete()`, which permanently deletes the task. There is **no undo mechanism**. If a user accidentally swipes a task, it's gone forever.

**Impact:**
- Data loss from accidental deletion
- Poor user experience
- No recovery mechanism

**Current Code:**
```dart
return Dismissible(
  key: ValueKey(task.id),
  direction: DismissDirection.endToStart,
  background: Container(
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    color: Theme.of(context).colorScheme.error,
    child: const Icon(Icons.delete, color: Colors.white),
  ),
  onDismissed: (_) => onDelete(),  // BUG: No undo
  child: Card(...),
);
```

**Fix:**
```dart
onDismissed: (_) async {
  await onDelete();
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${task.title} deleted'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            // Restore the task
            await widget.tasks.createTask(
              title: task.title,
              description: task.description,
              scheduledAt: task.scheduledAt,
              priority: task.priority,
              categoryId: task.categoryId,
              recurrence: task.recurrence,
              reminderMinutesBefore: task.reminderMinutesBefore,
            );
          },
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }
},
```

---

### BUG-009: Notification ID Collision Risk

**File:** `lib/services/notification_service.dart`  
**Line:** 86  
**Severity:** High

**Description:**  
The notification ID is computed as `taskId.hashCode & 0x7fffffff`. While this ensures a positive integer, **hash code collisions are possible**. If two different task IDs produce the same hash code (after masking), one task's notification will **overwrite** the other's.

**Impact:**
- One task's notification replaces another's
- User misses reminders
- Difficult to debug

**Current Code:**
```dart
int notificationIdForTask(String taskId) => taskId.hashCode & 0x7fffffff;
```

**Fix:**
Use a deterministic mapping stored in the database, or use a more robust hash:
```dart
int notificationIdForTask(String taskId) {
  // Use a simple but effective hash combination
  var hash = 0;
  for (var i = 0; i < taskId.length; i++) {
    hash = ((hash << 5) - hash) + taskId.codeUnitAt(i);
    hash = hash & 0x7fffffff;
  }
  return hash;
}
```

Or better, store the notification ID in the task record itself.

---

### BUG-010: Backup Import No Version Validation

**File:** `lib/data/backup_service.dart`  
**Lines:** 64-70  
**Severity:** High

**Description:**  
The `importFromPicker()` method validates the `app` field but **does not check the `version` field**. If the backup format changes in the future (e.g., v2 with different fields), importing an old backup could fail silently or produce incorrect data.

**Impact:**
- Silent data corruption when importing incompatible backups
- No migration path for backup format changes

**Current Code:**
```dart
if (decoded['app'] != 'personal_todo') {
  throw const FormatException('Not a Personal Todo backup.');
}
// BUG: No version check
```

**Fix:**
```dart
if (decoded['app'] != 'personal_todo') {
  throw const FormatException('Not a Personal Todo backup.');
}
final version = decoded['version'];
if (version != 1) {
  throw FormatException('Unsupported backup version: $version');
}
```

---

### BUG-011: `openSheet` Doesn't Refresh UI After Actions

**File:** `lib/features/common/task_actions.dart`  
**Lines:** 41-181  
**Severity:** High

**Description:**  
After performing an action from the bottom sheet (Complete, Snooze, Skip, Reschedule, Edit, Delete), the UI is **not refreshed**. The user must navigate away and back to see the updated state. This is because the `openSheet` method doesn't call any refresh callback.

**Impact:**
- UI shows stale data
- User confusion
- Poor user experience

**Current Code:**
```dart
static Future<void> openSheet({
  required BuildContext context,
  required TaskRepository tasks,
  required CategoryRepository categories,
  required NotificationService notifications,
  required AppSettings settings,
  required Task task,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ... actions that don't refresh UI
          ],
        ),
      );
    },
  );
}
```

**Fix:**
Add a `VoidCallback? onChanged` parameter and call it after each action:
```dart
static Future<void> openSheet({
  required BuildContext context,
  required TaskRepository tasks,
  required CategoryRepository categories,
  required NotificationService notifications,
  required AppSettings settings,
  required Task task,
  VoidCallback? onChanged,  // Add this
}) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ...
            ListTile(
              leading: const Icon(Icons.check_circle_outline),
              title: Text(task.isCompleted ? 'Mark upcoming' : 'Complete'),
              onTap: () async {
                Navigator.pop(context);
                await toggleComplete(...);
                onChanged?.call();  // Add this
              },
            ),
            // ... same for other actions
          ],
        ),
      );
    },
  );
}
```

---

### BUG-012: `getUpcoming` Excludes Overdue Tasks

**File:** `lib/data/task_repository.dart`  
**Lines:** 29-44  
**Severity:** High

**Description:**  
The `getUpcoming()` method uses `DateTime.now()` as the start of the query range. This means **overdue tasks** (scheduled before now but not completed) are excluded from the Upcoming view. Users may miss overdue tasks that they haven't completed yet.

**Impact:**
- Overdue tasks not visible in Upcoming view
- Users may forget about overdue tasks

**Current Code:**
```dart
Future<List<Task>> getUpcoming({int days = 7}) async {
  final start = DateTime.now();  // BUG: Excludes overdue tasks
  final end = DateTime(start.year, start.month, start.day)
      .add(Duration(days: days + 1));
  final rows = await (await _db).query(
    'tasks',
    where: 'scheduled_at >= ? AND scheduled_at < ? AND status != ?',
    whereArgs: [
      start.toIso8601String(),
      end.toIso8601String(),
      TaskStatus.completed.name,
    ],
    orderBy: 'scheduled_at ASC',
  );
  return rows.map(Task.fromMap).toList();
}
```

**Fix:**
```dart
Future<List<Task>> getUpcoming({int days = 7}) async {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);  // Start from beginning of today
  final end = start.add(Duration(days: days + 1));
  final rows = await (await _db).query(
    'tasks',
    where: 'scheduled_at >= ? AND scheduled_at < ? AND status NOT IN (?, ?)',
    whereArgs: [
      start.toIso8601String(),
      end.toIso8601String(),
      TaskStatus.completed.name,
      TaskStatus.skipped.name,
    ],
    orderBy: 'scheduled_at ASC',
  );
  return rows.map(Task.fromMap).toList();
}
```

---

## Medium Severity Bugs

### BUG-013: `_nextWeekday` Fallback Returns Incorrect Day

**File:** `lib/services/recurrence_engine.dart`  
**Lines:** 36-52  
**Severity:** Medium

**Description:**  
The `_nextWeekday` method has a fallback that returns `from.add(const Duration(days: 1))` if no matching weekday is found within 14 days. This could return a day that's **not in the weekdays list**, causing the recurrence to skip a day incorrectly.

**Impact:**
- Recurrence skips a day incorrectly
- User misses a scheduled task

**Current Code:**
```dart
DateTime _nextWeekday(DateTime from, List<int> weekdays) {
  final sorted = [...weekdays]..sort();
  var cursor = from.add(const Duration(days: 1));
  for (var i = 0; i < 14; i++) {
    if (sorted.contains(cursor.weekday)) {
      return DateTime(
        cursor.year,
        cursor.month,
        cursor.day,
        from.hour,
        from.minute,
      );
    }
    cursor = cursor.add(const Duration(days: 1));
  }
  return from.add(const Duration(days: 1));  // BUG: Could return non-matching day
}
```

**Fix:**
```dart
DateTime _nextWeekday(DateTime from, List<int> weekdays) {
  if (weekdays.isEmpty) return from.add(const Duration(days: 1));
  final sorted = [...weekdays]..sort();
  var cursor = from.add(const Duration(days: 1));
  for (var i = 0; i < 14; i++) {
    if (sorted.contains(cursor.weekday)) {
      return DateTime(
        cursor.year,
        cursor.month,
        cursor.day,
        from.hour,
        from.minute,
      );
    }
    cursor = cursor.add(const Duration(days: 1));
  }
  // Fallback: return the first matching weekday from the next week
  return cursor;
}
```

---

### BUG-014: Settings Save Reschedules All Reminders Unnecessarily

**File:** `lib/features/settings/settings_page.dart`  
**Lines:** 46-52  
**Severity:** Medium

**Description:**  
Every time a setting is changed, `_save()` calls `rescheduleAll()` which cancels and reschedules **all pending notifications**. This is inefficient and causes unnecessary notification churn, especially when changing non-notification settings like theme or date display.

**Impact:**
- Unnecessary notification churn
- Performance degradation
- Potential notification flicker

**Current Code:**
```dart
Future<void> _save(AppSettings next) async {
  setState(() => _settings = next);
  await widget.settingsRepo.save(next);
  widget.onSettingsChanged(next);
  final pending = await widget.tasks.getPendingReminders();
  await widget.notifications.rescheduleAll(pending, next);  // BUG: Always reschedules
}
```

**Fix:**
```dart
Future<void> _save(AppSettings next) async {
  final notificationSettingsChanged = 
      next.notificationsEnabled != _settings.notificationsEnabled ||
      next.quietHoursEnabled != _settings.quietHoursEnabled ||
      next.quietStartMinute != _settings.quietStartMinute ||
      next.quietEndMinute != _settings.quietEndMinute;
  
  setState(() => _settings = next);
  await widget.settingsRepo.save(next);
  widget.onSettingsChanged(next);
  
  if (notificationSettingsChanged) {
    final pending = await widget.tasks.getPendingReminders();
    await widget.notifications.rescheduleAll(pending, next);
  }
}
```

---

### BUG-015: Calendar `_countForDay` is O(n*m) Complexity

**File:** `lib/features/calendar/calendar_page.dart`  
**Lines:** 77-86  
**Severity:** Medium

**Description:**  
The `_countForDay()` method iterates through all tasks for each day of the month. For a month with 30 days and 100 tasks, this results in **3,000 comparisons**. This could cause performance issues with large task lists.

**Impact:**
- Slow calendar rendering with many tasks
- UI jank

**Current Code:**
```dart
int _countForDay(int day) {
  final bs = NepaliDateTime(_month.year, _month.month, day);
  final start = bs.toDateTime();
  final end = start.add(const Duration(days: 1));
  return _monthTasks
      .where(
        (t) => !t.scheduledAt.isBefore(start) && t.scheduledAt.isBefore(end),
      )
      .length;
}
```

**Fix:**
Pre-compute a map of day -> count:
```dart
Map<int, int> get _taskCountByDay {
  final map = <int, int>{};
  for (final task in _monthTasks) {
    final bs = BsDateHelper.toBs(task.scheduledAt);
    if (bs.year == _month.year && bs.month == _month.month) {
      map[bs.day] = (map[bs.day] ?? 0) + 1;
    }
  }
  return map;
}

// In build():
final count = _taskCountByDay[day] ?? 0;
```

---

### BUG-016: Today Page Doesn't Update Overdue Tasks

**File:** `lib/features/today/today_page.dart`  
**Lines:** 34-50  
**Severity:** Medium

**Description:**  
Overdue tasks are only updated when the app starts (via `applyMissedPolicy` in `main.dart`). When the Today page is viewed, it doesn't check for newly overdue tasks. If a task becomes overdue while the app is open, it won't be moved to the "OVERDUE" section until the app is restarted.

**Impact:**
- Overdue tasks not visible in Today view
- Stale UI

**Fix:**
Add a check in `_reload()`:
```dart
Future<void> _reload() async {
  final cats = await widget.categories.getAll();
  // Check for newly overdue tasks
  await widget.tasks.applyMissedPolicy(widget.settings.missedPolicy);
  setState(() {
    _categoryMap = {for (final c in cats) c.id: c};
    _future = widget.tasks.getTasksForDay(DateTime.now());
  });
}
```

---

### BUG-017: `search` is Case-Sensitive for Non-ASCII Characters

**File:** `lib/data/task_repository.dart`  
**Lines:** 56-66  
**Severity:** Medium

**Description:**  
The `search()` method uses SQL `LIKE` which is case-insensitive for ASCII characters by default in SQLite, but **case-sensitive for non-ASCII characters** (e.g., Nepali text). This means searching for Nepali task titles may not work correctly.

**Impact:**
- Search misses results for non-ASCII text
- Poor search experience for Nepali users

**Fix:**
Use `LOWER()` for case-insensitive search:
```dart
Future<List<Task>> search(String query) async {
  final q = '%${query.trim().toLowerCase()}%';
  final rows = await (await _db).query(
    'tasks',
    where: 'LOWER(title) LIKE ? OR LOWER(description) LIKE ?',
    whereArgs: [q, q],
    orderBy: 'scheduled_at DESC',
    limit: 100,
  );
  return rows.map(Task.fromMap).toList();
}
```

---

### BUG-018: `rescheduleAll` is Sequential

**File:** `lib/services/notification_service.dart`  
**Lines:** 172-177  
**Severity:** Medium

**Description:**  
The `rescheduleAll()` method iterates through tasks sequentially, calling `cancelTaskReminder()` and `scheduleTaskReminder()` for each one. For large task lists, this could be slow.

**Impact:**
- Slow rescheduling with many tasks
- UI freeze during rescheduling

**Fix:**
Use `Future.wait()` for parallel processing:
```dart
Future<void> rescheduleAll(List<Task> tasks, AppSettings settings) async {
  await Future.wait(
    tasks.map((task) async {
      await cancelTaskReminder(task.id);
      await scheduleTaskReminder(task, settings: settings);
    }),
  );
}
```

---

### BUG-019: Task Editor Doesn't Validate Past Dates

**File:** `lib/features/task_editor/task_editor_page.dart`  
**Lines:** 116-170  
**Severity:** Medium

**Description:**  
The task editor allows saving tasks with past dates. While the task is saved, the notification won't be scheduled (because `scheduleTaskReminder` checks `if (!when.isAfter(DateTime.now())) return;`). This could confuse users who wonder why they didn't receive a notification.

**Impact:**
- User confusion
- Silent failure of notifications

**Fix:**
Add validation in `_save()`:
```dart
Future<void> _save() async {
  if (!_formKey.currentState!.validate()) return;
  if (_recurrenceType == RecurrenceType.selectedWeekdays && _weekdays.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Select at least one weekday.')),
    );
    return;
  }
  if (_scheduledAt.isBefore(DateTime.now())) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cannot schedule tasks in the past.')),
    );
    return;
  }
  // ... rest of save logic
}
```

---

### BUG-020: `markUpcoming` Doesn't Cancel Existing Notification

**File:** `lib/data/task_repository.dart`  
**Lines:** 216-222  
**Severity:** Medium

**Description:**  
When `markUpcoming()` is called (e.g., when un-completing a task), it updates the task status but **doesn't cancel any existing notification**. If the task was previously snoozed or rescheduled, the old notification may still fire.

**Impact:**
- Stale notifications fire
- User confusion

**Fix:**
This is actually handled by the caller in `task_actions.dart` (line 21 calls `scheduleTaskReminder` after `markUpcoming`), but the repository method should be documented to make this clear, or the caller should be responsible for canceling the old notification.

---

## Low Severity Issues

### BUG-021: `getTasksForDay` Uses `DateTime.now()` Instead of Parameter

**File:** `lib/features/today/today_page.dart`  
**Line:** 48  
**Severity:** Low

**Description:**  
The `_reload()` method calls `getTasksForDay(DateTime.now())`, which is correct, but the method signature accepts a `DateTime day` parameter that could be used for testing or future flexibility. Currently, it's always called with `DateTime.now()`.

**Impact:**
- Minor: Less testable
- Minor: Less flexible

---

### BUG-022: `BsDateHelper.daysInMonth` Creates Unnecessary DateTime Objects

**File:** `lib/core/bs_date.dart`  
**Lines:** 37-43  
**Severity:** Low

**Description:**  
The `daysInMonth()` method creates two `NepaliDateTime` objects and calculates the difference. This is correct but could be optimized.

**Impact:**
- Minor performance overhead
- Negligible in practice

---

### BUG-023: `Task.copyWith` Doesn't Allow Clearing `seriesId`

**File:** `lib/domain/task.dart`  
**Lines:** 42-70  
**Severity:** Low

**Description:**  
The `copyWith` method has a `clearCategory` parameter to allow clearing the category, but there's no equivalent for `seriesId`. This could be needed if a recurring task is converted to a non-recurring task.

**Impact:**
- Minor: Can't clear seriesId when converting recurring to non-recurring

**Fix:**
```dart
Task copyWith({
  // ... existing params ...
  bool clearSeries = false,
}) {
  return Task(
    // ... existing fields ...
    seriesId: clearSeries ? null : (seriesId ?? this.seriesId),
    // ...
  );
}
```

---

### BUG-024: `AppSettings` Doesn't Validate Snooze Minutes

**File:** `lib/domain/app_settings.dart`  
**Lines:** 68-87  
**Severity:** Low

**Description:**  
The `fromStorageMap` factory parses `snoozeMinutes` from a comma-separated string but doesn't validate that the values are positive or within a reasonable range. A corrupted settings file could produce invalid snooze durations.

**Impact:**
- Minor: Could produce invalid snooze durations
- Minor: No input validation

---

### BUG-025: `Category` Default Icon Code Point May Not Exist

**File:** `lib/domain/category.dart`  
**Line:** 6  
**Severity:** Low

**Description:**  
The default `iconCodePoint` is `0xe57f`, which is a Material Icons code point. However, this code point may not exist in all versions of the Material Icons font, which could cause a placeholder icon to be displayed.

**Impact:**
- Minor: Icon may not display correctly
- Minor: Inconsistent across devices

---

### BUG-026: `AndroidManifest.xml` Missing `SCHEDULE_EXACT_ALARM` Permission for Android 12+

**File:** `android/app/src/main/AndroidManifest.xml`  
**Line:** 5  
**Severity:** Low

**Description:**  
The `SCHEDULE_EXACT_ALARM` permission is declared, but on Android 12+ (API 31+), this permission is **not granted by default** and must be requested at runtime. The app does request it via `requestExactAlarmsPermission()`, but the manifest should also include `USE_EXACT_ALARM` for apps that require exact alarms.

**Impact:**
- Minor: Exact alarms may not work on Android 12+
- Minor: User may need to grant permission manually

---

### BUG-027: `gradle.properties` Uses Deprecated `android.newDsl` Flag

**File:** `android/gradle.properties`  
**Line:** 6  
**Severity:** Low

**Description:**  
The `android.newDsl=false` property is deprecated in newer versions of AGP. This could cause warnings or issues when upgrading.

**Impact:**
- Minor: Deprecation warning
- Minor: Future compatibility

---

### BUG-028: `pubspec.lock` Should Not Be Manually Edited

**File:** `pubspec.lock`  
**Severity:** Low

**Description:**  
The `pubspec.lock` file is auto-generated and should not be manually edited. It's good that it's committed to the repository (for reproducible builds), but it should be noted that manual edits could cause issues.

**Impact:**
- Minor: Potential for merge conflicts
- Minor: Auto-generated file

---

## Architecture & Design Issues

### ARCH-001: No State Management Library

**Description:**  
The app uses a simple `_token` + `ValueKey` pattern to force widget rebuilds. While this works for a small app, it doesn't scale well and can lead to bugs (e.g., unnecessary rebuilds, state loss).

**Recommendation:**  
Consider using Riverpod or Bloc for state management, as recommended in the Plan.md.

---

### ARCH-002: No Dependency Injection Framework

**Description:**  
All dependencies are created in `main()` and passed down through the widget tree. This makes testing difficult and leads to verbose constructor parameters.

**Recommendation:**  
Consider using `get_it` or `injectable` for dependency injection, or use Riverpod providers.

---

### ARCH-003: No Routing Library

**Description:**  
The app uses direct `Navigator.push` for navigation. This works for 4 pages but doesn't scale well for deep linking or nested navigation.

**Recommendation:**  
Consider using GoRouter for declarative navigation, as recommended in the Plan.md.

---

### ARCH-004: Database Schema Not Using Drift

**Description:**  
The app uses raw `sqflite` instead of the recommended Drift. This means:
- No type-safe queries
- No compile-time validation
- Manual schema management
- More boilerplate code

**Recommendation:**  
Consider migrating to Drift for type-safe database access.

---

### ARCH-005: No Error Handling Strategy

**Description:**  
There is no centralized error handling strategy. Each widget handles errors independently (or not at all). This leads to inconsistent error messages and poor user experience.

**Recommendation:**  
Implement a centralized error handling strategy with user-friendly error messages.

---

### ARCH-006: No Logging

**Description:**  
The app has no logging mechanism. When errors occur, they are either silently ignored or shown to the user via SnackBar. There's no way to debug issues in production.

**Recommendation:**  
Add a logging package (e.g., `logger`) and log errors to a file or remote service.

---

## Missing Features (Planned but Not Implemented)

### FEAT-001: No Subtasks

**Planned:** V1.2  
**Status:** Not implemented

---

### FEAT-002: No Tags

**Planned:** V1.2  
**Status:** Not implemented

---

### FEAT-003: No Task Notes

**Planned:** V1.2  
**Status:** Not implemented

---

### FEAT-004: No Statistics/Streaks

**Planned:** V1.2  
**Status:** Not implemented

---

### FEAT-005: No Carry-Forward Feature

**Planned:** V1.2  
**Status:** Not implemented

---

### FEAT-006: No Bulk Actions

**Planned:** V1.2  
**Status:** Not implemented

---

### FEAT-007: No Archive Feature

**Planned:** V1.2  
**Status:** Not implemented

---

### FEAT-008: No Quick Add

**Planned:** V1.2  
**Status:** Not implemented

---

### FEAT-009: No Task History

**Planned:** V1.2  
**Status:** Not implemented

---

### FEAT-010: No Recurrence Exceptions

**Planned:** V1.2  
**Status:** Not implemented

---

### FEAT-011: No Advanced Recurrence (Every X days/weeks/months)

**Planned:** V1.2  
**Status:** Not implemented

---

### FEAT-012: No Custom Snooze Durations

**Planned:** V1.2  
**Status:** Not implemented

---

### FEAT-013: No Language Localization (Nepali UI)

**Planned:** V1.2  
**Status:** Not implemented

---

### FEAT-014: No Accent Color Customization

**Planned:** V1.2  
**Status:** Not implemented

---

### FEAT-015: No Font Size Customization

**Planned:** V1.2  
**Status:** Not implemented

---

## Security Concerns

### SEC-001: No Input Validation on Backup Import

**File:** `lib/data/backup_service.dart`  
**Description:**  
The backup import doesn't validate the structure of the imported data beyond checking the `app` field. Malformed data could cause crashes or unexpected behavior.

**Recommendation:**  
Add comprehensive validation of the backup data structure.

---

### SEC-002: No SQL Injection Protection

**File:** `lib/data/task_repository.dart`  
**Description:**  
The app uses parameterized queries (good!), but the `search()` method uses `LIKE` with user input. While parameterized, the `%` and `_` characters in the search query could be interpreted as wildcards.

**Recommendation:**  
Escape special characters in the search query:
```dart
final q = '%${query.trim().replaceAll('%', r'\%').replaceAll('_', r'\_')}%';
```

---

### SEC-003: No Data Encryption

**Description:**  
The SQLite database is stored in plain text. If the device is compromised, all task data is accessible.

**Recommendation:**  
Consider using `sqlcipher` for database encryption.

---

### SEC-004: No Certificate Pinning (If Backend Added)

**Description:**  
Currently, the app has no backend, so this is not an issue. If a backend is added in the future, certificate pinning should be implemented.

---

## Performance Issues

### PERF-001: Calendar Rendering is O(n*m)

**File:** `lib/features/calendar/calendar_page.dart`  
**Description:**  
As mentioned in BUG-015, the calendar rendering has O(n*m) complexity.

---

### PERF-002: No Pagination for Large Task Lists

**File:** `lib/data/task_repository.dart`  
**Description:**  
The `getAll()` method loads all tasks into memory. For large task lists, this could cause memory issues.

**Recommendation:**  
Implement pagination or lazy loading.

---

### PERF-003: No Image Caching

**Description:**  
If attachments are added in the future, image caching should be implemented.

---

### PERF-004: No Database Index on `status`

**File:** `lib/data/app_database.dart`  
**Description:**  
The `status` column is not indexed, but it's used in several queries (e.g., `getPendingReminders`, `getUpcoming`, `applyMissedPolicy`).

**Recommendation:**  
Add an index on the `status` column:
```sql
CREATE INDEX idx_tasks_status ON tasks(status);
```

---

## Testing Gaps

### TEST-001: Only 2 Unit Tests

**File:** `test/widget_test.dart`  
**Description:**  
Only 2 unit tests exist, both for `RecurrenceEngine`. There are no tests for:
- BS/AD date conversion
- Task repository
- Notification service
- Backup service
- Widget tests
- Integration tests

---

### TEST-002: No BS Date Conversion Tests

**Description:**  
The BS/AD date conversion is critical and should be thoroughly tested, especially for:
- Month boundaries
- Year boundaries
- Leap years
- Historical dates
- Future dates

---

### TEST-003: No Recurrence Edge Case Tests

**Description:**  
Only 2 recurrence tests exist. Missing tests for:
- Weekly recurrence
- Monthly recurrence
- Yearly recurrence
- Selected weekdays
- Interval > 1
- Month-end clamping (e.g., Jan 31 + 1 month)

---

### TEST-004: No Widget Tests

**Description:**  
No widget tests exist for any of the UI components.

---

### TEST-005: No Integration Tests

**Description:**  
No integration tests exist for the full task lifecycle (create → notify → complete → next occurrence).

---

## Summary & Recommendations

### Bug Count by Severity

| Severity | Count |
|----------|-------|
| Critical | 6 |
| High | 6 |
| Medium | 8 |
| Low | 8 |
| **Total** | **28** |

### Top 5 Priority Fixes

1. **BUG-001:** Fix `seriesId` propagation in `complete()` and `skip()` — This breaks the core recurring task functionality
2. **BUG-002:** Wrap `replaceAll()` in a transaction — This prevents data corruption
3. **BUG-003:** Fix `moveTomorrow` month boundary bug — This causes crashes at month end
4. **BUG-004:** Add exception handling to notification action handler — This prevents app crashes
5. **BUG-005:** Fix quiet hours infinite loop — This prevents notifications from firing

### Recommended Actions

1. **Immediate:** Fix all Critical and High severity bugs
2. **Short-term:** Add comprehensive unit tests for date conversion and recurrence
3. **Medium-term:** Add a state management library (Riverpod) and routing (GoRouter)
4. **Long-term:** Implement missing V1.2 features (subtasks, tags, statistics, etc.)

### Code Quality Score

| Category | Score | Notes |
|----------|-------|-------|
| Architecture | 6/10 | Clean separation but no state management |
| Error Handling | 3/10 | Minimal error handling, no centralized strategy |
| Testing | 2/10 | Only 2 unit tests, no widget/integration tests |
| Documentation | 7/10 | Good Plan.md and Process.md |
| Security | 5/10 | Parameterized queries but no encryption |
| Performance | 6/10 | Some O(n*m) issues, no pagination |
| **Overall** | **5/10** | Functional but needs hardening |

---

*Report generated by comprehensive code analysis. All bugs identified through manual code review without running the application.*
