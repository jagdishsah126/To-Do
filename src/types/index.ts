// ============================================================
// Core TypeScript Types — Personal Todo PWA
// ============================================================

// ------------------------------------------------------------
// Enums
// ------------------------------------------------------------

export type OccurrenceStatus =
  | 'upcoming'
  | 'due'
  | 'in_progress'
  | 'completed'
  | 'snoozed'
  | 'skipped'
  | 'missed'
  | 'cancelled'

export type Priority = 'low' | 'normal' | 'high' | 'urgent'

export type RecurrenceType =
  | 'daily'
  | 'weekdays'
  | 'weekly'
  | 'monthly'
  | 'yearly'
  | 'custom'

export type RecurrenceEndType = 'never' | 'date' | 'count'

export type MonthlyType = 'date' | 'first_weekday' | 'last_weekday'

export type ThemeMode = 'light' | 'dark' | 'system'

export type TimeFormat = '12h' | '24h'

export type DateDisplay = 'bs' | 'bs_ad'

export type MissedTaskBehavior = 'mark_missed' | 'keep_overdue' | 'move_tomorrow' | 'ask'

export type CarryForwardBehavior = 'keep_overdue' | 'move_tomorrow' | 'ask' | 'mark_missed'

// ------------------------------------------------------------
// Recurrence
// ------------------------------------------------------------

export interface RecurrenceRule {
  type: RecurrenceType
  interval: number               // every N days/weeks/months
  daysOfWeek?: number[]          // 0=Sun … 6=Sat (for 'weekly')
  monthlyType?: MonthlyType
  endType: RecurrenceEndType
  endDate?: string               // AD ISO date string
  maxCount?: number
  exceptions: string[]           // AD date strings (YYYY-MM-DD) skipped or overridden
}

// ------------------------------------------------------------
// Reminder
// ------------------------------------------------------------

export interface ReminderConfig {
  enabled: boolean
  minutesBefore: number          // 0 = at task time
}

export interface Subtask {
  id: string
  title: string
  completed: boolean
}

// ------------------------------------------------------------
// TaskSeries — the definition of a task (recurring or one-off)
// ------------------------------------------------------------

export interface TaskSeries {
  id: string
  title: string
  description?: string
  categoryId?: string
  tags: string[]
  priority: Priority
  duration?: number              // minutes
  recurrenceRule?: RecurrenceRule
  reminderConfig: ReminderConfig
  isPinned: boolean
  isTemplate: boolean
  subtasks?: Subtask[]
  createdAt: string              // AD ISO timestamp
  updatedAt: string              // AD ISO timestamp
}

// ------------------------------------------------------------
// TaskOccurrence — one actual scheduled instance of a series
// ------------------------------------------------------------

export interface TaskOccurrence {
  id: string
  seriesId: string               // links to TaskSeries
  scheduledAt: string            // AD ISO timestamp — intended date+time
  status: OccurrenceStatus
  completedAt?: string           // AD ISO
  snoozedUntil?: string          // AD ISO
  skippedAt?: string             // AD ISO
  missedAt?: string              // AD ISO
  isException: boolean           // manually edited occurrence
  exceptionData?: Partial<TaskSeries>  // field overrides for this occurrence only
  notificationId?: string        // for cancelling scheduled notifications
}

// ------------------------------------------------------------
// Category
// ------------------------------------------------------------

export interface Category {
  id: string
  name: string
  color: string                  // hex string e.g. '#3B82F6'
  icon: string                   // emoji or icon name
  createdAt: string
}

// ------------------------------------------------------------
// Tag
// ------------------------------------------------------------

export interface Tag {
  id: string
  name: string
  createdAt: string
}

// ------------------------------------------------------------
// BS Date (Bikram Sambat)
// ------------------------------------------------------------

export interface BSDate {
  year: number
  month: number                  // 1–12
  day: number
}

// ------------------------------------------------------------
// Snooze Option
// ------------------------------------------------------------

export interface SnoozeOption {
  label: string
  minutes?: number               // fixed minutes ahead
  tomorrow?: boolean             // snooze to start of next day
}

// ------------------------------------------------------------
// App Settings
// ------------------------------------------------------------

export interface AppSettings {
  // General
  timeFormat: TimeFormat
  weekStartDay: number           // 0=Sun, 1=Mon
  defaultDuration: number        // minutes
  dateDisplay: DateDisplay

  // Notifications
  notificationsEnabled: boolean
  defaultReminderMinutes: number
  snoozeOptions: SnoozeOption[]
  missedTaskNotifications: boolean
  recurringNotifications: boolean
  quietHoursEnabled: boolean
  quietHoursStart: string        // 'HH:MM'
  quietHoursEnd: string          // 'HH:MM'

  // Tasks
  defaultPriority: Priority
  defaultCategoryId?: string
  missedTaskBehavior: MissedTaskBehavior
  carryForwardBehavior: CarryForwardBehavior

  // Appearance
  theme: ThemeMode
  accentColor: string            // hex
  layoutDensity: 'compact' | 'comfortable'

  // Data
  autoBackupReminderDays: number // 0 = disabled
  storageWarningPercent: number  // 80 = warn at 80% full

  // Focus Mode
  focusModeEnabled: boolean
}

// ------------------------------------------------------------
// Versioned Backup
// ------------------------------------------------------------

export interface VersionedBackup {
  format: 'personal-todo-backup'
  version: number
  exportedAt: string             // AD ISO
  appVersion: string             // semver e.g. '1.0.0'
  data: {
    series: TaskSeries[]
    occurrences: TaskOccurrence[]
    settings: AppSettings
    categories: Category[]
    tags: Tag[]
  }
}

// ------------------------------------------------------------
// Undo Action
// ------------------------------------------------------------

export interface UndoAction {
  id: string
  label: string                  // e.g. "Task skipped"
  expiresAt: number              // Date.now() + 4000
  undo: () => Promise<void>
}

// ------------------------------------------------------------
// Notification Capability
// ------------------------------------------------------------

export type CapabilityState = 'supported' | 'partial' | 'unsupported' | 'unknown'

export interface NotificationCapabilities {
  permission: CapabilityState
  display: CapabilityState
  actions: CapabilityState
  backgroundScheduling: CapabilityState
  lockedScreen: CapabilityState
  afterRestart: CapabilityState
  offline: CapabilityState
}
