// ============================================================
// Notification Scheduler
// Native Capacitor LocalNotifications with Web Fallback
// ============================================================

import { Capacitor } from '@capacitor/core'
import { LocalNotifications } from '@capacitor/local-notifications'
import type { TaskOccurrence, TaskSeries, AppSettings } from '../../types'
import { isQuietHours } from '../../utils/dateUtils'
import { formatBS, adToBS } from '../../utils/bsUtils'
import { formatTime } from '../../utils/dateUtils'
import { sendSWMessage } from './ServiceWorkerBridge'
import { isGranted } from './PermissionManager'
import { handleNotificationAction } from './NotificationActionHandler'

const activeTimers = new Map<string, number>()
let isInitialized = false

/**
 * Hash a string to a positive 32-bit signed integer for Capacitor notifications.
 */
export function stringToNotificationId(str: string): number {
  let hash = 0
  for (let i = 0; i < str.length; i++) {
    hash = (hash << 5) - hash + str.charCodeAt(i)
    hash |= 0
  }
  return Math.abs(hash)
}

/**
 * Initialize native notification channels, action types and listeners.
 */
export async function initNotificationEngine(): Promise<void> {
  if (isInitialized) return
  isInitialized = true

  if (Capacitor.isNativePlatform()) {
    try {
      // 1. Create Android Notification Channel
      await LocalNotifications.createChannel({
        id: 'zara_tasks',
        name: 'Task Reminders',
        description: 'Scheduled reminders for Zara To-Do tasks',
        importance: 5, // High importance (heads-up banner + sound)
        visibility: 1, // Public (lockscreen)
        vibration: true,
      })

      // 2. Register Actions (Complete, Snooze, Skip)
      await LocalNotifications.registerActionTypes({
        types: [
          {
            id: 'TASK_ACTIONS',
            actions: [
              { id: 'complete', title: '✅ Complete' },
              { id: 'snooze', title: '💤 Snooze 15m' },
              { id: 'skip', title: '⏭ Skip' },
            ],
          },
        ],
      })

      // 3. Listen for Action Performed (Foreground, Background, or Cold Start)
      await LocalNotifications.addListener('localNotificationActionPerformed', async (notificationAction) => {
        const occurrenceId = notificationAction.notification.extra?.occurrenceId
        const actionId = notificationAction.actionId

        if (!occurrenceId) return

        if (actionId === 'complete') {
          await handleNotificationAction({ type: 'COMPLETE_OCCURRENCE', occurrenceId })
        } else if (actionId === 'snooze') {
          await handleNotificationAction({ type: 'SNOOZE_OCCURRENCE', occurrenceId, minutes: 15 })
        } else if (actionId === 'skip') {
          await handleNotificationAction({ type: 'SKIP_OCCURRENCE', occurrenceId })
        } else {
          // Default tap on notification
          await handleNotificationAction({ type: 'OPEN_OCCURRENCE', occurrenceId })
        }
      })

      console.log('[NotificationEngine] Capacitor LocalNotifications initialized successfully')
    } catch (err) {
      console.warn('[NotificationEngine] Failed to initialize native local notifications:', err)
    }
  }
}

export interface ScheduleOptions {
  occurrence: TaskOccurrence
  series: TaskSeries
  settings: AppSettings
  isFocusModeActive: boolean
}

/**
 * Schedules a notification for a task occurrence.
 */
export async function scheduleNotification(opts: ScheduleOptions): Promise<void> {
  const { occurrence, series, settings, isFocusModeActive } = opts

  if (!settings.notificationsEnabled || !isGranted()) return
  if (!series.reminderConfig.enabled) return
  if (occurrence.status === 'completed' || occurrence.status === 'skipped' || occurrence.status === 'cancelled') return

  // Cancel any existing reminder
  await cancelNotification(occurrence.id)

  const scheduledDate = new Date(occurrence.scheduledAt)
  const reminderMinutes = series.reminderConfig.minutesBefore ?? settings.defaultReminderMinutes ?? 10
  const reminderTimestamp = scheduledDate.getTime() - reminderMinutes * 60 * 1000

  const now = Date.now()
  const delayMs = reminderTimestamp - now

  // If already more than 15 minutes overdue, do not trigger old alarm
  if (delayMs < -15 * 60 * 1000) {
    return
  }

  // Check Focus Mode suppression
  if (isFocusModeActive && series.priority !== 'urgent' && !series.isPinned) {
    console.log(`[Scheduler] Notification suppressed by Focus Mode: "${series.title}"`)
    return
  }

  // Check Quiet Hours suppression
  if (settings.quietHoursEnabled) {
    const isQuiet = isQuietHours(new Date(reminderTimestamp > now ? reminderTimestamp : now), settings.quietHoursStart, settings.quietHoursEnd)
    if (isQuiet && series.priority !== 'urgent') {
      console.log(`[Scheduler] Notification suppressed by Quiet Hours: "${series.title}"`)
      return
    }
  }

  const bsDate = adToBS(scheduledDate)
  const timeStr = formatTime(scheduledDate, settings.timeFormat)
  const body = `${formatBS(bsDate)} at ${timeStr}`
  const notificationId = stringToNotificationId(occurrence.id)

  // 1. Native Capacitor Android Path (Runs even when app is killed or locked!)
  if (Capacitor.isNativePlatform()) {
    try {
      const scheduleAt = delayMs > 0 ? new Date(reminderTimestamp) : new Date(now + 500)
      await LocalNotifications.schedule({
        notifications: [
          {
            id: notificationId,
            title: series.title,
            body,
            schedule: {
              at: scheduleAt,
              allowWhileIdle: true, // Uses Android AlarmManager.setExactAndAllowWhileIdle!
            },
            channelId: 'zara_tasks',
            actionTypeId: 'TASK_ACTIONS',
            extra: {
              occurrenceId: occurrence.id,
            },
          },
        ],
      })
      console.log(`[Scheduler] Native notification scheduled for "${series.title}" at ${scheduleAt.toISOString()}`)
      return
    } catch (err) {
      console.warn('[Scheduler] Capacitor schedule failed, falling back to web timers:', err)
    }
  }

  // 2. Web Fallback (For browser testing / PWA)
  const fireWeb = () => {
    const isPageVisible = typeof document !== 'undefined' && document.visibilityState === 'visible'

    if (isPageVisible && typeof Notification !== 'undefined') {
      try {
        const n = new Notification(series.title, {
          body,
          icon: '/icons/icon-192.png',
          badge: '/icons/badge-72.png',
          tag: `task-${occurrence.id}`,
          data: { occurrenceId: occurrence.id },
          silent: false,
        })
        n.onclick = () => {
          window.focus()
          n.close()
        }
      } catch {
        sendSWMessage({
          type: 'SHOW_NOTIFICATION',
          title: series.title,
          body,
          occurrenceId: occurrence.id,
          tag: `task-${occurrence.id}`,
        })
      }
    } else {
      sendSWMessage({
        type: 'SHOW_NOTIFICATION',
        title: series.title,
        body,
        occurrenceId: occurrence.id,
        tag: `task-${occurrence.id}`,
      })
    }
  }

  if (delayMs <= 0) {
    fireWeb()
  } else {
    const timerId = window.setTimeout(() => {
      fireWeb()
      activeTimers.delete(occurrence.id)
    }, delayMs)
    activeTimers.set(occurrence.id, timerId)
  }
}

/**
 * Cancel a scheduled reminder.
 */
export async function cancelNotification(occurrenceId: string): Promise<void> {
  const timerId = activeTimers.get(occurrenceId)
  if (timerId !== undefined) {
    clearTimeout(timerId)
    activeTimers.delete(occurrenceId)
  }

  if (Capacitor.isNativePlatform()) {
    try {
      const id = stringToNotificationId(occurrenceId)
      await LocalNotifications.cancel({
        notifications: [{ id }],
      })
    } catch (err) {
      console.warn('[Scheduler] Native notification cancel failed:', err)
    }
  }

  sendSWMessage({
    type: 'CANCEL_NOTIFICATION',
    tag: `task-${occurrenceId}`,
  })
}

/**
 * Clear all scheduled timers / notifications.
 */
export async function clearAllScheduled(): Promise<void> {
  for (const timerId of activeTimers.values()) {
    clearTimeout(timerId)
  }
  activeTimers.clear()

  if (Capacitor.isNativePlatform()) {
    try {
      const pending = await LocalNotifications.getPending()
      if (pending.notifications.length > 0) {
        await LocalNotifications.cancel({ notifications: pending.notifications })
      }
    } catch (err) {
      console.warn('[Scheduler] Failed to clear pending native notifications:', err)
    }
  }
}
