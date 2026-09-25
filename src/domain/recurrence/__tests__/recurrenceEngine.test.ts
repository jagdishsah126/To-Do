import { describe, it, expect } from 'vitest'
import {
  generateNextOccurrence,
  generateOccurrencesInRange,
  isDateException,
  buildNextOccurrence,
} from '../recurrenceEngine'
import type { RecurrenceRule, TaskSeries, TaskOccurrence } from '../../../types'

describe('Recurrence Engine', () => {
  it('correctly advances daily recurrence preserving time', () => {
    const baseDate = new Date('2026-09-25T07:00:00')
    const rule: RecurrenceRule = {
      type: 'daily',
      interval: 1,
      endType: 'never',
      exceptions: [],
    }

    const next = generateNextOccurrence(rule, baseDate, baseDate)
    expect(next).not.toBeNull()
    expect(next!.date.getDate()).toBe(26)
    expect(next!.date.getHours()).toBe(7)
    expect(next!.date.getMinutes()).toBe(0)
  })

  it('correctly skips weekends for weekdays recurrence', () => {
    // 2026-09-25 is Friday (5)
    const friday = new Date('2026-09-25T10:00:00')
    const rule: RecurrenceRule = {
      type: 'weekdays',
      interval: 1,
      endType: 'never',
      exceptions: [],
    }

    const next = generateNextOccurrence(rule, friday, friday)
    expect(next).not.toBeNull()
    // Next day after Friday should be Monday 2026-09-28
    expect(next!.date.getDay()).toBe(1) // Monday
    expect(next!.date.getDate()).toBe(28)
  })

  it('correctly generates MWF (Mon, Wed, Fri) weekly occurrences in range', () => {
    const start = new Date('2026-09-21T09:00:00') // Monday
    const end = new Date('2026-09-27T23:59:59') // Sunday (1 week)
    const rule: RecurrenceRule = {
      type: 'weekly',
      interval: 1,
      daysOfWeek: [1, 3, 5], // Mon, Wed, Fri
      endType: 'never',
      exceptions: [],
    }

    const occurrences = generateOccurrencesInRange(rule, start, start, end)
    expect(occurrences.length).toBe(3) // Mon 21, Wed 23, Fri 25
    expect(occurrences.map((d) => d.getDate())).toEqual([21, 23, 25])
  })

  it('respects maxCount end condition', () => {
    const start = new Date('2026-09-25T12:00:00')
    const end = new Date('2026-10-25T12:00:00')
    const rule: RecurrenceRule = {
      type: 'daily',
      interval: 1,
      endType: 'count',
      maxCount: 3,
      exceptions: [],
    }

    const occurrences = generateOccurrencesInRange(rule, start, start, end)
    expect(occurrences.length).toBe(3)
  })

  it('respects endDate condition', () => {
    const start = new Date('2026-09-25T12:00:00')
    const end = new Date('2026-10-25T12:00:00')
    const rule: RecurrenceRule = {
      type: 'daily',
      interval: 1,
      endType: 'date',
      endDate: '2026-09-28T23:59:59',
      exceptions: [],
    }

    const occurrences = generateOccurrencesInRange(rule, start, start, end)
    expect(occurrences.length).toBe(4) // 25, 26, 27, 28
  })

  it('skips dates marked as exceptions', () => {
    const start = new Date('2026-09-25T12:00:00')
    const end = new Date('2026-09-28T23:59:59')
    const rule: RecurrenceRule = {
      type: 'daily',
      interval: 1,
      endType: 'never',
      exceptions: ['2026-09-26'], // Skip the 26th
    }

    expect(isDateException(rule, new Date('2026-09-26T12:00:00'))).toBe(true)

    const occurrences = generateOccurrencesInRange(rule, start, start, end)
    expect(occurrences.map((d) => d.getDate())).toEqual([25, 27, 28])
  })

  it('correctly advances monthly recurrence on same day', () => {
    const start = new Date('2026-01-15T18:00:00')
    const rule: RecurrenceRule = {
      type: 'monthly',
      interval: 1,
      monthlyType: 'date',
      endType: 'never',
      exceptions: [],
    }

    const next = generateNextOccurrence(rule, start, start)
    expect(next).not.toBeNull()
    expect(next!.date.getMonth()).toBe(1) // February
    expect(next!.date.getDate()).toBe(15)
  })

  it('buildNextOccurrence creates a valid TaskOccurrence from series', () => {
    const series: TaskSeries = {
      id: 'series-123',
      title: 'Daily Workout',
      priority: 'high',
      tags: [],
      isPinned: false,
      isTemplate: false,
      createdAt: '2026-09-25T06:30:00.000Z',
      updatedAt: '2026-09-25T06:30:00.000Z',
      reminderConfig: { enabled: true, minutesBefore: 15 },
      recurrenceRule: {
        type: 'daily',
        interval: 1,
        endType: 'never',
        exceptions: [],
      },
    }

    const currentOcc: TaskOccurrence = {
      id: 'occ-1',
      seriesId: 'series-123',
      scheduledAt: '2026-09-25T06:30:00.000Z',
      status: 'completed',
      isException: false,
    }

    const nextOcc = buildNextOccurrence(series, currentOcc)
    expect(nextOcc).not.toBeNull()
    expect(nextOcc!.seriesId).toBe('series-123')
    expect(nextOcc!.status).toBe('upcoming')
    expect(new Date(nextOcc!.scheduledAt).getDate()).toBe(26)
  })
})
