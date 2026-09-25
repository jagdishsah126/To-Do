// ============================================================
// Default App Settings
// ============================================================

import type { AppSettings } from '../types'

export const DEFAULT_SETTINGS: AppSettings = {
  timeFormat: '12h',
  weekStartDay: 0,
  defaultDuration: 30,
  dateDisplay: 'bs',

  notificationsEnabled: true,
  defaultReminderMinutes: 10,
  snoozeOptions: [
    { label: '5 minutes', minutes: 5 },
    { label: '10 minutes', minutes: 10 },
    { label: '15 minutes', minutes: 15 },
    { label: '30 minutes', minutes: 30 },
    { label: '1 hour', minutes: 60 },
    { label: 'Tomorrow', tomorrow: true },
  ],
  missedTaskNotifications: true,
  recurringNotifications: true,
  quietHoursEnabled: false,
  quietHoursStart: '22:30',
  quietHoursEnd: '07:00',

  defaultPriority: 'normal',
  defaultCategoryId: undefined,
  missedTaskBehavior: 'mark_missed',
  carryForwardBehavior: 'ask',

  theme: 'system',
  accentColor: '#6366f1',
  layoutDensity: 'comfortable',

  autoBackupReminderDays: 7,
  storageWarningPercent: 80,

  focusModeEnabled: false,
}

export const APP_VERSION = '0.1.0'

export const DB_NAME = 'zara-todo-db'
export const DB_VERSION = 1

export const BACKUP_FORMAT = 'personal-todo-backup' as const
export const BACKUP_VERSION = 1
