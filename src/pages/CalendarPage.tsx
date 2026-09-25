import React, { useState } from 'react'
import { todayBS, bsMonthDays, bsMonthName, bsMonthOffset, adToBS } from '../utils/bsUtils'
import { isSameDay, formatTime } from '../utils/dateUtils'
import { useTaskStore } from '../store/taskStore'
import { useUIStore } from '../store/uiStore'
import { haptic } from '../utils/haptics'
import type { TaskSeries } from '../types'

export const CalendarPage: React.FC = () => {
  const [currentBS, setCurrentBS] = useState(() => todayBS())
  const [selectedDayDate, setSelectedDayDate] = useState<Date>(() => new Date())
  const { series, occurrences } = useTaskStore()
  const { openSheet } = useUIStore()

  const seriesMap = new Map<string, TaskSeries>(series.map((s) => [s.id, s]))

  const days = bsMonthDays(currentBS.year, currentBS.month)
  const firstDayWeekday = days.length > 0 ? days[0].getDay() : 0 // 0=Sun
  const today = new Date()
  const handlePrevMonth = () => {
    haptic.light()
    setCurrentBS((prev) => {
      const next = bsMonthOffset(prev.year, prev.month, -1)
      return { ...next, day: 1 }
    })
  }

  const handleNextMonth = () => {
    haptic.light()
    setCurrentBS((prev) => {
      const next = bsMonthOffset(prev.year, prev.month, 1)
      return { ...next, day: 1 }
    })
  }

  const handleToday = () => {
    haptic.medium()
    setCurrentBS(todayBS())
    setSelectedDayDate(new Date())
  }

  // Selected day occurrences
  const selectedOccurrences = occurrences.filter((occ) => {
    return isSameDay(new Date(occ.scheduledAt), selectedDayDate)
  })

  const weekdaysShort = ['S', 'M', 'T', 'W', 'T', 'F', 'S']

  return (
    <div className="p-4 space-y-5 pb-24 select-none">
      {/* Calendar Header */}
      <div className="flex items-center justify-between">
        <div>
          <h2 className="text-lg font-bold text-neutral-100 flex items-center gap-2">
            <span>{currentBS.year}</span>
            <span className="text-indigo-400">{bsMonthName(currentBS.month, 'ne')}</span>
          </h2>
          <p className="text-xs text-neutral-400">
            {bsMonthName(currentBS.month, 'en')} {currentBS.year} BS
          </p>
        </div>

        <div className="flex items-center gap-1.5">
          <button
            onClick={handleToday}
            className="text-xs font-semibold px-2.5 py-1 rounded-lg bg-neutral-800 hover:bg-neutral-700 text-neutral-200 active:scale-95 transition-all"
          >
            Today
          </button>
          <button
            onClick={handlePrevMonth}
            className="p-1.5 rounded-lg bg-neutral-800 hover:bg-neutral-700 text-neutral-300 active:scale-95 transition-all"
            aria-label="Previous month"
          >
            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 19l-7-7 7-7" />
            </svg>
          </button>
          <button
            onClick={handleNextMonth}
            className="p-1.5 rounded-lg bg-neutral-800 hover:bg-neutral-700 text-neutral-300 active:scale-95 transition-all"
            aria-label="Next month"
          >
            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 5l7 7-7 7" />
            </svg>
          </button>
        </div>
      </div>

      {/* Weekday headers */}
      <div className="grid grid-cols-7 gap-1 text-center">
        {weekdaysShort.map((w, idx) => (
          <div key={idx} className="text-xs font-semibold text-neutral-500 py-1">
            {w}
          </div>
        ))}
      </div>

      {/* Days grid */}
      <div className="grid grid-cols-7 gap-1 text-center">
        {/* Empty cells before month start */}
        {Array.from({ length: firstDayWeekday }).map((_, idx) => (
          <div key={`empty-${idx}`} className="h-10 rounded-xl" />
        ))}

        {/* Days */}
        {days.map((date) => {
          const bs = adToBS(date)
          const isCurrentToday = isSameDay(date, today)
          const isSelected = isSameDay(date, selectedDayDate)

          // Count occurrences for this day
          const dayOccurrences = occurrences.filter((occ) => isSameDay(new Date(occ.scheduledAt), date))
          const hasIncomplete = dayOccurrences.some((o) => o.status !== 'completed' && o.status !== 'skipped')
          const hasCompleted = dayOccurrences.some((o) => o.status === 'completed')

          return (
            <button
              key={date.toISOString()}
              onClick={() => {
                haptic.light()
                setSelectedDayDate(date)
              }}
              className={`relative h-11 flex flex-col items-center justify-center rounded-xl transition-all active:scale-90 ${
                isSelected
                  ? 'bg-indigo-600 text-white font-bold shadow-md shadow-indigo-600/30'
                  : isCurrentToday
                  ? 'bg-neutral-800 text-indigo-400 font-semibold border border-indigo-500/30'
                  : 'text-neutral-200 hover:bg-neutral-800/60'
              }`}
            >
              <span className="text-xs">{bs.day}</span>
              {/* Dots */}
              <div className="flex gap-0.5 mt-0.5">
                {hasIncomplete && (
                  <span className={`w-1 h-1 rounded-full ${isSelected ? 'bg-white' : 'bg-indigo-400'}`} />
                )}
                {hasCompleted && !hasIncomplete && (
                  <span className={`w-1 h-1 rounded-full ${isSelected ? 'bg-white' : 'bg-emerald-400'}`} />
                )}
              </div>
            </button>
          )
        })}
      </div>

      {/* Selected Day Agenda */}
      <div className="pt-4 border-t border-neutral-800/80 space-y-3">
        <div className="flex items-center justify-between">
          <div>
            <h3 className="text-sm font-bold text-neutral-100">
              {adToBS(selectedDayDate).day} {bsMonthName(adToBS(selectedDayDate).month, 'ne')}
            </h3>
            <p className="text-xs text-neutral-400">
              {selectedDayDate.toDateString()}
            </p>
          </div>

          <button
            onClick={() => {
              haptic.medium()
              openSheet('create_task', { defaultDate: selectedDayDate.toISOString() })
            }}
            className="text-xs font-semibold px-2.5 py-1.5 rounded-lg bg-indigo-600/20 text-indigo-300 border border-indigo-500/30 hover:bg-indigo-600/30 active:scale-95 transition-all flex items-center gap-1"
          >
            <span>+ Add Task</span>
          </button>
        </div>

        {selectedOccurrences.length === 0 ? (
          <div className="py-8 text-center text-xs text-neutral-500">
            No tasks scheduled for this day
          </div>
        ) : (
          <div className="space-y-2">
            {selectedOccurrences.map((occ) => {
              const s = seriesMap.get(occ.seriesId)
              const timeFormatted = formatTime(new Date(occ.scheduledAt), '12h')
              return (
                <div
                  key={occ.id}
                  onClick={() => {
                    haptic.light()
                    openSheet('task_detail', { occurrenceId: occ.id, seriesId: occ.seriesId })
                  }}
                  className="flex items-center justify-between p-3 rounded-xl bg-neutral-900/60 border border-neutral-800 hover:border-neutral-700 transition-colors"
                >
                  <div className="min-w-0 flex-1">
                    <h4 className={`text-sm font-semibold truncate ${occ.status === 'completed' ? 'line-through text-neutral-400' : 'text-neutral-100'}`}>
                      {s?.title ?? 'Untitled Task'}
                    </h4>
                    <span className="text-xs text-neutral-400">{timeFormatted}</span>
                  </div>
                  <span className={`text-[10px] uppercase font-bold px-2 py-0.5 rounded-full ${
                    occ.status === 'completed' ? 'bg-emerald-500/20 text-emerald-400' : 'bg-neutral-800 text-neutral-300'
                  }`}>
                    {occ.status}
                  </span>
                </div>
              )
            })}
          </div>
        )}
      </div>
    </div>
  )
}
