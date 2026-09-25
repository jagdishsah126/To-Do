import React, { useState } from 'react'
import { useTaskStore } from '../../store/taskStore'
import { useUIStore } from '../../store/uiStore'
import { todayBS, bsToAD, bsMonthName } from '../../utils/bsUtils'
import { haptic } from '../../utils/haptics'
import type { Priority, RecurrenceType, RecurrenceRule } from '../../types'

export const CreateTaskSheet: React.FC = () => {
  const { createSeries, createOccurrence } = useTaskStore()
  const { closeSheet, bottomSheetData } = useUIStore()

  const defaultDateStr = bottomSheetData.defaultDate as string | undefined
  const initialBS = defaultDateStr ? todayBS() : todayBS()

  const [title, setTitle] = useState('')
  const [description, setDescription] = useState('')
  const [priority, setPriority] = useState<Priority>('normal')
  const [isPinned, setIsPinned] = useState(false)

  // Recurrence state
  const [repeatType, setRepeatType] = useState<'none' | RecurrenceType>('none')
  const [selectedDays, setSelectedDays] = useState<number[]>([1, 3, 5]) // Mon, Wed, Fri by default
  
  // BS Date state
  const [bsYear, setBsYear] = useState(initialBS.year)
  const [bsMonth, setBsMonth] = useState(initialBS.month)
  const [bsDay, setBsDay] = useState(initialBS.day)

  // Time state (HH:MM)
  const now = new Date()
  const defaultHour = String((now.getHours() + 1) % 24).padStart(2, '0')
  const [time, setTime] = useState(`${defaultHour}:00`)

  const [showAdvanced, setShowAdvanced] = useState(false)

  const toggleDay = (dayIndex: number) => {
    haptic.light()
    setSelectedDays((prev) =>
      prev.includes(dayIndex) ? prev.filter((d) => d !== dayIndex) : [...prev, dayIndex].sort()
    )
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!title.trim()) return

    haptic.success()

    // Convert BS date + time to internal AD ISO string
    const adBase = bsToAD({ year: bsYear, month: bsMonth, day: bsDay })
    const [hours, minutes] = time.split(':').map(Number)
    adBase.setHours(hours ?? 12, minutes ?? 0, 0, 0)
    const scheduledAt = adBase.toISOString()

    // Build recurrence rule if selected
    let recurrenceRule: RecurrenceRule | undefined = undefined
    if (repeatType !== 'none') {
      recurrenceRule = {
        type: repeatType,
        interval: 1,
        daysOfWeek: repeatType === 'weekly' ? (selectedDays.length > 0 ? selectedDays : [adBase.getDay()]) : undefined,
        endType: 'never',
        exceptions: [],
      }
    }

    // 1. Create series
    const series = await createSeries({
      title: title.trim(),
      description: description.trim() || undefined,
      priority,
      tags: [],
      isPinned,
      isTemplate: false,
      reminderConfig: {
        enabled: true,
        minutesBefore: 10,
      },
      recurrenceRule,
    })

    // 2. Create first occurrence
    await createOccurrence({
      seriesId: series.id,
      scheduledAt,
      status: 'upcoming',
      isException: false,
    })

    closeSheet()
  }

  const weekdays = [
    { label: 'S', day: 0 },
    { label: 'M', day: 1 },
    { label: 'T', day: 2 },
    { label: 'W', day: 3 },
    { label: 'T', day: 4 },
    { label: 'F', day: 5 },
    { label: 'S', day: 6 },
  ]

  return (
    <form onSubmit={handleSubmit} className="space-y-4 pt-1 select-none">
      {/* Title */}
      <div>
        <label className="block text-xs font-semibold text-neutral-400 mb-1">
          Task Title
        </label>
        <input
          type="text"
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          placeholder="e.g. Study Engineering Math"
          autoFocus
          className="w-full bg-neutral-950 border border-neutral-800 rounded-xl px-3.5 py-2.5 text-sm text-neutral-100 placeholder-neutral-500 focus:outline-none focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 transition-all"
        />
      </div>

      {/* BS Date Picker */}
      <div className="space-y-1.5">
        <label className="block text-xs font-semibold text-neutral-400">
          Nepali Date (Bikram Sambat)
        </label>
        <div className="grid grid-cols-3 gap-2">
          {/* Year */}
          <select
            value={bsYear}
            onChange={(e) => setBsYear(Number(e.target.value))}
            className="bg-neutral-950 border border-neutral-800 rounded-xl px-2.5 py-2 text-xs text-neutral-200 focus:outline-none focus:border-indigo-500"
          >
            {[2080, 2081, 2082, 2083, 2084, 2085].map((y) => (
              <option key={y} value={y}>
                {y} BS
              </option>
            ))}
          </select>

          {/* Month */}
          <select
            value={bsMonth}
            onChange={(e) => setBsMonth(Number(e.target.value))}
            className="bg-neutral-950 border border-neutral-800 rounded-xl px-2.5 py-2 text-xs text-neutral-200 focus:outline-none focus:border-indigo-500"
          >
            {Array.from({ length: 12 }, (_, i) => i + 1).map((m) => (
              <option key={m} value={m}>
                {bsMonthName(m, 'ne')} ({m})
              </option>
            ))}
          </select>

          {/* Day */}
          <select
            value={bsDay}
            onChange={(e) => setBsDay(Number(e.target.value))}
            className="bg-neutral-950 border border-neutral-800 rounded-xl px-2.5 py-2 text-xs text-neutral-200 focus:outline-none focus:border-indigo-500"
          >
            {Array.from({ length: 32 }, (_, i) => i + 1).map((d) => (
              <option key={d} value={d}>
                Day {d}
              </option>
            ))}
          </select>
        </div>
      </div>

      {/* Time & Priority */}
      <div className="grid grid-cols-2 gap-3">
        <div>
          <label className="block text-xs font-semibold text-neutral-400 mb-1">
            Time
          </label>
          <input
            type="time"
            value={time}
            onChange={(e) => setTime(e.target.value)}
            className="w-full bg-neutral-950 border border-neutral-800 rounded-xl px-3 py-2 text-xs text-neutral-200 focus:outline-none focus:border-indigo-500"
          />
        </div>

        <div>
          <label className="block text-xs font-semibold text-neutral-400 mb-1">
            Priority
          </label>
          <select
            value={priority}
            onChange={(e) => setPriority(e.target.value as Priority)}
            className="w-full bg-neutral-950 border border-neutral-800 rounded-xl px-3 py-2 text-xs text-neutral-200 focus:outline-none focus:border-indigo-500"
          >
            <option value="low">Low</option>
            <option value="normal">Normal</option>
            <option value="high">High</option>
            <option value="urgent">Urgent</option>
          </select>
        </div>
      </div>

      {/* Recurrence Selector */}
      <div className="space-y-2">
        <label className="block text-xs font-semibold text-neutral-400">
          Repeat / Recurrence
        </label>
        <select
          value={repeatType}
          onChange={(e) => setRepeatType(e.target.value as 'none' | RecurrenceType)}
          className="w-full bg-neutral-950 border border-neutral-800 rounded-xl px-3 py-2 text-xs text-neutral-200 focus:outline-none focus:border-indigo-500"
        >
          <option value="none">Does not repeat</option>
          <option value="daily">Daily</option>
          <option value="weekdays">Every weekday (Mon–Fri)</option>
          <option value="weekly">Weekly (selected days)</option>
          <option value="monthly">Monthly</option>
          <option value="yearly">Yearly</option>
        </select>

        {repeatType === 'weekly' && (
          <div className="flex gap-1 pt-1 justify-between">
            {weekdays.map((w) => {
              const isSelected = selectedDays.includes(w.day)
              return (
                <button
                  type="button"
                  key={w.day}
                  onClick={() => toggleDay(w.day)}
                  className={`w-9 h-9 rounded-xl text-xs font-semibold transition-all active:scale-95 ${
                    isSelected
                      ? 'bg-indigo-600 text-white shadow-sm shadow-indigo-600/30'
                      : 'bg-neutral-950 text-neutral-400 border border-neutral-800 hover:text-neutral-200'
                  }`}
                >
                  {w.label}
                </button>
              )
            })}
          </div>
        )}
      </div>

      {/* Expandable details */}
      {!showAdvanced ? (
        <button
          type="button"
          onClick={() => setShowAdvanced(true)}
          className="text-xs text-indigo-400 hover:text-indigo-300 font-medium py-1"
        >
          + Add description & options
        </button>
      ) : (
        <div className="space-y-3 pt-1 border-t border-neutral-800 animate-in fade-in">
          <div>
            <label className="block text-xs font-semibold text-neutral-400 mb-1">
              Description / Notes
            </label>
            <textarea
              rows={2}
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="Additional details..."
              className="w-full bg-neutral-950 border border-neutral-800 rounded-xl px-3 py-2 text-xs text-neutral-100 placeholder-neutral-500 focus:outline-none focus:border-indigo-500"
            />
          </div>

          <div className="flex items-center gap-2">
            <input
              type="checkbox"
              id="isPinned"
              checked={isPinned}
              onChange={(e) => setIsPinned(e.target.checked)}
              className="rounded bg-neutral-950 border-neutral-700 text-indigo-600 focus:ring-0"
            />
            <label htmlFor="isPinned" className="text-xs text-neutral-300 font-medium">
              📌 Pin this task to top of Today view
            </label>
          </div>
        </div>
      )}

      {/* Submit Button */}
      <div className="pt-2">
        <button
          type="submit"
          disabled={!title.trim()}
          className="w-full py-3 rounded-2xl bg-indigo-600 disabled:opacity-40 hover:bg-indigo-500 text-white font-semibold text-sm shadow-lg shadow-indigo-600/30 active:scale-98 transition-all"
        >
          Create Task
        </button>
      </div>
    </form>
  )
}
