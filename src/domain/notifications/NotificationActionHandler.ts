// ============================================================
// Notification Action Handler
// Processes actions performed directly on notifications (Complete / Snooze / Skip / Open)
// ============================================================

import { useTaskStore } from '../../store/taskStore'
import { useUIStore } from '../../store/uiStore'
import {
  onOccurrenceCompletedOrSkipped,
  skipRecurringOccurrence,
} from '../../services/recurrenceService'
import * as taskDb from '../../db/taskDb'

export interface SWActionPayload {
  type: 'COMPLETE_OCCURRENCE' | 'SKIP_OCCURRENCE' | 'SNOOZE_OCCURRENCE' | 'OPEN_OCCURRENCE'
  occurrenceId?: string
  minutes?: number
}

export async function handleNotificationAction(payload: SWActionPayload): Promise<void> {
  const { type, occurrenceId, minutes } = payload
  if (!occurrenceId) return

  const occ = await taskDb.getOccurrenceById(occurrenceId)
  if (!occ) return

  const series = await taskDb.getSeriesById(occ.seriesId)
  const isRecurring = Boolean(series?.recurrenceRule)

  switch (type) {
    case 'COMPLETE_OCCURRENCE': {
      await useTaskStore.getState().completeOccurrence(occurrenceId)
      if (isRecurring) {
        await onOccurrenceCompletedOrSkipped(occ)
        await useTaskStore.getState().loadAll()
      }
      break
    }

    case 'SKIP_OCCURRENCE': {
      if (isRecurring) {
        await skipRecurringOccurrence(occurrenceId)
        await useTaskStore.getState().loadAll()
      } else {
        await useTaskStore.getState().skipOccurrence(occurrenceId)
      }
      break
    }

    case 'SNOOZE_OCCURRENCE': {
      const snoozeDuration = minutes ?? 15
      const until = new Date(Date.now() + snoozeDuration * 60 * 1000).toISOString()
      await useTaskStore.getState().snoozeOccurrence(occurrenceId, until)
      break
    }

    case 'OPEN_OCCURRENCE': {
      useUIStore.getState().openSheet('task_detail', {
        occurrenceId,
        seriesId: occ.seriesId,
      })
      break
    }
  }
}
