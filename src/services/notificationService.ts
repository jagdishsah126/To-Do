// ============================================================
// High-Level Notification Service
// Coordinates scheduling across all occurrences, settings, and lifecycle events
// ============================================================

import type { TaskOccurrence } from '../types'
import * as taskDb from '../db/taskDb'
import * as settingsDb from '../db/settingsDb'
import {
  scheduleNotification,
  cancelNotification,
  clearAllScheduled,
} from '../domain/notifications/NotificationScheduler'
import { useUIStore } from '../store/uiStore'

/**
 * Reschedules all upcoming reminders within the next 24 hours.
 * Called on app launch, data sync, or settings change.
 */
export async function syncUpcomingReminders(): Promise<void> {
  const settings = await settingsDb.getSettings()
  if (!settings.notificationsEnabled) {
    clearAllScheduled()
    return
  }

  const now = new Date()
  const windowEnd = new Date(now.getTime() + 24 * 60 * 60 * 1000) // next 24 hours

  const occurrences = await taskDb.getOccurrencesForDateRange(now, windowEnd)
  const allSeries = await taskDb.getAllSeries()
  const seriesMap = new Map(allSeries.map((s) => [s.id, s]))

  const isFocusModeActive = useUIStore.getState().focusMode.active

  for (const occ of occurrences) {
    const s = seriesMap.get(occ.seriesId)
    if (s && occ.status === 'upcoming') {
      scheduleNotification({
        occurrence: occ,
        series: s,
        settings,
        isFocusModeActive,
      })
    }
  }
}

/**
 * Schedule or update a reminder for a single occurrence.
 */
export async function scheduleOccurrenceReminder(occurrence: TaskOccurrence): Promise<void> {
  const settings = await settingsDb.getSettings()
  const series = await taskDb.getSeriesById(occurrence.seriesId)
  if (!series) return

  const isFocusModeActive = useUIStore.getState().focusMode.active

  scheduleNotification({
    occurrence,
    series,
    settings,
    isFocusModeActive,
  })
}

/**
 * Cancel an occurrence reminder.
 */
export function cancelOccurrenceReminder(occurrenceId: string): void {
  cancelNotification(occurrenceId)
}
