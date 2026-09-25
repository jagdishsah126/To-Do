// ============================================================
// Recurrence Service
//
// Coordinates recurrence generation, occurrence hydration in DB,
// and series-split editing scopes:
// 1. "This occurrence" (exception override)
// 2. "This and future occurrences" (series split)
// 3. "Entire series" (series update)
// ============================================================

import type { TaskSeries, TaskOccurrence } from '../types'
import * as taskDb from '../db/taskDb'
import {
  generateOccurrencesInRange,
  buildNextOccurrence,
} from '../domain/recurrence/recurrenceEngine'
import { toDateString, isSameDay } from '../utils/dateUtils'

/**
 * Ensures all recurring series have occurrences generated for the given window [rangeStart, rangeEnd].
 * Called when opening Today, Upcoming, or Calendar views.
 */
export async function hydrateOccurrencesForRange(
  rangeStart: Date,
  rangeEnd: Date
): Promise<TaskOccurrence[]> {
  const allSeries = await taskDb.getAllSeries()
  const recurringSeries = allSeries.filter((s) => s.recurrenceRule)
  const existingOccurrences = await taskDb.getOccurrencesForDateRange(rangeStart, rangeEnd)

  const newlyCreated: TaskOccurrence[] = []

  for (const series of recurringSeries) {
    if (!series.recurrenceRule) continue

    const baseDate = new Date(series.createdAt)
    const expectedDates = generateOccurrencesInRange(
      series.recurrenceRule,
      baseDate,
      rangeStart,
      rangeEnd
    )

    const seriesOccurrences = existingOccurrences.filter((o) => o.seriesId === series.id)

    for (const targetDate of expectedDates) {
      // Check if an occurrence already exists on this day for this series
      const alreadyExists = seriesOccurrences.some((o) =>
        isSameDay(new Date(o.scheduledAt), targetDate)
      )

      if (!alreadyExists) {
        const newOcc = await taskDb.createOccurrence({
          seriesId: series.id,
          scheduledAt: targetDate.toISOString(),
          status: 'upcoming',
          isException: false,
        })
        newlyCreated.push(newOcc)
      }
    }
  }

  return newlyCreated
}

/**
 * When an occurrence is completed or skipped, check if the next one needs to be generated.
 */
export async function onOccurrenceCompletedOrSkipped(
  occurrence: TaskOccurrence
): Promise<TaskOccurrence | null> {
  const series = await taskDb.getSeriesById(occurrence.seriesId)
  if (!series || !series.recurrenceRule) return null

  // Check if an upcoming occurrence already exists in the future
  const allOccurrences = await taskDb.getOccurrencesBySeries(series.id)
  const hasFutureUpcoming = allOccurrences.some(
    (o) =>
      o.id !== occurrence.id &&
      new Date(o.scheduledAt) > new Date(occurrence.scheduledAt) &&
      o.status === 'upcoming'
  )

  if (hasFutureUpcoming) return null

  // Generate next occurrence
  const next = buildNextOccurrence(series, occurrence)
  if (!next) return null

  return taskDb.createOccurrence(next)
}

// ------------------------------------------------------------
// Editing Scopes
// ------------------------------------------------------------

/**
 * Scope 1: "This occurrence only"
 * Stores field overrides directly on the occurrence as an exception.
 */
export async function editThisOccurrenceOnly(
  occurrenceId: string,
  overrides: Partial<TaskSeries>
): Promise<TaskOccurrence | undefined> {
  return taskDb.updateOccurrence(occurrenceId, {
    isException: true,
    exceptionData: overrides,
  })
}

/**
 * Scope 2: "This and future occurrences"
 * Splits the series:
 * 1. Sets endDate on the old series to day before splitDate.
 * 2. Creates a new TaskSeries starting from splitDate with the new settings.
 * 3. Migrates any occurrences on/after splitDate to the new series.
 */
export async function editThisAndFutureOccurrences(
  seriesId: string,
  splitDate: Date,
  newSeriesData: Partial<TaskSeries>
): Promise<{ oldSeries: TaskSeries; newSeries: TaskSeries }> {
  const oldSeries = await taskDb.getSeriesById(seriesId)
  if (!oldSeries) throw new Error('Series not found')

  // 1. Terminate old series right before split date
  const dayBefore = new Date(splitDate)
  dayBefore.setDate(dayBefore.getDate() - 1)
  dayBefore.setHours(23, 59, 59, 999)

  const updatedOld = await taskDb.updateSeries(seriesId, {
    recurrenceRule: oldSeries.recurrenceRule
      ? {
          ...oldSeries.recurrenceRule,
          endType: 'date',
          endDate: dayBefore.toISOString(),
        }
      : undefined,
  })

  // 2. Create new series
  const newSeries = await taskDb.createSeries({
    title: newSeriesData.title ?? oldSeries.title,
    description: newSeriesData.description ?? oldSeries.description,
    categoryId: newSeriesData.categoryId ?? oldSeries.categoryId,
    tags: newSeriesData.tags ?? oldSeries.tags,
    priority: newSeriesData.priority ?? oldSeries.priority,
    duration: newSeriesData.duration ?? oldSeries.duration,
    isPinned: newSeriesData.isPinned ?? oldSeries.isPinned,
    isTemplate: false,
    reminderConfig: newSeriesData.reminderConfig ?? oldSeries.reminderConfig,
    recurrenceRule: newSeriesData.recurrenceRule ?? oldSeries.recurrenceRule,
  })

  // 3. Re-link occurrences on or after splitDate to new series
  const occurrences = await taskDb.getOccurrencesBySeries(seriesId)
  for (const occ of occurrences) {
    if (new Date(occ.scheduledAt) >= splitDate) {
      await taskDb.updateOccurrence(occ.id, {
        seriesId: newSeries.id,
      })
    }
  }

  return { oldSeries: updatedOld!, newSeries }
}

/**
 * Scope 3: "Entire series"
 * Directly updates the series definition for all past and future occurrences.
 */
export async function editEntireSeries(
  seriesId: string,
  updates: Partial<TaskSeries>
): Promise<TaskSeries | undefined> {
  return taskDb.updateSeries(seriesId, updates)
}

/**
 * Skip a recurring occurrence:
 * Marks occurrence as skipped and registers date in series exceptions list.
 */
export async function skipRecurringOccurrence(
  occurrenceId: string
): Promise<void> {
  const occ = await taskDb.getOccurrenceById(occurrenceId)
  if (!occ) return

  await taskDb.updateOccurrence(occurrenceId, {
    status: 'skipped',
    skippedAt: new Date().toISOString(),
  })

  const series = await taskDb.getSeriesById(occ.seriesId)
  if (series?.recurrenceRule) {
    const dateStr = toDateString(new Date(occ.scheduledAt))
    const exceptions = new Set(series.recurrenceRule.exceptions || [])
    exceptions.add(dateStr)

    await taskDb.updateSeries(series.id, {
      recurrenceRule: {
        ...series.recurrenceRule,
        exceptions: Array.from(exceptions),
      },
    })
  }

  // Advance to next occurrence
  await onOccurrenceCompletedOrSkipped(occ)
}
