# Flutter Process Guide — Personal Todo Mobile App

This document explains **how the Flutter app is built, how every system works, and what requirements must be met** at each stage.

Companion document: `Plan.md` (product scope and feature list).  
This document: **implementation process, architecture, and working behavior**.

---

# 1. Product Process Summary

## What the app does

```text
User creates a task
        ↓
Task is stored locally (SQLite)
        ↓
Reminder is scheduled with the OS
        ↓
Notification fires at the right time
        ↓
User Completes / Snoozes / Skips / Reschedules
        ↓
If recurring → next occurrence is generated
        ↓
UI updates from local database
```

## Hard requirements that drive process decisions

1. Must work **fully offline**
2. Must store data **only on device** in V1/V2
3. Must show dates in **BS**, store dates in **AD**
4. Must deliver **reliable notifications** when app is closed
5. Must survive **force-stop + device reboot**
6. Must allow **export/import** of user data
7. Must be **Flutter mobile only** (Android first)

If a feature conflicts with these, the feature is deferred or redesigned.

---

# 2. Confirmed Flutter Stack

| Concern | Choice | Why |
| --- | --- | --- |
| Framework | Flutter | Native mobile UI + one codebase |
| Language | Dart | Flutter standard |
| Database | Drift (SQLite) | Typed queries, migrations, reliable persistence |
| State | Riverpod | Clear dependency injection + testable providers |
| Routing | GoRouter | Declarative navigation for Today / Calendar / Settings |
| Notifications | `flutter_local_notifications` + `timezone` | Native scheduled reminders |
| Timezone | `timezone` / `flutter_timezone` | Correct local scheduling for Nepal (+05:45) |
| Paths / files | `path_provider` + `file_picker` / share APIs | Backup export/import |
| Icons / splash | `flutter_launcher_icons` + `flutter_native_splash` | Native packaging |
| Serialization | `freezed` + `json_serializable` (optional but recommended) | Safe models + backup JSON |

No backend. No auth. No cloud sync in V1/V2.

---

# 3. Recommended Project Structure

```text
lib/
  main.dart
  app.dart

  core/
    theme/
    constants/
    errors/
    utils/
      bs_date_converter.dart
      datetime_utils.dart
      id_generator.dart

  data/
    db/
      app_database.dart
      tables/
      daos/
    repositories/
      task_repository.dart
      category_repository.dart
      settings_repository.dart
      backup_repository.dart
    mappers/

  domain/
    models/
      task.dart
      occurrence.dart
      category.dart
      tag.dart
      settings.dart
    enums/
      task_status.dart
      priority.dart
      recurrence_type.dart
    services/
      recurrence_engine.dart
      reminder_scheduler.dart
      missed_task_policy.dart
      carry_forward_policy.dart

  features/
    today/
    upcoming/
    calendar/
    task_editor/
    task_detail/
    completed/
    search/
    settings/
    statistics/
    onboarding_permissions/

  services/
    notifications/
      notification_service.dart
      notification_actions.dart
      reboot_rescheduler.dart
    backup/
      export_service.dart
      import_service.dart

  routing/
    app_router.dart
```

### Layer rules

* **UI (features)** never talks to SQLite directly
* **Repositories** own read/write of persistent data
* **Domain services** own business rules (recurrence, missed policy, snooze)
* **Notification service** owns OS scheduling only
* **BS converter** is the only place that converts calendars

---

# 4. How Core Systems Work

## 4.1 Date System (AD internal / BS display)

### Rule

```text
Storage + calculations = AD / Gregorian Instant
UI date pickers + labels = BS
```

### Flow

```text
User picks:
  2083 असोज 9, 7:00 PM
        ↓
BS → AD converter
        ↓
Stored as ISO/local DateTime:
  2026-09-25T19:00:00+05:45
        ↓
UI reads DateTime
        ↓
AD → BS converter
        ↓
User sees:
  2083 असोज 9 · Friday · 7:00 PM
```

### Requirements

* One dedicated converter utility
* No scattered conversion logic in widgets
* Leap years / month lengths must be tested
* Settings may show BS only, AD only, or BS + AD
* Recurrence arithmetic uses AD timestamps, then converts for display

---

## 4.2 Task Model and Lifecycle

### Minimal task fields

```text
id
title
description
scheduledAt          // AD DateTime
durationMinutes
priority
categoryId
status
recurrenceRule       // nullable JSON/object
reminderOffset       // e.g. 10 minutes before
notificationId       // OS notification id mapping
createdAt
updatedAt
```

### Status meanings

| Status | Meaning |
| --- | --- |
| upcoming | Scheduled in the future |
| due | At/near scheduled time |
| in_progress | User started / actively working (optional V1) |
| completed | Done |
| snoozed | Temporarily moved |
| skipped | This occurrence ignored |
| missed | Passed without action |
| cancelled | Explicitly cancelled |

### Task action flows

#### Complete

```text
Tap Complete
  → mark occurrence completed
  → cancel pending notification for this occurrence
  → if recurring: generate next occurrence
  → schedule next reminder if needed
  → update Today / Calendar / Stats
```

#### Snooze

```text
Tap Snooze (5m / 10m / custom / tomorrow)
  → compute new DateTime
  → update occurrence scheduledAt
  → set status = snoozed (or upcoming after move)
  → cancel old notification
  → schedule new notification
```

#### Skip

```text
Tap Skip
  → mark this occurrence skipped
  → cancel this reminder
  → if recurring: create next occurrence
  → do not delete the series
```

#### Reschedule

```text
Pick new BS date/time
  → convert to AD
  → update scheduledAt
  → recalculate reminder time
  → reschedule notification
```

---

## 4.3 Local Database Process (Drift / SQLite)

### Why SQLite

* Survives app kill and reboot
* Supports queries for Today / Upcoming / Calendar / Search
* Can store recurrence history and settings
* Easy to export as structured backup

### Suggested tables

* `tasks` — series or single tasks
* `occurrences` — concrete dated instances (especially for recurrence)
* `categories`
* `tags`
* `task_tags`
* `subtasks`
* `settings`
* `notification_map` — task/occurrence → notification ids
* `stats_events` or derive stats from occurrence history

### Persistence rules

1. Every create/edit/complete/snooze/skip writes to DB first
2. UI listens to DB/stream/providers and rebuilds
3. Notifications are scheduled from DB truth, not from temporary UI state
4. After reboot, reminder scheduler rebuilds from DB

### Data survival must-pass cases

* App refresh / hot restart
* Force stop
* Device reboot
* Airplane mode / offline
* Large task history

---

## 4.4 Recurrence Engine

### Responsibility

Given a recurrence rule + base task, generate the next valid occurrence(s).

### V1.1 supported rules

* Daily
* Weekdays
* Weekly
* Selected weekdays (e.g. Mon/Wed/Fri)
* Monthly
* Yearly

### How it works

```text
Series definition stored once
        ↓
Current/next occurrence stored as concrete row
        ↓
On Complete / Skip
        ↓
Engine computes next AD DateTime from rule
        ↓
New occurrence row created
        ↓
Reminder scheduled for new occurrence
```

### Exception model (V1.2)

When editing a recurring item:

```text
○ This occurrence
○ This and future
○ Entire series
```

Process:

* **This occurrence** → mutate only one occurrence row
* **This and future** → split series / update forward window
* **Entire series** → update series rule and rebuild future occurrences carefully

Never silently destroy history when editing one day.

---

## 4.5 Notification System (Most Critical Process)

### Goal

> If a reminder is set for tomorrow 7:00 PM, the phone must notify at that time even if the app is closed.

### Components

1. **Permission gate** — request notification permission (Android 13+)
2. **Exact alarm handling** — request/check where Android requires it
3. **Notification channels** — e.g. `task_reminders`, `missed_tasks`
4. **Scheduler** — converts task reminder time → OS scheduled notification
5. **Action handler** — Complete / Snooze / Skip from notification
6. **Reboot rescheduler** — restore schedules after boot

### Schedule flow

```text
Task saved with reminder
        ↓
Compute trigger time = scheduledAt - reminderOffset
        ↓
Respect Quiet Hours (delay or suppress per settings)
        ↓
Register local notification with unique id
        ↓
Store notification id in DB
```

### Action flow

```text
Notification action tapped
        ↓
App receives action payload (occurrence id + action)
        ↓
Domain service updates DB
        ↓
Scheduler cancels/reschedules as needed
        ↓
UI reflects new state when opened
```

### Reboot flow

```text
Device boots
        ↓
Boot receiver / app init path runs
        ↓
Load all future pending occurrences from DB
        ↓
Reschedule notifications
```

### Notification testing process (mandatory)

Test each case on a real Android phone:

* App open
* App in background
* App force-stopped (document OS limits)
* Screen locked
* Airplane mode
* After reboot
* Permission denied
* Exact alarm denied
* Battery optimization aggressive OEMs (Xiaomi/Oppo/Vivo etc.)

Document any OEM-specific limitations instead of pretending they do not exist.

---

## 4.6 Today / Upcoming / Calendar Views

### Today process

```text
Query occurrences where date == today (device local)
  → split overdue / today remaining / completed
  → sort by time
  → render list
```

### Upcoming process

```text
Query occurrences in selected window
  (tomorrow / 7 days / 30 days / custom)
  → group by date
  → show BS labels
```

### Calendar process

```text
Build BS month grid
  → convert each BS day to AD range
  → query task counts/indicators for that range
  → tap day → day detail list
```

UI must remain phone-first: bottom navigation or simple primary tabs.

Suggested primary destinations:

* Today
* Upcoming
* Calendar
* Settings

Search can be an icon action, not a main tab in V1.1.

---

## 4.7 Settings Process

Settings are stored locally and read by domain services at runtime.

### Setting consumers

| Setting | Consumed by |
| --- | --- |
| Date display BS/AD | Calendar + task tiles |
| Default reminder | Task editor |
| Snooze presets | Snooze action sheet + notifications |
| Quiet hours | Reminder scheduler |
| Missed-task policy | Missed task evaluator |
| Carry-forward policy | Midnight / day-change job |
| Theme / accent | App theme |
| Language | UI strings / weekday labels |

### Process rule

Hard-coded behavior becomes a setting only when it gives meaningful user control.

---

## 4.8 Missed Tasks and Carry Forward

### Missed evaluator process

Runs when:

* App opens
* Day changes
* Periodic check while app is active

```text
Find occurrences where now > scheduledAt
AND status not completed/skipped/cancelled
        ↓
Apply user policy:
  - mark missed
  - keep overdue
  - move to next day
  - ask user
  - auto reschedule
```

### Carry forward process

At local midnight transition (or first open after midnight):

```text
Incomplete yesterday tasks
        ↓
Apply carry-forward setting
        ↓
Update DB + reschedule reminders if moved
```

---

## 4.9 Backup / Export / Import

### Export process

```text
Read DB entities
  → serialize to versioned JSON
  → write/share file
```

Suggested JSON envelope:

```text
{
  "app": "personal_todo",
  "version": 1,
  "exportedAt": "...",
  "tasks": [...],
  "occurrences": [...],
  "categories": [...],
  "tags": [...],
  "settings": {...}
}
```

### Import process

```text
Pick file
  → validate schema/version
  → preview summary
  → confirm replace or merge strategy
  → write DB transactionally
  → rebuild notification schedules
```

### Safety rules

* Never partially import into a corrupt state
* Invalid backup must fail with a clear message
* Warn before delete-all
* Optional reminder if no backup for N days

---

# 5. Version Process Roadmap

## V1.1 — Basics (build a usable core)

Goal: reliable local task system + native reminder foundation.

Must include:

1. Flutter project foundation
2. Task model + SQLite
3. Create / Edit / Delete
4. Complete / Skip / Snooze / Reschedule
5. Basic recurrence
6. Today / Upcoming / Calendar (BS)
7. Local notifications (schedule + basic actions)
8. Settings skeleton
9. Export/import minimal JSON

Exit criteria:

* Create a BS-dated task
* Receive reminder with app closed
* Complete/snooze/skip works
* Data survives reboot

---

## V1.2 — Complete feature integration

Add depth only after V1.1 is solid:

* Advanced recurrence + exceptions
* Categories / tags / subtasks
* Search / filters / sorting
* Notes / attachments (if practical)
* Statistics / streaks
* Quiet hours / missed / carry-forward policies
* Themes and appearance customization
* Bulk actions / archive / quick add polish

Exit criteria:

* Feature set from Plan V1.2 works offline
* Recurrence exceptions do not corrupt history
* Notification actions remain reliable

---

## V1.3 — Testing and hardening

Stop feature growth.

Process:

1. Functional test checklist
2. Recurrence edge-case battery
3. BS conversion battery
4. Timezone / midnight tests
5. Notification real-device matrix
6. Offline tests
7. Data integrity / corrupt backup tests
8. Performance pass
9. Accessibility pass
10. Privacy review
11. Classify and fix Critical/High bugs

Exit criteria:

* Zero Critical bugs
* Zero High bugs
* Known OS limits documented

---

## V2 — Stable release

Process:

1. Feature freeze
2. Final regression
3. Signed Android release build
4. Real-device reminder validation
5. Backup/restore validation
6. Stable tag/release

---

# 6. Development Order (Execution Process)

Follow this order. Do not jump to cosmetics before reminders/data are trustworthy.

## Phase 1 — Foundation

```text
Create Flutter app
→ Add Drift + Riverpod + GoRouter
→ Define models/tables
→ Implement BS/AD utility with unit tests
→ App shell navigation
```

Deliverable: empty screens + DB open + date converter tests green.

## Phase 2 — Core tasks

```text
Create task form
→ Persist task
→ Edit/delete
→ Today list from DB
→ Complete / Skip / Snooze / Reschedule actions
```

Deliverable: full offline CRUD + basic actions.

## Phase 3 — Calendar + recurrence

```text
BS month calendar
→ Day task list
→ Upcoming view
→ Recurrence rules
→ Next-occurrence generation
```

Deliverable: recurring tasks appear correctly on BS dates.

## Phase 4 — Native packaging

```text
App name/icon/splash
→ Android permissions in manifest
→ Notification channels
→ Debug/release build config
```

Deliverable: installable Android app that looks like a real product.

## Phase 5 — Notifications

```text
Permission UX
→ Schedule on save
→ Cancel/update on edit/delete
→ Notification actions
→ Reboot reschedule
→ Quiet hours hook
```

Deliverable: reminder works with app closed and after reboot.

## Phase 6 — Advanced product features

```text
Categories/tags/subtasks
→ Search/filter/sort
→ Stats/history/archive
→ Bulk actions
```

## Phase 7 — Customization

```text
Settings sections
→ Theme/accent
→ Date/language prefs
→ Notification and task defaults
```

## Phase 8 — Data management

```text
Export JSON
→ Import/validate
→ Backup reminder
→ Delete-all safety
```

## Phase 9 — Hardening

```text
Test matrix execution
→ Bug triage
→ Performance fixes
→ UX polish only where needed
```

## Phase 10 — Stable release

```text
Freeze
→ Regression
→ Release build
→ Device verification
```

---

# 7. Requirements by System

## Functional requirements

* Create task with title, BS date, time
* Optional description, priority, category, reminder, recurrence
* Edit all mutable fields
* Delete task
* Complete / Skip / Snooze / Reschedule
* Today, Upcoming, Calendar views
* Offline use of all core actions
* Local DB persistence
* Export and import backup
* Configurable settings for reminders and task behavior

## Non-functional requirements

* Cold start should feel responsive on mid-range Android
* Calendar month render should remain smooth with normal personal task volume
* No account/network required for core use
* No analytics/tracking by default
* Clear human error messages
* Touch targets suitable for phone use

## Platform requirements (Android first)

* Target modern Android SDK with backward support decided at project init
* `POST_NOTIFICATIONS` runtime permission where required
* Notification channels configured
* Exact alarm permission handled if used
* Boot reschedule path implemented
* App works in portrait primarily

## Explicit non-requirements (V1/V2)

* No website
* No PWA
* No backend
* No login
* No AI features
* No multi-device sync
* No iOS release requirement for first Android stable (iOS can come later from same Flutter code)

---

# 8. State Management Process (Riverpod)

### Pattern

```text
UI watches providers
  → providers call repositories/services
  → repositories talk to Drift
  → services enforce domain rules
```

### Provider examples

* `todayTasksProvider`
* `upcomingTasksProvider`
* `calendarMonthProvider(bsYear, bsMonth)`
* `taskDetailProvider(id)`
* `settingsProvider`
* `notificationPermissionProvider`

### Update rule

Any write action (create/complete/snooze/etc.):

1. Validate input
2. Persist via repository
3. Update notifications via scheduler
4. Invalidate/refresh affected providers

Do not keep a second “source of truth” in memory that can diverge from SQLite.

---

# 9. Error Handling Process

Every failure should map to a user-facing explanation and a safe fallback.

| Failure | User message direction | App behavior |
| --- | --- | --- |
| Notification permission denied | Explain how to enable | Save task, mark reminder inactive |
| Exact alarm denied | Explain impact on precise reminders | Fallback or warn |
| Storage/DB unavailable | Cannot save right now | Block destructive writes |
| Invalid backup | Backup file is invalid | Abort import |
| Date conversion failure | Selected date cannot be converted | Block save |
| Corrupt recurrence data | Recurrence needs repair | Fail safe, preserve history |

Never show only “Something went wrong.”

---

# 10. Testing Process

## Unit tests

* BS ↔ AD conversion
* Recurrence next-date calculation
* Snooze time computation
* Quiet hours adjustment
* Missed/carry-forward policy decisions
* Backup JSON validation

## Widget/UI tests

* Today list rendering
* Task create form validation
* Settings toggles
* Calendar day selection

## Integration / device tests

* Create task → schedule notification → receive notification
* Complete from notification action
* Reboot → reminders restored
* Export → clear → import → data matches
* Airplane mode full flow

## Release testing gate

Before calling a build stable:

* [ ] Critical bugs = 0
* [ ] High bugs = 0
* [ ] Reminder works app-closed
* [ ] Reminder works after reboot
* [ ] BS calendar date correctness checked across month boundaries
* [ ] Import/export verified
* [ ] Offline verified

---

# 11. Day-to-Day Build Process

When implementing any feature, use this checklist:

1. **Read related Plan section** — confirm scope
2. **Define model/DB impact** — migrations if needed
3. **Implement domain rule** — pure Dart where possible
4. **Wire repository** — persistence
5. **Wire notification side effects** — only if time/reminder changes
6. **Build UI** — phone-first, minimal friction
7. **Add/adjust settings** — only if behavior should be configurable
8. **Write tests** — at least for date/recurrence/reminder math
9. **Real device check** — especially for notifications
10. **Update Process notes if architecture decisions change**

---

# 12. Definition of Done (Flutter Process)

A feature is done only when all are true:

1. Works offline
2. Persists in SQLite correctly
3. Updates UI from DB/providers
4. Does not break recurrence history
5. Schedules/cancels notifications correctly when relevant
6. Uses BS for display and AD for storage/calculation
7. Has clear failure behavior
8. Covered by tests appropriate to risk
9. Verified on a real Android device when notification-related

A release is done only when a user can:

1. Install the Android app
2. Create a BS-dated reminder
3. Receive it with the app closed
4. Complete / Snooze / Skip it
5. Keep using the app offline
6. Export and re-import data safely
7. Reboot and still get future reminders

---

# 13. Risk Register and Process Mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| OEM kills background alarms | Missed reminders | Exact alarms + boot reschedule + user guidance for battery exceptions |
| BS conversion bugs | Wrong task dates | Isolated converter + extensive unit tests |
| Recurrence exceptions corrupt series | Data loss/confusion | Occurrence rows + explicit edit scope |
| Backup import partial writes | Corrupt DB | Transactional import + schema validation |
| Overbuilding UI early | Delayed reliable reminders | Enforce phase order: data → actions → notifications before polish |
| Treating Flutter like a website | Weak mobile UX | Phone-first navigation, native permissions, no web assumptions |

---

# 14. Final Working Philosophy

Build in this priority order:

```text
Correct local data
  → Correct BS/AD behavior
  → Correct task actions
  → Correct recurrence
  → Correct native reminders
  → Then customization and extra features
```

The process succeeds when this sentence is true on a real phone:

> **I set a reminder for tomorrow, closed the app, and it actually notified me tomorrow.**

Everything in this Flutter process exists to make that reliable.
