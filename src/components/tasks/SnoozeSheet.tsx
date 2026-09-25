import React from 'react'
import { useTaskStore } from '../../store/taskStore'
import { useUIStore } from '../../store/uiStore'
import { haptic } from '../../utils/haptics'
import { tomorrow } from '../../utils/dateUtils'

export const SnoozeSheet: React.FC = () => {
  const { snoozeOccurrence } = useTaskStore()
  const { closeSheet, bottomSheetData, pushUndo } = useUIStore()

  const occurrenceId = bottomSheetData.occurrenceId as string | undefined

  if (!occurrenceId) return null

  const handleSnoozeMinutes = async (minutes: number) => {
    haptic.medium()
    const until = new Date(Date.now() + minutes * 60 * 1000).toISOString()
    await snoozeOccurrence(occurrenceId, until)
    pushUndo({
      label: `Snoozed for ${minutes}m`,
      undo: async () => {
        await useTaskStore.getState().updateOccurrence(occurrenceId, {
          status: 'upcoming',
          snoozedUntil: undefined,
        })
      },
    })
    closeSheet()
  }

  const handleSnoozeTomorrow = async () => {
    haptic.medium()
    const t = tomorrow()
    t.setHours(9, 0, 0, 0)
    await snoozeOccurrence(occurrenceId, t.toISOString())
    pushUndo({
      label: 'Snoozed until tomorrow 9:00 AM',
      undo: async () => {
        await useTaskStore.getState().updateOccurrence(occurrenceId, {
          status: 'upcoming',
          snoozedUntil: undefined,
        })
      },
    })
    closeSheet()
  }

  const options = [
    { label: '5 minutes', action: () => handleSnoozeMinutes(5) },
    { label: '10 minutes', action: () => handleSnoozeMinutes(10) },
    { label: '15 minutes', action: () => handleSnoozeMinutes(15) },
    { label: '30 minutes', action: () => handleSnoozeMinutes(30) },
    { label: '1 hour', action: () => handleSnoozeMinutes(60) },
    { label: 'Tomorrow morning (9:00 AM)', action: handleSnoozeTomorrow },
  ]

  return (
    <div className="space-y-2 pt-2 select-none">
      <p className="text-xs text-neutral-400 mb-3">
        Choose when to be reminded again:
      </p>
      {options.map((opt, i) => (
        <button
          key={i}
          onClick={opt.action}
          className="w-full text-left px-4 py-3 rounded-xl bg-neutral-950/60 hover:bg-neutral-800 border border-neutral-800 text-xs font-semibold text-neutral-200 active:scale-98 transition-all flex items-center justify-between"
        >
          <span>{opt.label}</span>
          <span className="text-neutral-500">→</span>
        </button>
      ))}
    </div>
  )
}
