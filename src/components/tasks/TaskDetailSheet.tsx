import React, { useState } from 'react'
import { useTaskStore } from '../../store/taskStore'
import { useUIStore } from '../../store/uiStore'
import { formatTime, generateId } from '../../utils/dateUtils'
import { formatBS, adToBS } from '../../utils/bsUtils'
import { haptic } from '../../utils/haptics'
import type { Subtask } from '../../types'
import {
  onOccurrenceCompletedOrSkipped,
  skipRecurringOccurrence,
  editThisOccurrenceOnly,
  editEntireSeries,
  editThisAndFutureOccurrences,
} from '../../services/recurrenceService'

export const TaskDetailSheet: React.FC = () => {
  const { series, occurrences, completeOccurrence, togglePin, deleteSeries, updateSeries, loadAll } = useTaskStore()
  const { closeSheet, bottomSheetData, pushUndo, openSheet } = useUIStore()

  const occurrenceId = bottomSheetData.occurrenceId as string | undefined
  const seriesId = bottomSheetData.seriesId as string | undefined

  const occ = occurrences.find((o) => o.id === occurrenceId)
  const s = series.find((item) => item.id === (seriesId ?? occ?.seriesId))

  const [isEditing, setIsEditing] = useState(false)
  const [editTitle, setEditTitle] = useState(s?.title ?? '')
  const [editDesc, setEditDesc] = useState(s?.description ?? '')
  const [editingScope, setEditingScope] = useState<'this' | 'future' | 'all'>('this')
  const [newSubtaskTitle, setNewSubtaskTitle] = useState('')

  if (!occ || !s) {
    return (
      <div className="py-6 text-center text-xs text-neutral-500">
        Task not found.
      </div>
    )
  }

  const isRecurring = Boolean(s.recurrenceRule)
  const dateObj = new Date(occ.scheduledAt)
  const bsDate = adToBS(dateObj)
  const timeFormatted = formatTime(dateObj, '12h')
  const subtasks: Subtask[] = s.subtasks ?? []
  const completedSubtasks = subtasks.filter((st) => st.completed).length

  const handleComplete = async () => {
    haptic.success()
    await completeOccurrence(occ.id)

    // Advance recurring series if applicable
    if (isRecurring) {
      await onOccurrenceCompletedOrSkipped(occ)
      await loadAll()
    }

    pushUndo({
      label: `Completed "${s.title}"`,
      undo: async () => {
        await useTaskStore.getState().updateOccurrence(occ.id, {
          status: 'upcoming',
          completedAt: undefined,
        })
      },
    })
    closeSheet()
  }

  const handleSkip = async () => {
    haptic.medium()
    if (isRecurring) {
      await skipRecurringOccurrence(occ.id)
      await loadAll()
    } else {
      await useTaskStore.getState().skipOccurrence(occ.id)
    }

    pushUndo({
      label: `Skipped "${s.title}"`,
      undo: async () => {
        await useTaskStore.getState().updateOccurrence(occ.id, {
          status: 'upcoming',
          skippedAt: undefined,
        })
      },
    })
    closeSheet()
  }

  const handleDelete = async () => {
    haptic.heavy()
    const confirmDelete = window.confirm(
      isRecurring
        ? `Delete entire recurring series "${s.title}" and all its occurrences?`
        : `Are you sure you want to delete "${s.title}"?`
    )
    if (!confirmDelete) return

    await deleteSeries(s.id)
    closeSheet()
  }

  const handleSaveEdit = async () => {
    haptic.medium()
    if (!editTitle.trim()) return

    if (!isRecurring || editingScope === 'all') {
      await editEntireSeries(s.id, {
        title: editTitle.trim(),
        description: editDesc.trim() || undefined,
      })
    } else if (editingScope === 'this') {
      await editThisOccurrenceOnly(occ.id, {
        title: editTitle.trim(),
        description: editDesc.trim() || undefined,
      })
    } else if (editingScope === 'future') {
      await editThisAndFutureOccurrences(s.id, new Date(occ.scheduledAt), {
        title: editTitle.trim(),
        description: editDesc.trim() || undefined,
      })
    }

    await loadAll()
    setIsEditing(false)
  }

  // Subtask Handlers
  const handleAddSubtask = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!newSubtaskTitle.trim()) return
    haptic.light()

    const updated: Subtask[] = [
      ...subtasks,
      { id: generateId(), title: newSubtaskTitle.trim(), completed: false },
    ]
    await updateSeries(s.id, { subtasks: updated })
    setNewSubtaskTitle('')
  }

  const handleToggleSubtask = async (subtaskId: string) => {
    haptic.light()
    const updated = subtasks.map((st) =>
      st.id === subtaskId ? { ...st, completed: !st.completed } : st
    )
    await updateSeries(s.id, { subtasks: updated })
  }

  const handleDeleteSubtask = async (subtaskId: string) => {
    haptic.light()
    const updated = subtasks.filter((st) => st.id !== subtaskId)
    await updateSeries(s.id, { subtasks: updated })
  }

  return (
    <div className="space-y-4 pt-1 select-none">
      {/* Title & Priority Header */}
      {!isEditing ? (
        <div>
          <div className="flex items-center gap-2 flex-wrap">
            <span className={`text-[10px] uppercase font-bold px-2 py-0.5 rounded-full ${
              s.priority === 'urgent'
                ? 'bg-rose-500/20 text-rose-400'
                : s.priority === 'high'
                ? 'bg-amber-500/20 text-amber-400'
                : 'bg-neutral-800 text-neutral-300'
            }`}>
              {s.priority} Priority
            </span>
            {s.isPinned && (
              <span className="text-[10px] bg-amber-500/20 text-amber-300 px-2 py-0.5 rounded-full">
                📌 Pinned
              </span>
            )}
            {isRecurring && (
              <span className="text-[10px] bg-indigo-500/20 text-indigo-300 border border-indigo-500/30 px-2 py-0.5 rounded-full">
                🔁 Recurring ({s.recurrenceRule?.type})
              </span>
            )}
            {occ.isException && (
              <span className="text-[10px] bg-purple-500/20 text-purple-300 border border-purple-500/30 px-2 py-0.5 rounded-full">
                Modified Occurrence
              </span>
            )}
          </div>
          <h2 className="text-lg font-bold text-neutral-100 mt-2">
            {occ.exceptionData?.title ?? s.title}
          </h2>
        </div>
      ) : (
        /* Edit Mode Form */
        <div className="space-y-3 p-3 rounded-xl bg-neutral-950/70 border border-indigo-500/40">
          <div>
            <label className="block text-xs font-semibold text-neutral-400 mb-1">
              Title
            </label>
            <input
              type="text"
              value={editTitle}
              onChange={(e) => setEditTitle(e.target.value)}
              className="w-full bg-neutral-900 border border-neutral-700 rounded-lg px-3 py-1.5 text-xs text-neutral-100 focus:outline-none focus:border-indigo-500"
            />
          </div>

          <div>
            <label className="block text-xs font-semibold text-neutral-400 mb-1">
              Description
            </label>
            <textarea
              rows={2}
              value={editDesc}
              onChange={(e) => setEditDesc(e.target.value)}
              className="w-full bg-neutral-900 border border-neutral-700 rounded-lg px-3 py-1.5 text-xs text-neutral-100 focus:outline-none focus:border-indigo-500"
            />
          </div>

          {/* Scope Selector for recurring tasks */}
          {isRecurring && (
            <div className="space-y-1.5 pt-1">
              <label className="block text-[11px] font-semibold text-neutral-400">
                Apply changes to:
              </label>
              <div className="space-y-1 text-xs">
                {[
                  { id: 'this', label: 'This occurrence only' },
                  { id: 'future', label: 'This and future occurrences' },
                  { id: 'all', label: 'Entire recurring series' },
                ].map((scope) => (
                  <label key={scope.id} className="flex items-center gap-2 cursor-pointer">
                    <input
                      type="radio"
                      name="editingScope"
                      checked={editingScope === scope.id}
                      onChange={() => setEditingScope(scope.id as typeof editingScope)}
                      className="text-indigo-600 bg-neutral-900 border-neutral-700"
                    />
                    <span className="text-neutral-300">{scope.label}</span>
                  </label>
                ))}
              </div>
            </div>
          )}

          <div className="flex gap-2 pt-2">
            <button
              onClick={handleSaveEdit}
              className="flex-1 py-1.5 rounded-lg bg-indigo-600 hover:bg-indigo-500 text-white font-semibold text-xs transition-colors"
            >
              Save Changes
            </button>
            <button
              onClick={() => setIsEditing(false)}
              className="px-3 py-1.5 rounded-lg bg-neutral-800 hover:bg-neutral-700 text-neutral-300 text-xs transition-colors"
            >
              Cancel
            </button>
          </div>
        </div>
      )}

      {/* Description */}
      {!isEditing && (occ.exceptionData?.description ?? s.description) && (
        <div className="p-3 rounded-xl bg-neutral-950/60 border border-neutral-800/80">
          <p className="text-xs text-neutral-300 whitespace-pre-wrap">
            {occ.exceptionData?.description ?? s.description}
          </p>
        </div>
      )}

      {/* Schedule Info */}
      <div className="grid grid-cols-2 gap-2 text-xs">
        <div className="p-3 rounded-xl bg-neutral-950/40 border border-neutral-800/80">
          <div className="text-neutral-500 font-medium">Bikram Sambat</div>
          <div className="text-neutral-200 font-semibold mt-0.5">{formatBS(bsDate)}</div>
        </div>
        <div className="p-3 rounded-xl bg-neutral-950/40 border border-neutral-800/80">
          <div className="text-neutral-500 font-medium">Scheduled Time</div>
          <div className="text-neutral-200 font-semibold mt-0.5">{timeFormatted}</div>
        </div>
      </div>

      {/* Subtasks Section */}
      <div className="p-3.5 rounded-2xl bg-neutral-950/40 border border-neutral-800/80 space-y-2.5">
        <div className="flex items-center justify-between">
          <h4 className="text-xs font-bold text-neutral-300 uppercase tracking-wider flex items-center gap-1.5">
            <span>Checklist / Subtasks</span>
            {subtasks.length > 0 && (
              <span className="text-[10px] text-neutral-400 font-normal">
                ({completedSubtasks}/{subtasks.length})
              </span>
            )}
          </h4>
        </div>

        {/* Progress Bar */}
        {subtasks.length > 0 && (
          <div className="w-full h-1.5 bg-neutral-800 rounded-full overflow-hidden">
            <div
              className="h-full bg-indigo-500 transition-all duration-300"
              style={{ width: `${(completedSubtasks / subtasks.length) * 100}%` }}
            />
          </div>
        )}

        {/* Subtask list */}
        {subtasks.length > 0 && (
          <div className="space-y-1.5 max-h-36 overflow-y-auto pr-1">
            {subtasks.map((st) => (
              <div
                key={st.id}
                className="flex items-center justify-between gap-2 p-2 rounded-lg bg-neutral-900/60 border border-neutral-800/60"
              >
                <div
                  onClick={() => handleToggleSubtask(st.id)}
                  className="flex items-center gap-2 cursor-pointer flex-1 min-w-0"
                >
                  <input
                    type="checkbox"
                    checked={st.completed}
                    onChange={() => {}}
                    className="rounded bg-neutral-950 border-neutral-700 text-indigo-600 focus:ring-0 w-3.5 h-3.5"
                  />
                  <span
                    className={`text-xs truncate ${
                      st.completed ? 'line-through text-neutral-500' : 'text-neutral-200'
                    }`}
                  >
                    {st.title}
                  </span>
                </div>
                <button
                  onClick={() => handleDeleteSubtask(st.id)}
                  className="text-neutral-500 hover:text-rose-400 text-xs px-1"
                >
                  ✕
                </button>
              </div>
            ))}
          </div>
        )}

        {/* Add subtask input */}
        <form onSubmit={handleAddSubtask} className="flex gap-2">
          <input
            type="text"
            value={newSubtaskTitle}
            onChange={(e) => setNewSubtaskTitle(e.target.value)}
            placeholder="+ Add subtask"
            className="flex-1 bg-neutral-900 border border-neutral-800 rounded-xl px-3 py-1.5 text-xs text-neutral-200 placeholder-neutral-500 focus:outline-none focus:border-indigo-500"
          />
          {newSubtaskTitle.trim() && (
            <button
              type="submit"
              className="px-3 py-1.5 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white text-xs font-semibold transition-colors"
            >
              Add
            </button>
          )}
        </form>
      </div>

      {/* Action buttons */}
      <div className="space-y-2 pt-1 border-t border-neutral-800/80">
        <div className="flex gap-2">
          <button
            onClick={handleComplete}
            className="flex-1 py-2.5 rounded-xl bg-emerald-600 hover:bg-emerald-500 text-white font-semibold text-xs active:scale-95 transition-all flex items-center justify-center gap-1.5 shadow-md shadow-emerald-600/20"
          >
            <span>✓ Complete</span>
          </button>

          <button
            onClick={() => {
              haptic.light()
              openSheet('snooze', { occurrenceId: occ.id })
            }}
            className="flex-1 py-2.5 rounded-xl bg-neutral-800 hover:bg-neutral-700 text-neutral-200 font-semibold text-xs active:scale-95 transition-all flex items-center justify-center gap-1.5"
          >
            <span>💤 Snooze</span>
          </button>
        </div>

        <div className="flex gap-2">
          <button
            onClick={handleSkip}
            className="flex-1 py-2 rounded-xl bg-neutral-950 hover:bg-neutral-800 border border-neutral-800 text-neutral-300 text-xs font-semibold active:scale-95 transition-all"
          >
            Skip Occurrence
          </button>

          <button
            onClick={() => {
              haptic.light()
              setIsEditing(true)
            }}
            className="px-3 py-2 rounded-xl bg-neutral-950 hover:bg-neutral-800 border border-neutral-800 text-neutral-300 text-xs font-semibold active:scale-95 transition-all"
          >
            Edit
          </button>

          <button
            onClick={() => {
              haptic.light()
              togglePin(s.id)
            }}
            className="px-3 py-2 rounded-xl bg-neutral-950 hover:bg-neutral-800 border border-neutral-800 text-neutral-300 text-xs font-semibold active:scale-95 transition-all"
          >
            {s.isPinned ? 'Unpin' : 'Pin'}
          </button>

          <button
            onClick={handleDelete}
            className="px-3 py-2 rounded-xl bg-rose-950/30 hover:bg-rose-900/40 border border-rose-800/40 text-rose-300 text-xs font-semibold active:scale-95 transition-all"
          >
            Delete
          </button>
        </div>
      </div>
    </div>
  )
}
