# Personal Todo Mobile App

## Project Overview

A personal, offline-first Todo and Reminder **mobile application** (Android first; iOS optional later).

The application is designed **only for mobile devices**. Website, desktop browser, and PWA targets are out of scope.

The core purpose is:

> Create a task → Schedule it → Receive a notification → Complete, Snooze, Skip, or Reschedule it → Repeat when required.

The application should feel like a lightweight personal task manager rather than a complicated enterprise productivity platform.

---

# Why Not PWA

PWA was attempted and failed for this product.

Primary failure reason:

> Reliable scheduled reminders when the app is closed are a hard requirement. Browser/PWA notification APIs are too limited and unreliable for this.

Known PWA limitations that break this product:

* Background notification scheduling is unreliable on Android Chrome and especially on iOS Safari
* Service Workers cannot guarantee precise local reminders after the app is killed
* Notification actions (Complete / Snooze / Skip) are limited or inconsistent across browsers
* Installability, offline caching, and permission flows vary by browser/OS
* Quiet hours, missed-task handling, and recurring reminders need native OS notification APIs

**Decision: abandon PWA. Build a native-capable mobile app only.**

---

# Recommended Technology

## Primary Recommendation: Flutter

**Use Flutter + Dart.**

Why Flutter fits this project best:

* True mobile app (not a browser shell)
* Reliable **local scheduled notifications** via native Android/iOS APIs
* Excellent offline-first architecture
* Single codebase for Android + iOS
* Strong local databases (SQLite / Drift / Isar / Hive)
* Good calendar and custom UI support for BS date pickers
* No dependency on Service Workers or browser install prompts

### Recommended Flutter Stack

| Layer | Choice |
| --- | --- |
| UI framework | Flutter |
| Language | Dart |
| Local database | Drift (SQLite) or Isar |
| State management | Riverpod (or Bloc if preferred) |
| Local notifications | `flutter_local_notifications` + timezone package |
| Navigation | GoRouter |
| Date conversion | Custom BS/AD utility (keep AD internal) |
| Backup | JSON export/import to device storage |
| Icons / splash | Flutter native splash + adaptive icons |

### Why not stay on React/Vite for mobile?

The original PWA plan used Vite + React + TypeScript. That stack can move to React Native/Expo, but for **reminder reliability**, Flutter’s native local-notification path is usually more predictable and simpler to own long-term.

---

## Alternative Options (If Flutter Is Not Chosen)

### Option A — Expo (React Native) — Best if you want to keep React skills

Stack:

* Expo + React Native + TypeScript
* SQLite (`expo-sqlite`) or WatermelonDB
* Zustand or Redux Toolkit
* `expo-notifications` for local scheduled reminders
* Expo Router

Pros:

* Familiar if you already know React/TypeScript
* Fast UI iteration
* Good enough local notifications on Android; iOS needs careful setup

Cons:

* Notification reliability still needs careful native permission/channel setup
* Some advanced background behaviors are harder than Flutter
* More dependency on Expo tooling and native modules

**Choose Expo if React familiarity matters more than maximum notification control.**

### Option B — Kotlin + Jetpack Compose — Best if Android-only

Stack:

* Kotlin
* Jetpack Compose
* Room (SQLite)
* WorkManager / AlarmManager for exact reminders
* Navigation Compose

Pros:

* Best possible Android notification control
* Smallest runtime overhead
* Full access to AlarmManager / exact alarms / notification channels

Cons:

* Android only unless rewritten later for iOS
* No shared codebase for iPhone

**Choose Kotlin if you only care about Android phones and want maximum reminder reliability.**

### Option C — Capacitor / Ionic — Not recommended

Wrapping the old web app in Capacitor improves installability slightly, but notification reliability still depends on web/hybrid bridges and can recreate PWA-like failure modes.

**Do not choose Capacitor as the recovery path from a failed PWA for this reminder-heavy app.**

---

## Final Tech Decision for This Plan

```text
Platform: Mobile app only (Android first)
Framework: Flutter
Language: Dart
Storage: Local SQLite via Drift (or Isar)
Notifications: Native local notifications
Sync/Backend: None in V1/V2
Auth: None in V1/V2
```

Desktop website and PWA are explicitly removed from scope.

---

# Core Principles

1. **Offline First**

   * Core functionality must work without an internet connection.
   * Tasks must remain available offline.
   * Creating, editing, completing, skipping, and snoozing tasks must work offline.

2. **Local First**

   * V1 stores user data locally on the device.
   * No account should be required.
   * No backend is required for the core application.

3. **AD for Internal Date Logic**

   * Store and calculate dates internally using Gregorian/AD dates.
   * AD is the canonical internal representation because native date APIs and timezone libraries use Gregorian dates naturally.

4. **BS for User Display**

   * Display dates to the user using the Nepali Bikram Sambat (BS) calendar.
   * Date pickers and calendar interfaces should use BS where practical.
   * Users should not need to understand or manually convert AD dates.

5. **Everything Customizable**

   * Settings should expose user-configurable behavior wherever reasonable.
   * Avoid hard-coded behavior when it can reasonably become a setting.

6. **No AI in V1/V2**

   * No AI task generation.
   * No AI scheduling.
   * No AI assistant.
   * No AI dependency.

7. **Mobile Only**

   * Design and ship only for phones.
   * No website target.
   * No desktop-browser target.
   * No PWA install target.
   * Tablet support is optional and not a V1 priority.

8. **Data Ownership**

   * Users should be able to export and restore their data.
   * Never rely on an opaque database that the user cannot back up.

---

# Date and Calendar Architecture

## Internal Date System

All task dates and times should ultimately be represented internally using AD/Gregorian-compatible timestamps.

Example:

```text
User sees:
2083-06-09 BS
7:00 PM

Internal representation:
2026-09-25T19:00:00+05:45
```

The exact BS conversion should be handled by a dedicated date-conversion utility rather than scattered throughout the application.

---

## User Display

The application should primarily display:

* BS year
* BS month
* BS day
* BS weekday
* BS calendar

Example:

```text
2083 असोज 9
Friday
7:00 PM
```

English/AD display may optionally be enabled from Settings.

---

## Calendar Requirements

The calendar must support:

* BS month navigation
* Previous month
* Next month
* Today
* Task indicators
* Task selection
* Task creation from a date
* Daily task view
* Upcoming tasks
* Completed task visibility
* Recurring task indicators
* Overdue task indicators

Optional display:

```text
2083 असोज 9
25 Sep 2026
```

The AD equivalent can be shown when the user enables secondary-date display.

---

# V1.1 - Basics

Goal:

> Build a complete basic task system with reliable local storage and a working native mobile foundation.

Do not add every advanced feature immediately.

---

## 1. Project Foundation

### Technology

Required:

* Flutter
* Dart
* Local SQLite (Drift recommended)
* Riverpod (or Bloc)
* `flutter_local_notifications`
* Timezone-aware scheduling
* Native Android notification channels
* Adaptive app icon + splash screen

State management should remain modular enough to replace individual packages later.

Target platform for V1.1:

```text
Android phone (primary)
iOS (optional later, same Flutter codebase)
```

---

# 2. Task Model

Each task should support at minimum:

```text
id
title
description
date
time
duration
priority
category
status
recurrence
reminder
createdAt
updatedAt
```

Additional metadata may be added later.

---

# 3. Task Creation

Users must be able to create:

### Basic task

* Title
* Description
* Date
* Time

### Optional

* Duration
* Priority
* Category
* Reminder
* Recurrence

Task creation should be quick.

The user should not be forced to configure every optional field.

---

# 4. Task Editing

Users must be able to:

* Edit title
* Edit description
* Change date
* Change time
* Change priority
* Change category
* Change recurrence
* Change reminder
* Change duration
* Delete task

---

# 5. Task States

The application should distinguish between:

* Upcoming
* Due
* In Progress
* Completed
* Snoozed
* Skipped
* Missed
* Cancelled

The system should not treat every non-completed task as the same state.

---

# 6. Task Actions

Every scheduled task should support:

### Complete

Marks the occurrence as completed.

For recurring tasks, the next occurrence is generated according to the recurrence rule.

### Snooze

Temporarily moves the reminder/task.

Default options:

* 5 minutes
* 10 minutes
* 15 minutes
* 30 minutes
* 1 hour
* Tomorrow
* Custom

These values must be configurable from Settings.

### Skip

Skips the current occurrence.

For recurring tasks:

> Skip this occurrence only.

The recurrence itself continues.

### Reschedule

Move the task to another date/time.

---

# 7. Recurring Tasks

V1.1 should implement the basic recurrence engine.

Supported:

* Daily
* Weekdays
* Weekly
* Selected weekdays
* Monthly
* Yearly

Example:

```text
Study Math
Every Monday, Wednesday and Friday
7:00 PM
```

The recurrence engine must generate occurrences reliably.

---

# 8. Today View

The default screen should be:

## Today

Display tasks chronologically.

Example:

```text
TODAY

7:00 AM
○ Morning Study

12:30 PM
✓ Lunch

5:00 PM
○ Trading Journal

7:00 PM
○ Engineering Math
```

Tasks should be grouped by:

* Morning
* Afternoon
* Evening

or simply chronological order.

This grouping should eventually be configurable.

---

# 9. Upcoming View

Display future tasks.

Possible filters:

* Tomorrow
* Next 7 days
* Next 30 days
* Custom

---

# 10. Calendar View

Provide a monthly BS calendar.

Selecting a day displays tasks for that day.

---

# 11. Completed Tasks

Provide a history of completed tasks.

Users must be able to:

* View completed tasks
* View completion date/time
* Restore/reschedule if appropriate
* Delete history

---

# 12. Local Storage

Use on-device SQLite (via Drift or Isar) for persistent application data.

Data must survive:

* App restart
* Device reboot
* App process kill
* Offline operation

Do not rely solely on in-memory state.

Schedule notifications from persisted reminder data so reminders can be rebuilt after reboot when needed.

---

# 13. Mobile App Packaging

The application must:

* Install as a normal Android app (APK/AAB)
* Have an app icon
* Have a splash/loading experience
* Work fully offline
* Open independently from any browser
* Request notification permission correctly on modern Android versions
* Use notification channels for reminders
* Support exact/scheduled local notifications where the OS allows

No web installability, no Service Worker, no browser manifest.

---

# 14. Mobile UI

Must support:

* Small Android phones
* Large Android phones

Priority:

```text
Phone portrait > Phone landscape > Tablet (optional)
```

The interface should feel like a native mobile app, not a website squeezed into a phone.

---

# V1.2 - Complete Feature Integration

Goal:

> Integrate the complete planned feature set.

---

# 15. Advanced Recurrence

Add:

* Every X days
* Every X weeks
* Every X months
* First Monday of month
* Last Friday of month
* Custom recurrence
* Recurrence end date
* Maximum occurrence count
* Never-ending recurrence

---

# 16. Recurring Task Exceptions

Users must be able to modify an individual occurrence without destroying the recurrence.

When editing a recurring task:

```text
Apply to:

○ This occurrence
○ This and future occurrences
○ Entire series
```

Example:

```text
Gym
Every Monday

Sep 28
Oct 5
Oct 12
Oct 19
```

If Oct 12 is skipped, only Oct 12 should be affected.

---

# 17. Categories

Default categories may include:

* Personal
* College
* Study
* Coding
* Trading
* Health
* Family
* Other

Users must be able to:

* Create categories
* Rename categories
* Delete categories
* Assign icons
* Assign colors
* Filter by category

Categories should be completely customizable.

---

# 18. Priority

Support:

* Low
* Normal
* High
* Urgent

Users should be able to rename or customize priority labels if practical.

---

# 19. Tags

Users can assign multiple tags.

Example:

```text
Study Math

#college
#exam
#important
```

Support:

* Create tag
* Delete tag
* Rename tag
* Filter by tag

---

# 20. Subtasks

Example:

```text
Prepare FEE presentation

☐ Research topic
☐ Prepare slides
☐ Add diagrams
☐ Practice
☐ Final review
```

Parent task should display progress:

```text
3 / 5 completed
```

---

# 21. Task Dependencies

Optional advanced system:

```text
Research
   ↓
Write report
   ↓
Submit report
```

Tasks can optionally depend on another task.

This feature should not interfere with normal tasks.

---

# 22. Notes

Tasks can contain detailed notes.

Support:

* Plain text
* URLs
* Basic formatting if practical

---

# 23. Attachments

If practical for the mobile app:

* Images
* Documents
* Files

Attachments should be stored locally on device storage.

This feature must not compromise offline reliability.

---

# 24. Search

Global task search.

Search:

* Title
* Description
* Notes
* Category
* Tags

---

# 25. Filtering

Filters:

* Date
* Status
* Priority
* Category
* Tag
* Recurring
* Completed
* Missed
* Skipped

Filters can be combined.

Example:

```text
College
+
High Priority
+
Incomplete
```

---

# 26. Sorting

Users should be able to sort by:

* Time
* Date
* Priority
* Created date
* Updated date
* Completion status

Default sorting should be chronological.

---

# 27. Notifications

Notifications are a core feature, not an optional decoration.

The system should support:

* Reminder at task time
* Reminder before task
* Custom reminder
* Recurring-task reminders
* Missed-task notification if enabled

Implementation requirements (Flutter/Android):

* Use native local notification APIs
* Create dedicated notification channels
* Request POST_NOTIFICATIONS on Android 13+
* Handle exact-alarm permission where required
* Reschedule notifications after device reboot
* Persist pending reminder IDs with tasks

---

# 28. Notification Actions

Where supported by the OS:

```text
Complete
Snooze
Skip
```

The user should be able to act directly from the notification.

---

# 29. Notification Settings

Everything should be configurable.

Examples:

```text
Task notifications: ON/OFF

Default reminder:
10 minutes before

Snooze options:
5m
10m
15m
30m
1h
Tomorrow

Missed-task notifications:
ON/OFF

Recurring-task notifications:
ON/OFF
```

---

# 30. Quiet Hours

Users can configure:

```text
Quiet Hours

10:30 PM → 7:00 AM
```

Notifications should respect this setting where technically possible.

---

# 31. Custom Snooze

Users should be able to enter:

```text
Snooze for:
[ 45 minutes ]
```

or:

```text
Snooze until:
[ BS date ]
[ Time ]
```

---

# 32. Missed Task Handling

When a task passes its scheduled time without completion:

Options:

* Mark as missed
* Keep overdue
* Automatically move to next day
* Ask user
* Automatically reschedule

This behavior must be configurable.

---

# 33. Carry Forward

Optional behavior:

```text
If incomplete at midnight:

○ Keep overdue
○ Move to tomorrow
○ Ask me
○ Mark as missed
```

---

# 34. Daily Planning

Today view should clearly show:

* Overdue tasks
* Today's tasks
* Completed tasks
* Remaining tasks

Example:

```text
OVERDUE
🔴 Study Chapter 2

TODAY
○ Math
○ FEE
✓ Assignment

COMPLETED
✓ Morning revision
```

---

# 35. Statistics

Provide:

### Daily

* Total tasks
* Completed
* Skipped
* Missed

### Weekly

* Completion count
* Completion percentage
* Missed count
* Skipped count

### Monthly

* Total tasks
* Completed
* Missed
* Skipped

Statistics should be descriptive rather than judgmental.

---

# 36. Streaks

Optional:

* Daily completion streak
* Weekly completion streak

Users should be able to disable streaks.

---

# 37. Calendar Task Indicators

Calendar days can display:

* Number of tasks
* Completed indicator
* Overdue indicator
* High-priority indicator

Avoid making the calendar visually overloaded.

---

# 38. Themes

Support:

* Light
* Dark
* System

---

# 39. Appearance Customization

Users should be able to configure:

* Theme
* Accent color
* Compact/comfortable layout
* Font size where practical
* Calendar display
* 12/24-hour clock
* Week starting day
* Date format

---

# 40. Language / Display Preferences

Potential settings:

* English UI
* Nepali UI

Calendar display:

* BS only
* AD only
* BS + AD

Weekday display should follow selected language.

---

# 41. Data Management

Users must be able to:

### Export

* JSON backup
* CSV export where meaningful

### Import

* Restore JSON backup

### Clear data

Provide a clear warning before deleting all local data.

Example:

```text
Delete all application data?

This cannot be undone unless you have a backup.

[Cancel]
[Delete Everything]
```

---

# 42. Automatic Backup Reminder

Because V1 is local-first, optionally remind users:

> You haven't exported a backup recently.

The reminder should be configurable or disabled.

---

# 43. Task Archive

Instead of immediately deleting completed tasks:

* Archive
* Restore
* Permanently delete

Users should control archive behavior.

---

# 44. Bulk Actions

Allow users to select multiple tasks:

* Complete
* Skip
* Delete
* Archive
* Change category
* Change priority
* Reschedule

---

# 45. Quick Add

A very fast task creation interface.

Minimum:

```text
+ Add Task

Task:
[________________]

Date:
[Today]

Time:
[7:00 PM]

[Add]
```

Optional settings remain hidden until needed.

---

# 46. Task Details

Task detail page/modal should contain:

```text
Title
Description
Date
Time
Duration
Priority
Category
Tags
Reminder
Recurrence
Subtasks
Notes
History
```

---

# 47. Task History

For recurring tasks, maintain occurrence history.

Example:

```text
Study Math

Sep 21 ✓ Completed
Sep 23 ✓ Completed
Sep 25 ⏭ Skipped
Sep 28 ○ Upcoming
```

This is important for meaningful statistics.

---

# 48. Settings System

Settings should be centralized.

Suggested sections:

## General

* Language
* Date display
* Time format
* Week start
* Default task duration

## Calendar

* BS/AD display
* First day of week
* Calendar appearance

## Notifications

* Enable notifications
* Default reminder
* Snooze options
* Missed-task notifications
* Recurring-task notifications
* Quiet hours
* Exact-alarm / battery-optimization guidance (Android)

## Tasks

* Default priority
* Default category
* Default duration
* Completion behavior
* Missed-task behavior
* Carry-forward behavior

## Recurrence

* Default recurrence behavior
* End-of-series behavior

## Appearance

* Theme
* Accent
* Layout density
* Font size

## Data

* Export
* Import
* Backup
* Archive
* Delete all data

## App / Device

* Notification permission status
* Exact alarm permission status (Android)
* Storage / database information
* App version
* Rebuild / reschedule reminders

---

# 49. Settings Philosophy

Whenever reasonable:

> Hard-coded behavior should become configurable behavior.

However:

> Do not expose meaningless technical settings to normal users.

Advanced settings should only exist when they provide meaningful control.

---

# V1.3 - Testing, Debugging and Hardening

Goal:

> Stop adding features and make the application reliable.

No major new features should be introduced during this phase.

---

# 50. Functional Testing

Test:

* Create task
* Edit task
* Delete task
* Complete
* Skip
* Snooze
* Reschedule
* Recurrence
* Search
* Filter
* Calendar
* Statistics
* Import
* Export
* Settings

---

# 51. Recurrence Testing

Test difficult cases:

* Daily recurrence
* Weekly recurrence
* Multiple weekdays
* Monthly recurrence
* Yearly recurrence
* End dates
* Recurrence exceptions
* Skipped occurrence
* Edited occurrence
* Deleted occurrence
* Snoozed occurrence
* Rescheduled occurrence

---

# 52. BS Calendar Testing

Test:

* BS → AD conversion
* AD → BS conversion
* Month boundaries
* Year boundaries
* Leap-year behavior
* Date selection
* Task scheduling
* Recurring tasks
* Historical dates
* Future dates

This is a critical area.

Do not assume date conversion works merely because today's date looks correct.

---

# 53. Timezone Testing

Test:

* Nepal timezone
* Device timezone changes
* Daylight-saving regions if users travel
* Midnight transitions
* Date changes
* Recurring tasks across timezone changes

The application's default timezone should follow the device unless explicitly configured otherwise.

---

# 54. Notification Testing

Test:

* App open
* App closed / killed
* Device locked
* Device rebooted
* Offline
* Notification permission denied
* Notification permission restored
* Exact-alarm permission denied/restored (Android)
* Battery optimization restrictions
* Snooze
* Complete from notification
* Skip from notification
* Recurring notification

Also document OS limitations.

Do not promise notification behavior that Android/iOS cannot reliably provide.

---

# 55. Offline Testing

Disable internet and test:

* Open app
* Create task
* Edit task
* Complete task
* Snooze
* Skip
* Calendar
* Search
* Settings
* Export
* Import

Everything classified as offline-capable must actually work offline.

---

# 56. Data Integrity Testing

Test:

* Force-stop app
* Reopen app
* Device reboot
* Large task count
* Repeated editing
* Import/export
* Corrupted backup
* Duplicate task IDs
* Invalid task data

The app should fail safely rather than silently destroying data.

---

# 57. Device Testing

Test at:

* Small Android phone
* Large Android phone
* Optional tablet

Test portrait and landscape.

---

# 58. Performance Testing

Check:

* Cold start
* Calendar rendering
* Large task history
* Search performance
* Recurrence calculation
* Database operations
* Notification scheduling / rescheduling

Avoid unnecessary packages and excessive rebuilds.

---

# 59. Accessibility Testing

Minimum:

* Screen-reader labels
* Adequate contrast
* Focus / semantics
* Touch-friendly controls
* Accessible notification/task actions
* Reduced-motion support where practical

---

# 60. Error Handling

The app should handle:

* Notification permission denied
* Exact-alarm permission denied
* Storage unavailable
* Invalid imported data
* Corrupted backup
* Date conversion failure
* Unexpected recurrence data
* OS battery/notification restrictions

Errors should explain what happened instead of showing:

```text
Something went wrong.
```

Humanity deserves at least one useful error message.

---

# 61. Security / Privacy Review

Verify:

* No unnecessary external data transmission
* No hidden analytics
* No unnecessary tracking
* No sensitive task data sent to external services
* Safe import handling
* Safe URL handling
* No unsafe HTML rendering

---

# 62. Mobile Release Audit

Verify:

* App name
* Icons
* Splash screen
* Offline operation
* Notification channels
* Permission declarations
* Android 13+ notification permission flow
* Exact alarm handling where needed
* Boot-complete reminder reschedule
* Correct orientation handling
* Release signing / AAB readiness

---

# 63. Final Bug Classification

Every discovered issue should be classified:

### Critical

App/data loss or core functionality broken.

### High

Major feature unusable.

### Medium

Feature works incorrectly in specific situations.

### Low

Minor UI or cosmetic issue.

V2 cannot be called stable while Critical or High bugs remain.

---

# V2 - Stable Release

Goal:

> Release a reliable, polished, maintainable version rather than continuously adding features.

---

## V2 Requirements

### Core

* Task management stable
* Recurrence stable
* BS calendar stable
* Notifications stable within OS limitations
* Offline operation stable
* Android install/release stable
* Local database stable

### UX

* Fast task creation
* Clear Today view
* Reliable calendar
* Simple task actions
* Customizable settings
* Good phone experience

### Data

* Reliable export/import
* No silent data loss
* Archive/history functioning
* Recovery from invalid data

### Quality

* Critical bugs: 0
* High-priority bugs: 0
* No known data-loss issues
* No known recurrence corruption issues

---

# Features Explicitly NOT Included

## AI

No:

* AI assistant
* AI scheduling
* AI task generation
* AI task decomposition
* AI natural-language parser

These can be reconsidered in a future version, but are outside the current project scope.

## Web / PWA

No:

* Website version
* Progressive Web App
* Service Worker offline layer
* Browser install prompts
* Desktop-browser primary target

---

# Must-Have Features Checklist

The following features are mandatory for the project to satisfy its original purpose:

* [ ] Create task
* [ ] Edit task
* [ ] Delete task
* [ ] Date
* [ ] Time
* [ ] BS calendar display
* [ ] AD internal date representation
* [ ] Today view
* [ ] Upcoming view
* [ ] Calendar view
* [ ] Recurring tasks
* [ ] Daily recurrence
* [ ] Weekly recurrence
* [ ] Selected weekdays
* [ ] Monthly recurrence
* [ ] Complete
* [ ] Skip
* [ ] Snooze
* [ ] Reschedule
* [ ] Task reminders
* [ ] Notification actions
* [ ] Offline functionality
* [ ] Native mobile install (Android APK/AAB)
* [ ] Local SQLite persistence
* [ ] Settings
* [ ] Custom notification behavior
* [ ] Custom recurrence behavior
* [ ] Export
* [ ] Import
* [ ] Phone-first UI
* [ ] Data integrity
* [ ] BS/AD conversion testing
* [ ] Notification testing (including app killed + reboot)
* [ ] Recurrence testing

---

# Recommended Development Order

## Phase 1

Foundation

```text
Flutter project setup
↓
Navigation/layout
↓
Data models
↓
SQLite (Drift/Isar)
↓
State management
↓
BS/AD date utility
```

## Phase 2

Core task system

```text
Create task
↓
Edit task
↓
Delete task
↓
Complete
↓
Skip
↓
Snooze
↓
Reschedule
```

## Phase 3

Calendar and recurrence

```text
BS calendar
↓
Today
↓
Upcoming
↓
Recurring task engine
↓
Recurring exceptions
```

## Phase 4

Native packaging

```text
App icon
↓
Splash screen
↓
Android permissions
↓
Notification channels
↓
Release build config
```

## Phase 5

Notifications

```text
Permission
↓
Reminder engine
↓
Scheduled local notifications
↓
Reboot reschedule
↓
Complete action
↓
Skip action
↓
Snooze action
```

## Phase 6

Advanced features

```text
Categories
Tags
Subtasks
Search
Filters
Statistics
History
Archive
Bulk actions
```

## Phase 7

Customization

```text
Settings
Themes
Date preferences
Notification preferences
Recurrence preferences
Task defaults
Calendar preferences
```

## Phase 8

Data management

```text
Export
Import
Backup
Restore
Error recovery
```

## Phase 9

V1.3 Testing

```text
Functional tests
↓
Recurrence tests
↓
Calendar tests
↓
Notification tests
↓
Offline tests
↓
Performance tests
↓
Accessibility tests
↓
Security/privacy review
↓
Bug fixing
```

## Phase 10

V2 Stable

```text
Freeze features
↓
Final regression test
↓
Android release build
↓
Real-device notification test
↓
Stable release
```

---

# Definition of Done

The project is considered complete when a user can:

1. Install the Android app.
2. Open it without internet.
3. Create a task using a BS date.
4. Set a time.
5. Set a reminder.
6. Make it recurring.
7. Receive a notification even if the app was closed.
8. Complete the task from the app or notification.
9. Snooze it.
10. Skip it.
11. Reschedule it.
12. View it on the BS calendar.
13. See its history.
14. Customize application behavior through Settings.
15. Export their data.
16. Import their data.
17. Force-stop and reopen the app without losing data.
18. Reboot the device and still receive scheduled reminders.
19. Continue using core functionality offline.
20. Trust that recurring tasks and dates behave correctly.

---

# Final Product Philosophy

The application should remain:

**Simple to use.
Powerful when customized.
Offline first.
Private by default.
BS-friendly.
Reliable with recurring tasks.
Reliable with reminders.**

The user should not need to understand the internal complexity.

The underlying system can be sophisticated.

The interface should not be.

The most important feature is not the number of features.

It is:

> **When I tell the app to remind me about something tomorrow, it should actually remind me tomorrow.**

Everything else comes after that.
