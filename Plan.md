# Personal Todo PWA

## Project Overview

A personal, offline-first Todo and Reminder Progressive Web App (PWA).

The application is designed primarily for mobile use while remaining fully usable as a website on desktop.

The core purpose is:

> Create a task → Schedule it → Receive a notification → Complete, Snooze, Skip, or Reschedule it → Repeat when required.

The application should feel like a lightweight personal task manager rather than a complicated enterprise productivity platform.

---

# Core Principles

1. **Offline First**

   * Core functionality must work without an internet connection.
   * Tasks must remain available offline.
   * Creating, editing, completing, skipping, and snoozing tasks must work offline.

2. **Local First**

   * V1 stores user data locally.
   * No account should be required.
   * No backend is required for the core application.

3. **AD for Internal Date Logic**

   * Store and calculate dates internally using Gregorian/AD dates.
   * AD is the canonical internal representation because JavaScript and browser APIs use Gregorian dates naturally.

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

7. **Mobile First**

   * Design primarily for phone screens.
   * Desktop remains fully supported.

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

> Build a complete basic task system with reliable local storage and a working PWA foundation.

Do not add every advanced feature immediately.

---

## 1. Project Foundation

### Technology

Recommended:

* Vite
* React
* TypeScript
* Tailwind CSS
* PWA support
* IndexedDB
* Service Worker

State management can use:

* Zustand
* or another lightweight state-management solution

The architecture should remain modular enough to replace individual technologies later.

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

Use IndexedDB for persistent application data.

Data must survive:

* Page refresh
* Browser restart
* PWA restart
* Offline operation

Do not rely solely on React state or ordinary temporary variables.

---

# 13. PWA

The application must:

* Install on mobile
* Install on desktop
* Have an app icon
* Have a splash/loading experience where supported
* Work offline
* Cache required application assets
* Open independently from the browser

---

# 14. Responsive UI

Must support:

* Mobile
* Tablet
* Desktop

Priority:

```text
Mobile > Tablet > Desktop
```

The interface should not feel like a desktop website squeezed into a phone.

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

If practical for the PWA:

* Images
* Documents
* Files

Attachments should be stored locally or through a future storage layer.

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

---

# 28. Notification Actions

Where supported by the platform/browser:

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

## PWA

* Installation information
* Notification permission status
* Storage information
* Service Worker status

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
* App closed
* PWA installed
* Device locked
* Offline
* Browser restarted
* Notification permission denied
* Notification permission restored
* Snooze
* Complete from notification
* Skip from notification
* Recurring notification

Also document platform limitations.

Do not promise notification behavior that the browser/OS cannot reliably provide.

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

* Refresh
* Close browser
* Reopen PWA
* Browser restart
* Large task count
* Repeated editing
* Import/export
* Corrupted backup
* Duplicate task IDs
* Invalid task data

The app should fail safely rather than silently destroying data.

---

# 57. Responsive Testing

Test at:

* Small Android phone
* Large Android phone
* Tablet
* Laptop
* Desktop

Test portrait and landscape.

---

# 58. Performance Testing

Check:

* Initial load
* Calendar rendering
* Large task history
* Search performance
* Recurrence calculation
* IndexedDB operations
* Service Worker caching
* Notification scheduling

Avoid unnecessary libraries and excessive re-rendering.

---

# 59. Accessibility Testing

Minimum:

* Keyboard navigation
* Screen-reader labels
* Adequate contrast
* Focus states
* Touch-friendly controls
* Accessible notification/task actions
* Reduced-motion support

---

# 60. Error Handling

The app should handle:

* Notification permission denied
* Storage unavailable
* Invalid imported data
* Corrupted backup
* Service Worker failure
* Date conversion failure
* Unexpected recurrence data
* Browser limitations

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

# 62. PWA Audit

Verify:

* Manifest
* Icons
* Service Worker
* Offline cache
* Installability
* HTTPS deployment
* Correct app name
* Correct theme
* Correct orientation
* App shortcuts if supported

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
* Notifications stable within platform limitations
* Offline operation stable
* PWA installation stable
* Local database stable

### UX

* Fast task creation
* Clear Today view
* Reliable calendar
* Simple task actions
* Customizable settings
* Good mobile experience

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
* [ ] PWA installation
* [ ] IndexedDB/local persistence
* [ ] Settings
* [ ] Custom notification behavior
* [ ] Custom recurrence behavior
* [ ] Export
* [ ] Import
* [ ] Responsive mobile UI
* [ ] Data integrity
* [ ] BS/AD conversion testing
* [ ] Notification testing
* [ ] Recurrence testing

---

# Recommended Development Order

## Phase 1

Foundation

```text
Project setup
↓
Routing/layout
↓
Data models
↓
IndexedDB
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

PWA

```text
Manifest
↓
Service Worker
↓
Offline cache
↓
Installability
```

## Phase 5

Notifications

```text
Permission
↓
Reminder engine
↓
Notification display
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
Production deployment
↓
PWA installation test
↓
Real-device test
↓
Stable release
```

---

# Definition of Done

The project is considered complete when a user can:

1. Open the website.
2. Install it as a PWA.
3. Use it without internet.
4. Create a task using a BS date.
5. Set a time.
6. Set a reminder.
7. Make it recurring.
8. Receive a notification.
9. Complete the task from the app or notification.
10. Snooze it.
11. Skip it.
12. Reschedule it.
13. View it on the BS calendar.
14. See its history.
15. Customize application behavior through Settings.
16. Export their data.
17. Import their data.
18. Close and reopen the app without losing data.
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

