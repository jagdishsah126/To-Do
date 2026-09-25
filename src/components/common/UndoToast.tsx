import React from 'react'
import { useUIStore } from '../../store/uiStore'
import { haptic } from '../../utils/haptics'

export const UndoToast: React.FC = () => {
  const { undoActions, popUndo } = useUIStore()

  if (undoActions.length === 0) return null

  const latest = undoActions[undoActions.length - 1]

  const handleUndo = async () => {
    haptic.medium()
    try {
      await latest.undo()
    } finally {
      popUndo(latest.id)
    }
  }

  return (
    <div className="fixed bottom-16 left-4 right-4 z-50 max-w-md mx-auto pointer-events-none flex justify-center">
      <div className="pointer-events-auto bg-neutral-900 border border-neutral-700/80 text-neutral-100 shadow-2xl rounded-2xl px-4 py-2.5 flex items-center justify-between gap-4 w-full animate-in fade-in slide-in-from-bottom-3 duration-200">
        <span className="text-sm font-medium tracking-tight text-neutral-200">
          {latest.label}
        </span>
        <button
          onClick={handleUndo}
          className="text-xs font-semibold text-indigo-400 hover:text-indigo-300 bg-indigo-950/60 border border-indigo-700/40 px-3 py-1.5 rounded-lg active:scale-95 transition-all"
        >
          Undo
        </button>
      </div>
    </div>
  )
}
