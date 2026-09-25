// ============================================================
// AD Date Utilities
//
// All AD/Gregorian date helpers live here.
// Timezone policy: always use DEVICE timezone (no UTC forcing).
// ============================================================

// ------------------------------------------------------------
// Day boundaries
// ------------------------------------------------------------

/** Start of a day (midnight, local timezone) */
export function startOfDay(date: Date): Date {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate(), 0, 0, 0, 0)
}

/** End of a day (23:59:59.999, local timezone) */
export function endOfDay(date: Date): Date {
  return new Date(date.getFullYear(), date.getMonth(), date.getDate(), 23, 59, 59, 999)
}

/** Today at midnight (local timezone) */
export function today(): Date {
  return startOfDay(new Date())
}

/** Tomorrow at midnight (local timezone) */
export function tomorrow(): Date {
  const d = today()
  d.setDate(d.getDate() + 1)
  return d
}

// ------------------------------------------------------------
// Comparison helpers
// ------------------------------------------------------------

/** Check if two Dates are the same calendar day (local timezone) */
export function isSameDay(a: Date, b: Date): boolean {
  return (
    a.getFullYear() === b.getFullYear() &&
    a.getMonth() === b.getMonth() &&
    a.getDate() === b.getDate()
  )
}

/** Check if a Date is today */
export function isToday(date: Date): boolean {
  return isSameDay(date, new Date())
}

/** Check if an ISO timestamp string is in the past */
export function isPast(scheduledAt: string): boolean {
  return new Date(scheduledAt) < new Date()
}

/** Check if an ISO timestamp string is overdue (past AND not today) */
export function isOverdue(scheduledAt: string): boolean {
  const d = new Date(scheduledAt)
  return d < startOfDay(new Date())
}

/** Check if a date is in the future (after now) */
export function isFuture(date: Date): boolean {
  return date > new Date()
}

/**
 * Compare two ISO timestamp strings.
 * Returns negative if a < b, 0 if equal, positive if a > b.
 */
export function compareDates(a: string, b: string): number {
  return new Date(a).getTime() - new Date(b).getTime()
}

// ------------------------------------------------------------
// Range helpers
// ------------------------------------------------------------

/** Check if a date falls within [start, end] inclusive */
export function isInRange(date: Date, start: Date, end: Date): boolean {
  return date >= start && date <= end
}

/** Generate an array of Dates for each day in [start, end] */
export function daysInRange(start: Date, end: Date): Date[] {
  const days: Date[] = []
  const current = startOfDay(start)
  const endDay = startOfDay(end)
  while (current <= endDay) {
    days.push(new Date(current))
    current.setDate(current.getDate() + 1)
  }
  return days
}

// ------------------------------------------------------------
// Time helpers
// ------------------------------------------------------------

/**
 * Format a Date as time string.
 * @param format '12h' | '24h'
 */
export function formatTime(date: Date, format: '12h' | '24h' = '12h'): string {
  if (format === '24h') {
    const h = String(date.getHours()).padStart(2, '0')
    const m = String(date.getMinutes()).padStart(2, '0')
    return `${h}:${m}`
  }
  // 12h
  const hours = date.getHours()
  const minutes = date.getMinutes()
  const ampm = hours >= 12 ? 'PM' : 'AM'
  const h = hours % 12 || 12
  const m = String(minutes).padStart(2, '0')
  return `${h}:${m} ${ampm}`
}

/**
 * Parse a 'HH:MM' string into hours and minutes.
 */
export function parseTimeString(time: string): { hours: number; minutes: number } {
  const [h, m] = time.split(':').map(Number)
  return { hours: h ?? 0, minutes: m ?? 0 }
}

/**
 * Check if current time is within quiet hours.
 * Handles overnight quiet periods (e.g. 22:30 → 07:00).
 */
export function isQuietHours(
  now: Date,
  startTime: string,
  endTime: string
): boolean {
  const { hours: sh, minutes: sm } = parseTimeString(startTime)
  const { hours: eh, minutes: em } = parseTimeString(endTime)

  const nowMinutes = now.getHours() * 60 + now.getMinutes()
  const startMinutes = sh * 60 + sm
  const endMinutes = eh * 60 + em

  if (startMinutes <= endMinutes) {
    // Same-day period (e.g. 09:00 → 17:00)
    return nowMinutes >= startMinutes && nowMinutes < endMinutes
  } else {
    // Overnight period (e.g. 22:30 → 07:00)
    return nowMinutes >= startMinutes || nowMinutes < endMinutes
  }
}

// ------------------------------------------------------------
// ID generation
// ------------------------------------------------------------

/** Generate a unique ID */
export function generateId(): string {
  return `${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 9)}`
}

// ------------------------------------------------------------
// ISO helpers
// ------------------------------------------------------------

/** Get current time as ISO string */
export function nowISO(): string {
  return new Date().toISOString()
}

/** Format a Date as YYYY-MM-DD (no time, no timezone) */
export function toDateString(date: Date): string {
  const y = date.getFullYear()
  const m = String(date.getMonth() + 1).padStart(2, '0')
  const d = String(date.getDate()).padStart(2, '0')
  return `${y}-${m}-${d}`
}
