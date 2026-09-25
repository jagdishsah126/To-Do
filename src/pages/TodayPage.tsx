import React from 'react'
import { useTaskStore } from '../store/taskStore'
import { useUIStore } from '../store/uiStore'
import { isToday, isOverdue, formatTime } from '../utils/dateUtils'
import { formatBS, adToBS } from '../utils/bsUtils'
import { haptic } from '../utils/haptics'
import type { TaskOccurrence, TaskSeries } from '../types'
import {
  onOccurrenceCompletedOrSkipped,
  skipRecurringOccurrence,
} from '../services/recurrenceService'
import { TaskCountdown } from '../components/tasks/TaskCountdown'

export const TodayPage: React.FC = () => {
  const {
    series,
    occurrences,
    completeOccurrence,
    skipOccurrence,
    togglePin,
    toggleSelect,
    isMultiSelect,
    selectedIds,
    clearSelection,
    loadAll,
  } = useTaskStore()
  const { openSheet, pushUndo } = useUIStore()

  // Map series by ID
  const seriesMap = new Map<string, TaskSeries>(series.map((s) => [s.id, s]))

  // Filter occurrences
  const todayOccurrences = occurrences.filter((occ) => {
    const d = new Date(occ.scheduledAt)
    return isToday(d) && occ.status !== 'completed' && occ.status !== 'skipped' && occ.status !== 'cancelled'
  })

  const overdueOccurrences = occurrences.filter((occ) => {
    return isOverdue(occ.scheduledAt) && occ.status !== 'completed' && occ.status !== 'skipped' && occ.status !== 'cancelled'
  })

  const completedToday = occurrences.filter((occ) => {
    if (occ.status !== 'completed') return false
    const d = occ.completedAt ? new Date(occ.completedAt) : new Date(occ.scheduledAt)
    return isToday(d)
  })

  // Group today's into pinned vs regular
  const pinnedToday = todayOccurrences.filter((occ) => {
    const s = seriesMap.get(occ.seriesId)
    return s?.isPinned
  })

  const regularToday = todayOccurrences.filter((occ) => {
    const s = seriesMap.get(occ.seriesId)
    return !s?.isPinned
  })

  const handleComplete = async (occ: TaskOccurrence, s?: TaskSeries) => {
    haptic.success()
    const prevStatus = occ.status
    const prevCompletedAt = occ.completedAt
    await completeOccurrence(occ.id)

    if (s?.recurrenceRule) {
      await onOccurrenceCompletedOrSkipped(occ)
      await loadAll()
    }

    pushUndo({
      label: `Completed "${s?.title ?? 'Task'}"`,
      undo: async () => {
        await useTaskStore.getState().updateOccurrence(occ.id, {
          status: prevStatus,
          completedAt: prevCompletedAt,
        })
      },
    })
  }

  const handleSkip = async (occ: TaskOccurrence, s?: TaskSeries) => {
    haptic.medium()
    const prevStatus = occ.status
    const prevSkippedAt = occ.skippedAt

    if (s?.recurrenceRule) {
      await skipRecurringOccurrence(occ.id)
      await loadAll()
    } else {
      await skipOccurrence(occ.id)
    }

    pushUndo({
      label: `Skipped "${s?.title ?? 'Task'}"`,
      undo: async () => {
        await useTaskStore.getState().updateOccurrence(occ.id, {
          status: prevStatus,
          skippedAt: prevSkippedAt,
        })
      },
    })
  }

  // Bulk Actions
  const handleBulkComplete = async () => {
    haptic.success()
    const ids = Array.from(selectedIds)
    for (const id of ids) {
      await completeOccurrence(id)
    }
    clearSelection()
    await loadAll()
  }

  const handleBulkSkip = async () => {
    haptic.medium()
    const ids = Array.from(selectedIds)
    for (const id of ids) {
      await skipOccurrence(id)
    }
    clearSelection()
    await loadAll()
  }

  const handleBulkDelete = async () => {
    haptic.heavy()
    if (!window.confirm(`Delete ${selectedIds.size} selected tasks?`)) return
    const ids = Array.from(selectedIds)
    for (const id of ids) {
      const occ = occurrences.find((o) => o.id === id)
      if (occ) {
        await useTaskStore.getState().deleteSeries(occ.seriesId)
      }
    }
    clearSelection()
    await loadAll()
  }

  const renderCard = (occ: TaskOccurrence, isOverdueItem = false) => {
    const s = seriesMap.get(occ.seriesId)
    const isSelected = selectedIds.has(occ.id)
    const dateObj = new Date(occ.scheduledAt)
    const bsDate = adToBS(dateObj)
    const timeFormatted = formatTime(dateObj, '12h')
    const subtasks = s?.subtasks ?? []
    const completedSubtasksCount = subtasks.filter((st) => st.completed).length

    return (
      <div
        key={occ.id}
        onClick={() => {
          if (isMultiSelect) {
            haptic.light()
            toggleSelect(occ.id)
          } else {
            haptic.light()
            openSheet('task_detail', { occurrenceId: occ.id, seriesId: occ.seriesId })
          }
        }}
        onContextMenu={(e) => {
          e.preventDefault()
          haptic.heavy()
          toggleSelect(occ.id)
        }}
        className={`group relative flex items-start gap-3 p-3.5 rounded-2xl border transition-all select-none active:scale-[0.99] ${
          isSelected
            ? 'bg-indigo-950/40 border-indigo-500/70'
            : isOverdueItem
            ? 'bg-rose-950/20 border-rose-900/40'
            : 'bg-neutral-900/70 border-neutral-800/80 hover:border-neutral-700/80'
        }`}
      >
        {/* Complete Checkbox */}
        <button
          onClick={(e) => {
            e.stopPropagation()
            handleComplete(occ, s)
          }}
          className={`mt-0.5 w-6 h-6 rounded-full border-2 flex items-center justify-center transition-all ${
            occ.status === 'completed'
              ? 'bg-emerald-500 border-emerald-500 text-white'
              : 'border-neutral-600 hover:border-emerald-400 active:scale-90'
          }`}
          aria-label="Complete task"
        >
          {occ.status === 'completed' && (
            <svg className="w-3.5 h-3.5" viewBox="0 0 20 20" fill="currentColor">
              <path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd" />
            </svg>
          )}
        </button>

        {/* Content */}
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-1.5 flex-wrap">
            <h3 className={`text-sm font-semibold truncate ${occ.status === 'completed' ? 'line-through text-neutral-400' : 'text-neutral-100'}`}>
              {s?.title ?? 'Untitled Task'}
            </h3>
            {s?.isPinned && (
              <span className="text-[10px] bg-amber-500/20 text-amber-300 border border-amber-500/30 px-1.5 py-0.2 rounded-full">
                📌 Pinned
              </span>
            )}
            {s?.recurrenceRule && (
              <span className="text-[10px] bg-indigo-500/20 text-indigo-300 border border-indigo-500/30 px-1.5 py-0.2 rounded-full">
                🔁 Recurring
              </span>
            )}
            {subtasks.length > 0 && (
              <span className="text-[10px] bg-neutral-800 text-neutral-300 border border-neutral-700/60 px-1.5 py-0.2 rounded-full">
                ☑ {completedSubtasksCount}/{subtasks.length}
              </span>
            )}
          </div>

          {s?.description && (
            <p className="text-xs text-neutral-400 line-clamp-1 mt-0.5">
              {s.description}
            </p>
          )}

          <div className="flex items-center gap-2 mt-2 text-[11px] text-neutral-400 flex-wrap">
            <span className={isOverdueItem ? 'text-rose-400 font-medium' : 'text-neutral-300'}>
              {timeFormatted}
            </span>
            <span>•</span>
            <span>{formatBS(bsDate)}</span>
            {occ.status !== 'completed' && occ.status !== 'skipped' && (
              <>
                <span>•</span>
                <TaskCountdown scheduledAt={occ.scheduledAt} />
              </>
            )}
          </div>
        </div>

        {/* Quick action buttons */}
        <div className="flex items-center gap-1">
          <button
            onClick={(e) => {
              e.stopPropagation()
              handleSkip(occ, s)
            }}
            className="p-1.5 rounded-lg text-neutral-400 hover:text-amber-400 hover:bg-neutral-800/80 active:scale-95 transition-colors"
            title="Skip occurrence"
          >
            <svg className="w-4 h-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 5l7 7-7 7M5 5l7 7-7 7" />
            </svg>
          </button>

          <button
            onClick={(e) => {
              e.stopPropagation()
              if (s) {
                haptic.light()
                togglePin(s.id)
              }
            }}
            className={`p-1.5 rounded-lg transition-colors ${
              s?.isPinned ? 'text-amber-400' : 'text-neutral-400 hover:text-neutral-200'
            }`}
            title="Pin task"
          >
            <svg className="w-4 h-4" fill={s?.isPinned ? 'currentColor' : 'none'} viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 5a2 2 0 012-2h10a2 2 0 012 2v16l-7-3.5L5 21V5z" />
            </svg>
          </button>
        </div>
      </div>
    )
  }

  const isEmpty = overdueOccurrences.length === 0 && todayOccurrences.length === 0 && completedToday.length === 0

  return (
    <div className="p-4 space-y-6 pb-24 relative">
      {isEmpty && (
        <div className="flex flex-col items-center justify-center py-20 text-center select-none">
          <div className="w-16 h-16 rounded-full bg-neutral-900 border border-neutral-800 flex items-center justify-center text-indigo-400 mb-4 shadow-inner">
            <svg className="w-8 h-8" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.8} d="M5 13l4 4L19 7" />
            </svg>
          </div>
          <h2 className="text-base font-semibold text-neutral-200">All clear for today!</h2>
          <p className="text-xs text-neutral-400 mt-1 max-w-xs">
            Tap the <span className="text-indigo-400 font-medium">+</span> button above to create a task scheduled with Bikram Sambat date.
          </p>
        </div>
      )}

      {/* Overdue Section */}
      {overdueOccurrences.length > 0 && (
        <section className="space-y-2.5">
          <div className="flex items-center gap-2">
            <span className="w-2 h-2 rounded-full bg-rose-500 animate-pulse"></span>
            <h2 className="text-xs font-bold uppercase tracking-wider text-rose-400">
              Overdue ({overdueOccurrences.length})
            </h2>
          </div>
          <div className="space-y-2">
            {overdueOccurrences.map((occ) => renderCard(occ, true))}
          </div>
        </section>
      )}

      {/* Pinned Section */}
      {pinnedToday.length > 0 && (
        <section className="space-y-2.5">
          <h2 className="text-xs font-bold uppercase tracking-wider text-amber-400 flex items-center gap-1.5">
            <span>📌 Pinned</span>
            <span className="text-neutral-400">({pinnedToday.length})</span>
          </h2>
          <div className="space-y-2">
            {pinnedToday.map((occ) => renderCard(occ))}
          </div>
        </section>
      )}

      {/* Today Section */}
      {regularToday.length > 0 && (
        <section className="space-y-2.5">
          <h2 className="text-xs font-bold uppercase tracking-wider text-neutral-400 flex items-center gap-1.5">
            <span>Today</span>
            <span>({regularToday.length})</span>
          </h2>
          <div className="space-y-2">
            {regularToday.map((occ) => renderCard(occ))}
          </div>
        </section>
      )}

      {/* Completed Today Section */}
      {completedToday.length > 0 && (
        <section className="space-y-2.5 pt-2">
          <details className="group">
            <summary className="text-xs font-bold uppercase tracking-wider text-neutral-500 cursor-pointer flex items-center justify-between select-none list-none py-1">
              <span>Completed ({completedToday.length})</span>
              <svg className="w-4 h-4 transition-transform group-open:rotate-180" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
              </svg>
            </summary>
            <div className="space-y-2 mt-2 opacity-75">
              {completedToday.map((occ) => renderCard(occ))}
            </div>
          </details>
        </section>
      )}

      {/* Floating Bulk Action Bar */}
      {isMultiSelect && selectedIds.size > 0 && (
        <div className="fixed bottom-16 left-3 right-3 z-40 max-w-md mx-auto bg-neutral-900 border border-indigo-500/50 rounded-2xl p-2.5 shadow-2xl flex items-center justify-between gap-2 animate-in slide-in-from-bottom duration-200">
          <span className="text-xs font-bold text-indigo-300 pl-2">
            {selectedIds.size} selected
          </span>
          <div className="flex gap-1.5">
            <button
              onClick={handleBulkComplete}
              className="px-2.5 py-1.5 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white text-xs font-semibold active:scale-95 transition-all"
            >
              Complete
            </button>
            <button
              onClick={handleBulkSkip}
              className="px-2.5 py-1.5 rounded-xl bg-neutral-800 hover:bg-neutral-700 text-neutral-200 text-xs font-semibold active:scale-95 transition-all"
            >
              Skip
            </button>
            <button
              onClick={handleBulkDelete}
              className="px-2.5 py-1.5 rounded-xl bg-rose-950/40 border border-rose-800/40 text-rose-300 text-xs font-semibold active:scale-95 transition-all"
            >
              Delete
            </button>
          </div>
        </div>
      )}
    </div>
  )
}
