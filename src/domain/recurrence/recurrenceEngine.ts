// ============================================================
// Recurrence Engine — Pure deterministic occurrence calculation
//
// Rules:
// 1. NEVER generate infinite future occurrences into DB.
// 2. Compute on-demand for windows (today, upcoming 30d, calendar month).
// 3. Keep base time (hours/minutes/seconds) from baseDate.
// ============================================================

import type { RecurrenceRule, TaskSeries, TaskOccurrence } from '../../types'
import { toDateString, generateId } from '../../utils/dateUtils'

const MAX_ITERATIONS = 500 // Safety cap against infinite loops

/**
 * Checks if a specific date (YYYY-MM-DD) is registered as an exception.
 */
export function isDateException(rule: RecurrenceRule, date: Date): boolean {
  const dateStr = toDateString(date)
  return rule.exceptions?.includes(dateStr) ?? false
}

/**
 * Given a baseDate (the original series scheduled timestamp)
 * and an afterDate, calculate the next occurrence strictly after afterDate.
 */
export function generateNextOccurrence(
  rule: RecurrenceRule,
  baseDate: Date,
  afterDate: Date,
  occurrenceIndex = 0
): { date: Date; index: number } | null {
  const targetTime = {
    hours: baseDate.getHours(),
    minutes: baseDate.getMinutes(),
    seconds: baseDate.getSeconds(),
  }

  let current = new Date(baseDate)
  let count = occurrenceIndex
  let iterations = 0

  while (iterations < MAX_ITERATIONS) {
    iterations++

    // Advance current date based on recurrence type
    current = advanceDate(rule, current)
    current.setHours(targetTime.hours, targetTime.minutes, targetTime.seconds, 0)
    count++

    // Check end conditions
    if (rule.endType === 'count' && rule.maxCount && count >= rule.maxCount) {
      return null
    }

    if (rule.endType === 'date' && rule.endDate) {
      const end = new Date(rule.endDate)
      if (current > end) {
        return null
      }
    }

    // Check if date is strictly after afterDate
    if (current > afterDate) {
      // Check exception
      if (isDateException(rule, current)) {
        continue // Skip this exception date and find the next one
      }
      return { date: current, index: count }
    }
  }

  return null
}

/**
 * Generate all occurrence dates for a series within a date range [rangeStart, rangeEnd].
 */
export function generateOccurrencesInRange(
  rule: RecurrenceRule,
  baseDate: Date,
  rangeStart: Date,
  rangeEnd: Date
): Date[] {
  const targetTime = {
    hours: baseDate.getHours(),
    minutes: baseDate.getMinutes(),
    seconds: baseDate.getSeconds(),
  }

  const results: Date[] = []
  let current = new Date(baseDate)
  current.setHours(targetTime.hours, targetTime.minutes, targetTime.seconds, 0)

  let count = 0
  let iterations = 0

  // If baseDate itself is within range, check it
  if (current >= rangeStart && current <= rangeEnd && !isDateException(rule, current)) {
    results.push(new Date(current))
    count++
  }

  while (iterations < MAX_ITERATIONS) {
    iterations++
    current = advanceDate(rule, current)
    current.setHours(targetTime.hours, targetTime.minutes, targetTime.seconds, 0)
    count++

    if (rule.endType === 'date' && rule.endDate) {
      const end = new Date(rule.endDate)
      if (current > end) break
    }

    // Past range end — stop generating
    if (current > rangeEnd) {
      break
    }

    // Inside range
    if (current >= rangeStart) {
      if (!isDateException(rule, current)) {
        results.push(new Date(current))
      }
    }

    // Check count end condition after evaluating candidate
    if (rule.endType === 'count' && rule.maxCount && count >= rule.maxCount) {
      break
    }
  }

  return results
}

/**
 * Given a series and the last acted-upon occurrence, generate the next TaskOccurrence.
 */
export function buildNextOccurrence(
  series: TaskSeries,
  currentOccurrence: TaskOccurrence
): TaskOccurrence | null {
  if (!series.recurrenceRule) return null

  const baseDate = new Date(series.createdAt || currentOccurrence.scheduledAt)
  const afterDate = new Date(currentOccurrence.scheduledAt)

  const next = generateNextOccurrence(series.recurrenceRule, baseDate, afterDate)
  if (!next) return null

  return {
    id: generateId(),
    seriesId: series.id,
    scheduledAt: next.date.toISOString(),
    status: 'upcoming',
    isException: false,
  }
}

// ------------------------------------------------------------
// Date advancement logic per rule type
// ------------------------------------------------------------

function advanceDate(rule: RecurrenceRule, fromDate: Date): Date {
  const next = new Date(fromDate)
  const interval = Math.max(1, rule.interval || 1)

  switch (rule.type) {
    case 'daily':
    case 'custom': {
      next.setDate(next.getDate() + interval)
      return next
    }

    case 'weekdays': {
      do {
        next.setDate(next.getDate() + 1)
      } while (next.getDay() === 0 || next.getDay() === 6) // Skip Sunday (0) & Saturday (6)
      return next
    }

    case 'weekly': {
      const daysOfWeek = rule.daysOfWeek && rule.daysOfWeek.length > 0 ? rule.daysOfWeek : [next.getDay()]
      // Find the next day of the week in the list
      let found = false
      let daysChecked = 0
      while (!found && daysChecked < 14) {
        next.setDate(next.getDate() + 1)
        daysChecked++
        if (daysOfWeek.includes(next.getDay())) {
          found = true
        }
      }
      return next
    }

    case 'monthly': {
      if (rule.monthlyType === 'first_weekday') {
        // Move to first Monday of next month
        next.setMonth(next.getMonth() + interval, 1)
        while (next.getDay() !== 1) { // 1 = Monday
          next.setDate(next.getDate() + 1)
        }
        return next
      } else if (rule.monthlyType === 'last_weekday') {
        // Move to last Friday of next month
        next.setMonth(next.getMonth() + interval + 1, 0) // Last day of month
        while (next.getDay() !== 5) { // 5 = Friday
          next.setDate(next.getDate() - 1)
        }
        return next
      } else {
        // Same date of month
        const originalDay = fromDate.getDate()
        next.setMonth(next.getMonth() + interval)
        // Handle shorter months (e.g. Feb 30 -> Feb 28)
        if (next.getDate() !== originalDay) {
          next.setDate(0) // Last day of previous month
        }
        return next
      }
    }

    case 'yearly': {
      next.setFullYear(next.getFullYear() + interval)
      return next
    }

    default: {
      next.setDate(next.getDate() + 1)
      return next
    }
  }
}
