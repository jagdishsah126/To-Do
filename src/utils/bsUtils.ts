// ============================================================
// BS ↔ AD Date Utilities
//
// THIS IS THE ONLY FILE WHERE BS CONVERSION HAPPENS.
// Never import bikram-sambat anywhere else.
// All components use these helpers exclusively.
// ============================================================

import { toBik, toGreg, daysInMonth } from 'bikram-sambat'
import type { BSDate } from '../types'

// ------------------------------------------------------------
// Conversion
// ------------------------------------------------------------

/**
 * Convert an AD Date to a Bikram Sambat date.
 *
 * IMPORTANT: toBik() uses epoch milliseconds internally. If you pass a Date
 * with a time component (e.g. 22:34 NPT), its internal arithmetic can push
 * the result to the *next* BS day. We always strip the time to local midnight
 * before converting to ensure a stable, correct result.
 */
export function adToBS(date: Date): BSDate {
  // Use local date parts to construct a clean local midnight — no UTC shift.
  const localMidnight = new Date(
    date.getFullYear(),
    date.getMonth(),
    date.getDate(),
    0, 0, 0, 0
  )
  const bik = toBik(localMidnight)
  return {
    year: bik.year,
    month: bik.month,
    day: bik.day,
  }
}

/**
 * Convert a Bikram Sambat date to an AD Date (start of that day, local timezone).
 */
export function bsToAD(bs: BSDate): Date {
  const greg = toGreg(bs.year, bs.month, bs.day)
  return new Date(greg.year, greg.month - 1, greg.day, 0, 0, 0, 0)
}

// ------------------------------------------------------------
// Today helpers
// ------------------------------------------------------------

/** Get today as a BSDate */
export function todayBS(): BSDate {
  return adToBS(new Date())
}

/** Get today as an AD Date (midnight local) */
export function todayAD(): Date {
  const now = new Date()
  return new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0, 0)
}

// ------------------------------------------------------------
// Formatting
// ------------------------------------------------------------

const NEPALI_MONTHS_EN = [
  'Baisakh', 'Jestha', 'Ashadh', 'Shrawan',
  'Bhadra', 'Ashwin', 'Kartik', 'Mangsir',
  'Poush', 'Magh', 'Falgun', 'Chaitra',
]

const NEPALI_MONTHS_NE = [
  'बैशाख', 'जेठ', 'असार', 'श्रावण',
  'भाद्र', 'असोज', 'कार्तिक', 'मंसिर',
  'पुष', 'माघ', 'फागुन', 'चैत्र',
]

const WEEKDAYS_EN = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
const WEEKDAYS_EN_SHORT = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']

/**
 * Format a BSDate as a readable string.
 * Default: "2083 असोज 9"
 */
export function formatBS(
  bs: BSDate,
  opts: {
    monthLang?: 'ne' | 'en'
    showWeekday?: boolean
    weekdayDate?: Date
  } = {}
): string {
  const { monthLang = 'ne', showWeekday = false, weekdayDate } = opts
  const months = monthLang === 'ne' ? NEPALI_MONTHS_NE : NEPALI_MONTHS_EN
  const monthName = months[bs.month - 1] ?? ''

  let result = `${bs.year} ${monthName} ${bs.day}`

  if (showWeekday && weekdayDate) {
    result = `${WEEKDAYS_EN[weekdayDate.getDay()]}, ${result}`
  }

  return result
}

/**
 * Format an AD Date's BS equivalent as "YYYY MMM DD"
 */
export function formatDateBS(date: Date, opts?: Parameters<typeof formatBS>[1]): string {
  return formatBS(adToBS(date), opts)
}

/**
 * Get the weekday name for a given AD Date.
 */
export function weekdayName(date: Date, short = false): string {
  return short ? WEEKDAYS_EN_SHORT[date.getDay()] : WEEKDAYS_EN[date.getDay()]
}

/**
 * Get the BS month name (Nepali by default).
 */
export function bsMonthName(month: number, lang: 'ne' | 'en' = 'ne'): string {
  const months = lang === 'ne' ? NEPALI_MONTHS_NE : NEPALI_MONTHS_EN
  return months[month - 1] ?? ''
}

// ------------------------------------------------------------
// Month boundaries (for calendar views)
// ------------------------------------------------------------

/**
 * Returns all AD Dates that fall within a given BS month.
 * Used to render calendar grids.
 */
export function bsMonthDays(year: number, month: number): Date[] {
  const totalDays = daysInMonth(year, month)
  const days: Date[] = []

  for (let day = 1; day <= totalDays; day++) {
    days.push(bsToAD({ year, month, day }))
  }

  return days
}

/**
 * Returns start and end AD Dates for a given BS month.
 */
export function bsMonthBoundaries(
  year: number,
  month: number
): { start: Date; end: Date } {
  const totalDays = daysInMonth(year, month)
  return {
    start: bsToAD({ year, month, day: 1 }),
    end: bsToAD({ year, month, day: totalDays }),
  }
}

/**
 * Navigate BS month: returns next or previous BS year/month.
 */
export function bsMonthOffset(
  year: number,
  month: number,
  delta: number
): { year: number; month: number } {
  let m = month + delta
  let y = year
  while (m > 12) { m -= 12; y++ }
  while (m < 1)  { m += 12; y-- }
  return { year: y, month: m }
}

// ------------------------------------------------------------
// Comparison helpers
// ------------------------------------------------------------

/** Check if two BSDate objects represent the same day */
export function isSameBSDay(a: BSDate, b: BSDate): boolean {
  return a.year === b.year && a.month === b.month && a.day === b.day
}

/** Check if an AD Date is in the current BS month */
export function isCurrentBSMonth(date: Date): boolean {
  const today = adToBS(new Date())
  const d = adToBS(date)
  return d.year === today.year && d.month === today.month
}
