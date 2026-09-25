# Work_Step.md — Personal Todo PWA
> **Last Updated:** 2083-06-09 BS (2026-09-25 AD)
> **Status:** Architecture Reviewed — Ready to Build

---

## 🔑 Locked Decisions

| Decision | Choice |
|----------|--------|
| **Framework** | Vite + React + TypeScript |
| **Styling** | Tailwind CSS only (full custom UI) |
| **State Management** | Zustand |
| **Database** | IndexedDB (with versioned migrations) |
| **BS/AD Calendar** | `bikram-sambat` npm package |
| **Notifications** | Native Android via Capacitor (`@capacitor/local-notifications`) |
| **Target Platform** | **Android only** (Capacitor Native App / APK) |
| **Deployment** | Android APK / Capacitor |
| **Navigation** | Bottom navigation bar (Home, Calendar, Search, Settings) |
| **UI Style** | Minimal / clean (Apple Reminders aesthetic) |
| **Language** | English UI + Nepali for calendar/dates only |
| **Recurrence Storage** | Custom internal JSON model (`RecurrenceRule`) |
| **Task Model** | `TaskSeries` + `TaskOccurrence` (separated) |
| **Task Interaction** | Swipe gestures + Long press multi-select |
| **Task Creation** | Bottom sheet modal (slides up from bottom) |
| **Haptic Feedback** | Yes — on complete, snooze, swipe (with `navigator.vibrate` fallback) |
| **Backup Format** | Versioned JSON (`format` + `version` + `exportedAt`) |

---

## 📦 Confirmed Features (beyond original Plan.md)

- [ ] Focus Mode — silences non-urgent tasks for X minutes
- [ ] Task Templates — reusable templates for recurring task patterns
- [ ] PWA Home Screen Quick Actions — "Add Task" and "Today" shortcuts on app icon
- [ ] Pin/Star Tasks — surface critical tasks above fold in Today view
- [ ] Swipe Gestures — right = complete, left = snooze/skip options
- [ ] Long Press Multi-Select — bulk actions on selected tasks
- [ ] Haptic Feedback — vibration on complete, snooze, swipe
- [ ] Bottom Sheet Modals — task create/edit/detail as native-feeling sheets
- [ ] Storage Quota Warning — warn user before IndexedDB storage limit
- [ ] Task Duplication — quick "copy task" action
- [ ] Undo for destructive actions — "Task skipped [Undo]" toast

---

## ⚠️ Architecture Principles (Non-Negotiable)

These apply across all phases:

1. **UI never touches IndexedDB directly** — always goes through `db/` layer
2. **BS conversion never happens in components** — only via `utils/bsUtils.ts`
3. **All internal timestamps are AD ISO strings** — BS is display only
4. **TaskSeries ≠ TaskOccurrence** — never conflate the two in the data model
5. **Notifications are PoC-tested before full implementation** — no assumed capabilities
6. **IndexedDB schema changes go through migrations** — never destroy user data
7. **Backups are versioned** — imports validate format + version before touching data
8. **Swipe destructive actions have an Undo** — complete/skip/archive

---

## 📐 Folder Structure (Final)

```
src/
├── components/          # Reusable UI components (TaskCard, BottomSheet, etc.)
├── pages/               # Top-level screens (Today, Calendar, Search, Settings)
├── store/               # Zustand stores (taskStore, settingsStore, uiStore)
│
├── db/
│   ├── database.ts      # IndexedDB init, version, open
│   ├── migrations.ts    # Schema migrations (v1 → v2, etc.)
│   ├── taskDb.ts        # TaskSeries + TaskOccurrence CRUD
│   └── settingsDb.ts    # Settings persistence
│
├── domain/
│   ├── tasks/           # Task business logic (state transitions, validation)
│   ├── recurrence/      # RecurrenceRule engine (generate, advance, exceptions)
│   ├── notifications/   # NotificationManager, CapabilityDetector, Scheduler
│   └── calendar/        # BS calendar logic, month generation, day mapping
│
├── services/
│   ├── notificationService.ts   # High-level notification API
│   ├── recurrenceService.ts     # Occurrence generation + caching
│   ├── backupService.ts         # Export/import with validation
│   └── storageService.ts        # Storage quota monitoring
│
├── utils/
│   ├── bsUtils.ts        # BS ↔ AD conversion (ONLY place this happens)
│   ├── dateUtils.ts      # AD date helpers, timezone policy, comparisons
│   ├── haptics.ts        # navigator.vibrate wrapper with fallback
│   └── validation.ts     # Backup/import validation, task validation
│
├── hooks/               # Custom React hooks
├── types/               # TypeScript interfaces and enums
└── sw/                  # Service Worker files (notification handler, etc.)
```

---

## 🗂️ Core Data Models

### TaskSeries
```ts
interface TaskSeries {
  id: string
  title: string
  description?: string
  category?: string
  tags: string[]
  priority: 'low' | 'normal' | 'high' | 'urgent'
  duration?: number            // minutes
  recurrenceRule?: RecurrenceRule
  reminderConfig: ReminderConfig
  isPinned: boolean
  isTemplate: boolean
  createdAt: string            // AD ISO
  updatedAt: string            // AD ISO
}
```

### TaskOccurrence
```ts
interface TaskOccurrence {
  id: string
  seriesId: string             // links to TaskSeries
  scheduledAt: string          // AD ISO — the intended date+time
  status: OccurrenceStatus
  completedAt?: string
  snoozedUntil?: string
  skippedAt?: string
  isException: boolean         // manually edited from series default
  exceptionData?: Partial<TaskSeries>  // overrides for this occurrence only
}

type OccurrenceStatus =
  | 'upcoming' | 'due' | 'in_progress'
  | 'completed' | 'snoozed' | 'skipped'
  | 'missed' | 'cancelled'
```

### RecurrenceRule
```ts
interface RecurrenceRule {
  type: 'daily' | 'weekdays' | 'weekly' | 'monthly' | 'yearly' | 'custom'
  interval: number             // every N days/weeks/months
  daysOfWeek?: number[]        // 0=Sun … 6=Sat (for weekly)
  monthlyType?: 'date' | 'first_weekday' | 'last_weekday'
  endType: 'never' | 'date' | 'count'
  endDate?: string             // AD ISO
  maxCount?: number
  exceptions: string[]         // AD date strings of skipped/modified dates
}
```

### VersionedBackup
```ts
interface VersionedBackup {
  format: 'personal-todo-backup'
  version: number              // increment on breaking changes
  exportedAt: string           // AD ISO
  appVersion: string           // semver
  data: {
    series: TaskSeries[]
    occurrences: TaskOccurrence[]
    settings: AppSettings
    categories: Category[]
    tags: Tag[]
    templates: TaskSeries[]
  }
}
```

---

## 🗺️ Development Phases

---

## Phase 0 — Notification & PWA Proof of Concept
> **⚡ Do this BEFORE writing the main application.**
> Goal: Verify what Android Chrome actually supports. Document real limits.

> [!IMPORTANT]
> If the PoC fails, the fallback design must be decided before Phase 6.
> Never assume notification features work — prove them first.

- [x] **0.1** Set up minimal Vite PWA project (Manifest + Service Worker only)
- [ ] **0.2** Deploy to Vercel (HTTPS required for SW + Notifications)
- [ ] **0.3** Install as PWA on a real Android device (Chrome)
- [x] **0.4** Test notification permission request flow
- [x] **0.5** Show a basic notification from the Service Worker
- [x] **0.6** Test notification click — does it open/focus the PWA?
- [x] **0.7** Add notification actions (Complete / Snooze / Skip buttons)
- [ ] **0.8** Test actions when: **app open** / **app closed** / **phone locked**
- [ ] **0.9** Test behavior after device restart — do scheduled notifications survive?
- [ ] **0.10** Test behavior while **offline** — do notifications still fire?
- [x] **0.11** Document findings in `docs/notification-capabilities.md`:
  - What works reliably ✅
  - What works sometimes ⚠️
  - What does not work ❌
  - Fallback for each failed capability
- [ ] **0.12** Decide: Does the notification architecture need adjustment before Phase 6?

**Acceptance Criteria:**
- We know exactly what the Android Chrome PWA notification system can and cannot do
- Every capability is marked as ✅ guaranteed / ⚠️ partial / ❌ unsupported
- A fallback is documented for each ⚠️ and ❌

---

## Phase 1 — Foundation
> Goal: Project skeleton, tooling, core architecture
> Depends on: Phase 0 findings (notification arch confirmed)

- [x] **1.1** Initialize Vite + React + TypeScript project
- [x] **1.2** Install and configure Tailwind CSS
- [x] **1.3** Install core dependencies:
  - `zustand` — state management
  - `bikram-sambat` — BS/AD conversion
  - `idb` — typed IndexedDB wrapper
  - `vite-plugin-pwa` — PWA + Workbox
- [x] **1.4** Set up folder structure (as defined in Architecture section above)
- [x] **1.5** Define all TypeScript types in `types/`:
  - `TaskSeries`, `TaskOccurrence`, `RecurrenceRule`
  - `OccurrenceStatus`, `ReminderConfig`
  - `AppSettings`, `Category`, `Tag`
  - `VersionedBackup`
- [x] **1.6** Build IndexedDB layer:
  - `db/database.ts` — open DB, define version, object stores
  - `db/migrations.ts` — migration runner (v1 baseline → future versions)
  - Object stores: `series`, `occurrences`, `settings`, `categories`, `tags`, `archivedOccurrences`
- [x] **1.7** Build `db/taskDb.ts` (all task CRUD through this file only):
  - `createSeries()`, `updateSeries()`, `deleteSeries()`
  - `createOccurrence()`, `updateOccurrence()`, `deleteOccurrence()`
  - `getOccurrencesForDateRange()`
  - `getSeriesById()`, `getAllSeries()`
- [x] **1.8** Build `db/settingsDb.ts`:
  - `getSettings()`, `saveSettings()`, `resetSettings()`
- [x] **1.9** Build Zustand stores:
  - `taskStore` — loaded series/occurrences, filters, selection
  - `settingsStore` — settings (synced with IndexedDB)
  - `uiStore` — modal state, focus mode, current view
- [x] **1.10** Build `utils/bsUtils.ts` (ONLY place for BS↔AD):
  - `adToBS(date: Date): BSDate`
  - `bsToAD(bs: BSDate): Date`
  - `formatBS(date: Date, opts): string` — e.g. "2083 असोज 9"
  - `todayBS(): BSDate`
  - `weekdayNameBS(date: Date): string`
  - `bsMonthBoundaries(year: number, month: number): { start: Date, end: Date }`
- [x] **1.11** Build `utils/dateUtils.ts` (AD helpers, timezone policy):
  - Timezone policy: always use device timezone
  - `startOfDay(date: Date): Date`
  - `endOfDay(date: Date): Date`
  - `isSameDay(a: Date, b: Date): boolean`
  - `isOverdue(scheduledAt: string): boolean`
  - `isPast(scheduledAt: string): boolean`
  - `compareDates(a: string, b: string): number`
- [x] **1.12** Build `utils/haptics.ts`:
  ```ts
  // Graceful: does nothing if navigator.vibrate unavailable
  export const haptic = { light, medium, heavy, success, error }
  ```
- [x] **1.13** Set up flat mobile nav routing (Home / Calendar / Search / Settings)
- [x] **1.14** Build bottom navigation bar shell (Home / Calendar / Search / Settings)
- [x] **1.15** Build base mobile layout (max-width: 430px, safe area insets, no overflow)

**Acceptance Criteria:**
- App loads, shows clean screens with bottom nav
- IndexedDB opens without error (DB version 1, all object stores created)
- `bsToAD(adToBS(new Date()))` round-trips correctly
- Haptic utility works on Android, silently does nothing on desktop
- All TypeScript types are defined and compile cleanly

---

## Phase 2 — Core Task System
> Goal: Full task lifecycle working end-to-end (non-recurring tasks only)
> Depends on: Phase 1 complete

- [ ] **2.1** `domain/tasks/taskActions.ts` — pure business logic:
  - `completeOccurrence(occurrence): TaskOccurrence`
  - `skipOccurrence(occurrence): TaskOccurrence`
  - `snoozeOccurrence(occurrence, until: string): TaskOccurrence`
  - `rescheduleOccurrence(occurrence, newDate: string): TaskOccurrence`
  - `missOccurrence(occurrence): TaskOccurrence`
  - `deriveStatus(occurrence): OccurrenceStatus`
- [x] **2.2** Task creation — Bottom sheet:
  - Quick Add: title + BS date + time → creates `TaskSeries` + first `TaskOccurrence`
  - Expandable: priority, category, reminder, recurrence
- [x] **2.3** Task editing — same bottom sheet, pre-filled with series data
- [x] **2.4** Task deletion with confirmation (soft delete → archive, not destroy)
- [x] **2.6** Task detail bottom sheet:
  - Full series + occurrence info displayed
  - Action buttons: Edit / Complete / Snooze / Skip / Pin / Delete
  - Notes field
- [x] **2.8** Task action UI:
  - ✅ Complete → haptic success + Undo toast ("Completed [Undo]")
  - 💤 Snooze → options sheet (5m / 10m / 15m / 30m / 1h / Tomorrow / Custom)
  - ⏭ Skip → confirmation → haptic + Undo toast ("Skipped [Undo]")
- [x] **2.10** Long press → multi-select mode with selection count badge
- [x] **2.12** Pin/Star toggle — pinned tasks shown above all others in Today view
- [x] **2.13** Undo system (`uiStore.undoStack`):
  - Last destructive action stored for 4 seconds
  - "Undo" toast shown — tap to reverse
  - Auto-clears after timeout

**Acceptance Criteria:**
- Create a task, see it in Today view
- Complete/skip/snooze/reschedule all work and persist after page refresh
- Undo works for skip and complete
- Long press enters multi-select

---

## Phase 3 — Views (Today, Upcoming, Calendar)
> Goal: All three main views working with real data
> Depends on: Phase 2 complete

- [x] **3.1** Today View:
  - Sections: PINNED → OVERDUE → TODAY → COMPLETED (collapsible)
  - Empty state illustration when no tasks
- [x] **3.3** BS Monthly Calendar View:
  - Full BS month grid built from `bsUtils.bsMonthDays()`
  - Previous / Next month navigation
  - "Today" jump button
  - Day cell dots: task count / overdue / high-priority
  - Tap day → day task list in agenda view
  - Task creation from selected day (pre-fills date)
  - Recurring task indicators

---

## Phase 4 — Recurring Task Engine
> Goal: Rock-solid recurrence — generates correct occurrences only when needed
> Depends on: Phase 2 complete

- [x] **4.1** `domain/recurrence/recurrenceEngine.ts`:
  - `generateNextOccurrence(rule, after: Date): Date | null`
  - `generateOccurrencesInRange(rule, start: Date, end: Date): Date[]`
  - `isDateException(rule, date: Date): boolean`
  - `buildNextOccurrence(series, currentOccurrence): TaskOccurrence`
- [x] **4.2** All recurrence types:
  - Daily
  - Weekdays only (Mon–Fri)
  - Weekly (specific days — `daysOfWeek`)
  - Every X days / weeks / months (`interval`)
  - Monthly same date
  - Monthly first/last weekday (`monthlyType`)
  - Yearly
- [x] **4.3** End conditions: Never / On date (`endDate`) / After N (`maxCount`)
- [x] **4.4** Exception handling:
  - Skip adds date to `exceptions[]` — engine skips it on generation
  - Edited occurrence sets `isException: true` + `exceptionData` override
- [x] **4.5** Recurring task editing dialog — three scopes:
  - **This occurrence** → create exception occurrence, series unchanged
  - **This and future** → split series at this date, update new series
  - **Entire series** → update `TaskSeries` directly
- [x] **4.7** `services/recurrenceService.ts`:
  - `hydrateOccurrencesForRange(start, end)` — generates + saves missing occurrences
  - `onOccurrenceCompletedOrSkipped(occ)` — advances series after action
  - `skipRecurringOccurrence(occId)` — records exception and advances
- [x] **4.8** Recurrence unit tests (`domain/recurrence/__tests__/`):
  - Daily, weekly, weekdays, monthly, yearly — verified next dates
  - End date / max count — verified series terminates
  - Exception dates — verified skipped correctly
  - 8/8 tests passing via Vitest
  - Exception dates — verify skipped correctly
  - Edge cases: month end, year end, leap year behavior

**Acceptance Criteria:**
- "Every Mon/Wed/Fri" task generates correct future dates for 3 months
- Skipping one occurrence does not affect others
- "Edit this and future" splits the series at correct date
- All recurrence types tested and passing

---

## Phase 5 — PWA Setup
> Goal: App installs on mobile, works fully offline
> Depends on: Phase 0 (PoC already verified on device)

- [x] **5.1** Configure `vite-plugin-pwa`:
  - `manifest.json` (name, icons, `display: standalone`, `orientation: portrait`)
  - Workbox cache strategy: Cache-first for app shell assets
  - No network fetches — pure local app, no cache-miss fallback needed
- [x] **5.2** Design app icons (all required sizes: 192, 512, maskable, badge, shortcuts)
- [x] **5.3** Custom PWA install prompt UI (`PWAInstallPrompt.tsx` with beforeinstallprompt handler)
- [x] **5.4** PWA manifest shortcuts:
  - `"Add Task"` → opens app with task creation sheet
  - `"Today"` → opens app to Today view
- [x] **5.7** Standalone mode detection and layout optimization
- [x] **5.8** PWA status section in Settings:
  - Installation state (Standalone vs Browser)
  - Notification permission status
  - Storage quota used / available via `navigator.storage.estimate()`
  - Service Worker status

**Acceptance Criteria:**
- App installs from Chrome on Android
- Installed app opens in standalone mode (no URL bar)
- App loads fully while offline after first install
- Home screen shortcuts work

---

## Phase 6 — Notifications
> Goal: Reliable local notifications based on PoC findings
> Depends on: Phase 0 (capabilities documented), Phase 4 (recurrence engine)

- [x] **6.1** `domain/notifications/` architecture:
  - `PermissionManager.ts` — request, check, track permission state
  - `CapabilityDetector.ts` — detect what current platform/browser supports
  - `NotificationScheduler.ts` — schedule/cancel via SW & in-memory timers
  - `ServiceWorkerBridge.ts` — postMessage channel between app ↔ SW
  - `NotificationActionHandler.ts` — handle Complete/Snooze/Skip from notification
- [x] **6.2** Permission request flow:
  - Graceful permission check & re-request option in Settings
- [x] **6.3** `services/notificationService.ts` (high-level API):
  - `syncUpcomingReminders()` — schedules 24h reminder window
  - `scheduleOccurrenceReminder(occurrence)`
  - `cancelOccurrenceReminder(occurrenceId)`
- [x] **6.4** Notification content:
  - Title: task title
  - Body: BS date + time
  - Actions: Complete | Snooze 15m | Skip
- [x] **6.5** Service Worker (`sw/notificationHandler.ts`):
  - `notificationclick` handler → focus/open app
  - Action handlers → postMessage to app or directly update IndexedDB
- [x] **6.6** Recurring task: automatically advances and schedules next occurrence notification
- [x] **6.8** Quiet Hours suppression:
  - Check quiet hours before scheduling
  - Configurable start/end times in Settings
- [x] **6.9** Focus Mode:
  - `uiStore.focusMode: { active, endsAt }`
  - Suppresses non-urgent/non-pinned notifications during focus
  - Auto-ends at `endsAt` timestamp
- [ ] **6.10** Capability limitations displayed in Settings:
  - Each capability shown as ✅ / ⚠️ / ❌ based on PoC results
  - No false promises to the user

**Acceptance Criteria:**
- Notification fires at correct time for a scheduled task
- Tapping notification opens the correct task
- Complete/Snooze/Skip from notification updates task state in IndexedDB
- Quiet hours correctly suppresses notifications
- Focus mode suppresses low-priority notifications

---

## Phase 7 — Advanced Features
> Goal: Categories, Tags, Subtasks, Search, Filters, Statistics, Templates
> Depends on: Phase 3 + Phase 4

- [x] **7.3** Priority color coding on all task cards (urgent: rose, high: amber, normal/low)
- [x] **7.4** Subtasks:
  - Add / remove / toggle within task detail sheet
  - Progress indicator on task card ("☑ 2/3")
  - Visual progress bar inside task detail sheet
- [x] **7.6** Notes field (description & notes in creation and detail sheet)
- [x] **7.8** Search:
  - Full-text search across title, description, tags
  - Real-time filter chips (all, upcoming, overdue, completed, pinned)
- [x] **7.15** Bulk actions via multi-select (floating action bar with Complete, Skip, Delete)

---

## Phase 8 — Settings & Customization
> Goal: Full settings system — all behavior configurable
> Depends on: All features exist to configure

- [ ] **8.1** Settings screen sections:
  - General / Calendar / Notifications / Tasks / Recurrence / Appearance / Data / PWA
- [ ] **8.2** General: time format, week start, default duration, date display (BS/BS+AD)
- [ ] **8.3** Calendar: BS/AD toggle, first day of week, task indicator style
- [ ] **8.4** Notifications: enable/disable, default reminder, snooze options, quiet hours, missed task notifications
- [ ] **8.5** Tasks: default priority, default category, missed-task behavior, carry-forward behavior
- [ ] **8.6** Recurrence: end-of-series behavior
- [ ] **8.7** Appearance: Light / Dark / System, accent color, layout density, font size
- [ ] **8.8** Data:
  - Export versioned JSON backup
  - Export CSV (read-only export — never used for restore)
  - Import / Restore JSON (with format validation)
  - Automatic backup reminder
  - Archive management
  - Delete all data (double confirmation with typed confirmation text)
  - Storage quota display + warning at 80% full
- [ ] **8.9** PWA: install status, notification permission, SW status, capability report

---

## Phase 9 — Testing & Hardening
> Goal: Find and fix all bugs before V2
> Depends on: All phases complete

- [ ] **9.1** Functional testing (all items from Plan.md §50)
- [ ] **9.2** Recurrence edge cases (Plan.md §51) + automated tests from Phase 4
- [ ] **9.3** BS/AD conversion testing:
  - Month/year boundaries, leap years, historical + future dates
- [ ] **9.4** Timezone testing:
  - Nepal UTC+5:45, midnight transitions, device TZ changes
- [ ] **9.5** Notification testing (full checklist — app open / closed / locked / offline / restart)
- [ ] **9.6** Offline testing — all core features work without network
- [ ] **9.7** Data integrity:
  - DB migration testing (simulate schema upgrade)
  - Refresh / close / reopen
  - Import invalid/corrupted backup → graceful rejection
  - Duplicate task IDs → safe handling
- [ ] **9.8** Phone-only responsive testing (portrait + landscape, small + large Android)
- [ ] **9.9** Performance:
  - Lighthouse PWA audit (target ≥ 90)
  - Calendar rendering with 200+ tasks/month
  - Search on 500+ tasks
  - IndexedDB timing on 1000+ occurrences
- [ ] **9.10** Accessibility: contrast, touch targets (min 44×44px), reduced motion
- [ ] **9.11** Security/Privacy: no external data, safe import, no unsafe HTML rendering
- [ ] **9.12** Bug classification (Critical / High / Medium / Low)
- [ ] **9.13** Fix all Critical and High bugs before V2

---

## Phase 10 — V2 Stable Release
> Goal: Freeze, verify, deploy 🎉

- [ ] **10.1** Feature freeze
- [ ] **10.2** Final regression test (all 20 Definition of Done checkpoints)
- [ ] **10.3** Production Vercel deployment
- [ ] **10.4** Real Android device install + notification test
- [ ] **10.5** Final Lighthouse PWA audit (≥ 90)
- [ ] **10.6** `docs/notification-capabilities.md` up to date
- [ ] **10.7** README: setup, deployment, offline usage
- [ ] **10.8** `Files.md` final codebase map
- [ ] **10.9** Stable release tag `v2.0.0`

---

## 📌 Definition of Done

The project is complete when a user can:

1. Open the website and install it as a PWA
2. Use it without internet after install
3. Create a task using a BS date
4. Set time + reminder + recurrence
5. Receive a notification at the right time
6. Complete / Snooze / Skip from notification (where platform supports it)
7. Swipe to complete from within the app
8. View it on the BS calendar
9. See occurrence history for recurring tasks
10. Undo an accidental skip
11. Customize behavior through Settings
12. Export a versioned JSON backup
13. Import/restore a backup safely
14. Close and reopen without losing any data
15. Use Focus Mode to silence interruptions
16. Create a task from a template
17. Pin critical tasks above others
18. Use PWA home screen shortcuts
19. See meaningful statistics
20. Trust that recurring tasks and dates work correctly

---

## 🚀 Capacitor Native Android Migration
- [ ] **C.1** Create `/home/jagdish/Desktop/Sandbox/Zara/To_Do/Capacitor` directory and copy project files
- [ ] **C.2** Initialize Capacitor config (`capacitor.config.ts` for Android)
- [ ] **C.3** Migrate notification scheduler to `@capacitor/local-notifications` with native alarms, channels & actions
- [ ] **C.4** Integrate live countdown timer (`TaskCountdown.tsx`) beside tasks in `TodayPage.tsx`
- [ ] **C.5** Add Android native platform (`npx cap add android`) & test build
- [ ] **C.6** Configure Git repository in `Capacitor/` and stage clean project for GitHub push

---

## 🚦 Current Status

```
Capacitor Migration & Android Notifications 🔄 In Progress
Today Tab Task Countdown Timer              🔄 In Progress
Phase 1  — Foundation                       ✅ Completed
Phase 2  — Core Task System                 ✅ Completed
Phase 3  — Views                            ✅ Completed
Phase 4  — Recurrence Engine                ✅ Completed (8/8 unit tests passing)
Phase 5  — Native Mobile Setup (Capacitor)   🔄 Transitioning from PWA
Phase 6  — Native Notifications             🔄 Transitioning to Capacitor LocalNotifications
Phase 7  — Advanced Features                🔄 In Progress
Phase 8  — Settings                         🔄 In Progress
Phase 9  — Testing & Hardening              ⬜ Pending
Phase 10 — V2 Stable Release                ⬜ Pending
```
