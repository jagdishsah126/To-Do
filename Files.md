# Codebase Map (`Files.md`)

> **Project:** Zara To-Do — Personal Offline-First Todo App with Bikram Sambat Calendar (Native Android & PWA)
> **Active Root Directory:** `/home/jagdish/Desktop/Sandbox/Zara/To_Do/Capacitor`

```
Capacitor/
├── capacitor.config.ts                # Capacitor native configuration (appId, appName, webDir, plugins)
├── android/                           # Generated native Android Studio & Gradle project
├── public/
│   ├── favicon.svg
│   └── icons/
│       ├── icon-192.png               # 192x192 PWA app icon
│       ├── icon-512.png               # 512x512 PWA app icon
│       ├── icon-512-maskable.png      # 512x512 maskable icon for Android adaptive icons
│       ├── badge-72.png               # 72x72 monochrome badge for notifications
│       ├── shortcut-add.png           # 96x96 PWA shortcut icon for Add Task
│       └── shortcut-today.png         # 96x96 PWA shortcut icon for Today view
│
├── scripts/
│   └── generate_icons.py              # Python Pillow script generating all PWA/shortcut icons
│
├── docs/
│   └── notification-capabilities.md   # Phase 0 notification matrix, platform limits, fallbacks
│
├── src/
│   ├── types/
│   │   ├── index.ts                   # Core data models: TaskSeries, TaskOccurrence, RecurrenceRule, etc.
│   │   └── bikram-sambat.d.ts         # TypeScript module declaration for bikram-sambat
│   │
│   ├── utils/
│   │   ├── constants.ts               # App constants: DB name/version, backup format, default settings
│   │   ├── bsUtils.ts                 # Centralized Bikram Sambat ↔ AD date conversion and month formatting
│   │   ├── dateUtils.ts               # Gregorian/AD date helpers, local timezone policy, day boundaries
│   │   └── haptics.ts                 # navigator.vibrate wrapper with graceful fallback
│   │
│   ├── db/
│   │   ├── database.ts                # IndexedDB open, connection management, object store names
│   │   ├── migrations.ts              # Database schema migrations (v1 baseline and future migrations)
│   │   ├── taskDb.ts                  # TaskSeries & TaskOccurrence CRUD, date range queries, archiving
│   │   └── settingsDb.ts              # Settings persistence in IndexedDB
│   │
│   ├── store/
│   │   ├── taskStore.ts               # Zustand store for series, occurrences, filters, and bulk select
│   │   ├── settingsStore.ts           # Zustand store for persistent user preferences
│   │   └── uiStore.ts                 # Zustand store for bottom sheets, undo stack, focus mode, active tab
│   │
│   ├── domain/
│   │   ├── notifications/
│   │   │   ├── PermissionManager.ts   # Notification permission check and request utilities
│   │   │   ├── CapabilityDetector.ts  # Runtime platform feature detection for notification APIs
│   │   │   ├── NotificationScheduler.ts # Notification reminder timers, focus mode & quiet hours filtering
│   │   │   ├── ServiceWorkerBridge.ts # Bidirectional message bridge to Service Worker
│   │   │   └── NotificationActionHandler.ts # Handles Complete/Snooze/Skip action payloads from notifications
│   │   └── recurrence/
│   │       ├── recurrenceEngine.ts    # Deterministic recurrence calculations (daily, weekly, monthly, yearly)
│   │       └── __tests__/
│   │           └── recurrenceEngine.test.ts # Vitest suite covering all recurrence rules and exceptions
│   │
│   ├── services/
│   │   ├── backupService.ts           # Versioned JSON backup export and import validation
│   │   ├── recurrenceService.ts       # Recurrence occurrence hydration, progression, and 3 editing scopes
│   │   └── notificationService.ts     # High-level reminder synchronization across 24h windows
│   │
│   ├── components/
│   │   ├── layout/
│   │   │   ├── TopHeader.tsx          # Mobile header displaying current BS date, weekday, and focus mode
│   │   │   ├── BottomNav.tsx          # Mobile bottom navigation bar (Today, Calendar, Search, Settings)
│   │   │   └── MobileLayout.tsx       # Main layout wrapper constrained to mobile dimensions
│   │   │
│   │   ├── common/
│   │   │   ├── BottomSheet.tsx        # Slide-up modal sheet container with backdrop blur and drag handle
│   │   │   ├── GlobalBottomSheet.tsx  # Modal dispatcher opening CreateTask, TaskDetail, or Snooze sheets
│   │   │   ├── UndoToast.tsx          # Floating undo notification toast for reversible actions
│   │   │   └── PWAInstallPrompt.tsx   # Mobile PWA installation banner capturing beforeinstallprompt
│   │   │
│   │   └── tasks/
│   │       ├── CreateTaskSheet.tsx    # Task creation sheet with Bikram Sambat date picker & priority
│   │       ├── TaskDetailSheet.tsx    # Task detail inspection, complete, snooze, skip, pin, and delete
│   │       ├── SnoozeSheet.tsx        # Quick snooze interval selector with undo support
│   │       └── TaskCountdown.tsx      # Live 1-second countdown/countup timer badge for due tasks
│   │
│   ├── pages/
│   │   ├── TodayPage.tsx              # Today view with Overdue, Pinned, Today, and Completed task groups
│   │   ├── CalendarPage.tsx           # Monthly Bikram Sambat calendar grid with agenda and task dots
│   │   ├── SearchPage.tsx             # Real-time search with status filter chips and preview cards
│   │   └── SettingsPage.tsx           # Settings, Phase 0 notification diagnostic panel, and backup tools
│   │
│   ├── sw/
│   │   ├── sw.ts                      # Service Worker entry point with Workbox precaching
│   │   └── notificationHandler.ts     # Service Worker notification click, action, and message handlers
│   │
│   ├── App.tsx                        # Application root, data hydration, PWA shortcut router, SW listener
│   ├── main.tsx                       # React DOM root render
│   └── index.css                      # Global styles, Tailwind v4 import, safe-area insets
│
├── index.html                         # Mobile-optimized HTML shell with viewport and PWA meta tags
├── vite.config.ts                     # Vite configuration with React, Tailwind v4, and VitePWA
└── tsconfig.json                      # TypeScript project configuration
```

---

## 🔍 Exported Symbols & Responsibilities

### `src/utils/bsUtils.ts`
- `adToBS(date: Date): BSDate` — Convert AD Date to Bikram Sambat year, month, day.
- `bsToAD(bs: BSDate): Date` — Convert BS date to local AD Date.
- `todayBS(): BSDate` — Returns today's date in Bikram Sambat.
- `todayAD(): Date` — Returns today's date at local midnight.
- `formatBS(bs, opts): string` — Formats BS date into readable text (e.g. "2083 असोज 9").
- `formatDateBS(date, opts): string` — Formats AD Date into BS string.
- `weekdayName(date, short): string` — Returns weekday name in English.
- `bsMonthName(month, lang): string` — Returns Nepali month name in Devanagari or English.
- `bsMonthDays(year, month): Date[]` — Computes all AD Dates falling in a specific BS month.
- `bsMonthBoundaries(year, month)` — Returns start and end AD Dates for a BS month.
- `bsMonthOffset(year, month, delta)` — Navigates BS months with year roll-over.
- `isSameBSDay(a, b): boolean` — Compares two BSDate objects for equality.
- `isCurrentBSMonth(date): boolean` — Checks if an AD Date falls into current BS month.

### `src/utils/dateUtils.ts`
- `startOfDay(date: Date): Date` — Normalizes Date to 00:00:00.000.
- `endOfDay(date: Date): Date` — Normalizes Date to 23:59:59.999.
- `today(): Date` — Current day at midnight.
- `tomorrow(): Date` — Tomorrow at midnight.
- `isSameDay(a, b): boolean` — Checks if two dates share the same calendar day.
- `isToday(date: Date): boolean` — Checks if date is today.
- `isPast(scheduledAt: string): boolean` — Checks if an ISO timestamp is before now.
- `isOverdue(scheduledAt: string): boolean` — Checks if a task is before today's start.
- `compareDates(a, b): number` — Sorting comparator for ISO date strings.
- `formatTime(date, format): string` — Formats Date to 12h ("7:00 PM") or 24h ("19:00").
- `isQuietHours(now, start, end): boolean` — Evaluates whether current time falls into quiet hours.
- `generateId(): string` — Generates collision-resistant unique IDs.

### `src/utils/haptics.ts`
- `haptic.light()` — 10ms gentle vibration for selections.
- `haptic.medium()` — 20ms tap vibration for confirmations.
- `haptic.heavy()` — Pattern vibration for warnings and deletions.
- `haptic.success()` — Multi-pulse pattern for task completions.
- `haptic.error()` — Vibration pattern for invalid actions.

### `src/db/taskDb.ts`
- `getAllSeries(): Promise<TaskSeries[]>` — Fetches all task series definitions.
- `createSeries(data): Promise<TaskSeries>` — Persists new task series.
- `updateSeries(id, updates): Promise<TaskSeries | undefined>` — Updates task series.
- `deleteSeries(id): Promise<void>` — Permanently deletes a task series.
- `getAllOccurrences(): Promise<TaskOccurrence[]>` — Fetches all occurrences.
- `getOccurrencesForDateRange(start, end): Promise<TaskOccurrence[]>` — Queries indexed date range.
- `createOccurrence(data): Promise<TaskOccurrence>` — Inserts a scheduled task instance.
- `updateOccurrence(id, updates): Promise<TaskOccurrence | undefined>` — Updates task instance status.
- `archiveOccurrence(id): Promise<void>` — Soft-deletes occurrence into archive store.

### `src/store/taskStore.ts`
- `useTaskStore` — Zustand store managing loaded series, occurrences, filter state, multi-select, and instant mutations with optimistic updates and DB synchronization.

### `src/store/uiStore.ts`
- `useUIStore` — Zustand store managing active tab (`home`, `calendar`, `search`, `settings`), active bottom sheet, 4-second undo stack, focus mode timers, and search queries.

### `src/domain/notifications/PermissionManager.ts`
- `getPermissionStatus(): PermissionStatus` — Returns 'granted' | 'denied' | 'default' | 'unsupported'.
- `requestPermission(): Promise<PermissionStatus>` — Requests browser notification permission.

### `src/domain/notifications/CapabilityDetector.ts`
- `detectCapabilities(): Promise<NotificationCapabilities>` — Runs runtime diagnostics on notification support and caches results in localStorage.

### `src/domain/notifications/NotificationScheduler.ts`
- `scheduleNotification(options)` — Schedules reminders with Focus Mode & Quiet Hours checks.
- `cancelNotification(occurrenceId)` — Clears timer and sends cancel event to Service Worker.
- `clearAllScheduled()` — Cleans up all active in-memory timers.

### `src/domain/notifications/ServiceWorkerBridge.ts`
- `sendSWMessage(message)` — Sends typed messages to the active Service Worker.
- `onSWMessage(handler)` — Subscribes to messages dispatched from the Service Worker.

### `src/domain/notifications/NotificationActionHandler.ts`
- `handleNotificationAction(payload)` — Processes Complete, Snooze, Skip, and Open events from notification clicks.

### `src/domain/recurrence/recurrenceEngine.ts`
- `generateNextOccurrence(rule, baseDate, afterDate)` — Calculates the next scheduled date.
- `generateOccurrencesInRange(rule, baseDate, rangeStart, rangeEnd)` — Generates occurrence dates within a bounded window.
- `isDateException(rule, date)` — Checks if a date is listed as skipped/modified.
- `buildNextOccurrence(series, currentOccurrence)` — Creates the next upcoming TaskOccurrence record.

### `src/services/recurrenceService.ts`
- `hydrateOccurrencesForRange(start, end)` — Ensures recurring tasks have DB records in the visible window.
- `onOccurrenceCompletedOrSkipped(occ)` — Automatically advances recurring series to next occurrence.
- `skipRecurringOccurrence(occId)` — Skips current occurrence and registers date as an exception.
- `editThisOccurrenceOnly(occId, overrides)` — Sets exceptionData on specific occurrence.
- `editThisAndFutureOccurrences(seriesId, splitDate, newSeries)` — Splits series at boundary date.
- `editEntireSeries(seriesId, updates)` — Updates parent TaskSeries.

### `src/services/notificationService.ts`
- `syncUpcomingReminders()` — Re-evaluates upcoming 24h tasks and schedules notifications.
- `scheduleOccurrenceReminder(occurrence)` — Schedules a single occurrence reminder.
- `cancelOccurrenceReminder(occurrenceId)` — Cancels a single occurrence reminder.

### `src/services/backupService.ts`
- `exportBackupJSON(): Promise<void>` — Creates and downloads a versioned JSON backup of all IndexedDB tables.
- `importBackupJSON(file: File): Promise<void>` — Validates schema version and restores records to IndexedDB.

### `src/components/common/PWAInstallPrompt.tsx`
- `PWAInstallPrompt` — Catches `beforeinstallprompt` event and shows custom mobile installation banner.
