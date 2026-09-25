import React from 'react'
import { todayBS, formatBS, weekdayName } from '../../utils/bsUtils'
import { useUIStore } from '../../store/uiStore'
import { useTaskStore } from '../../store/taskStore'
import { haptic } from '../../utils/haptics'

export const TopHeader: React.FC = () => {
  const { focusMode, endFocus, openSheet } = useUIStore()
  const { isMultiSelect, selectedIds, clearSelection } = useTaskStore()

  const today = todayBS()
  const now = new Date()
  const formattedBS = formatBS(today, { monthLang: 'ne' })
  const weekday = weekdayName(now)

  return (
    <header className="sticky top-0 z-30 bg-neutral-950/80 backdrop-blur-md border-b border-neutral-800/60 px-4 py-3 select-none">
      <div className="max-w-md mx-auto flex items-center justify-between">
        {isMultiSelect ? (
          <div className="flex items-center justify-between w-full">
            <span className="text-sm font-semibold text-indigo-400">
              {selectedIds.size} selected
            </span>
            <button
              onClick={() => {
                haptic.light()
                clearSelection()
              }}
              className="text-xs bg-neutral-800 hover:bg-neutral-700 text-neutral-200 px-2.5 py-1 rounded-full transition-colors"
            >
              Done
            </button>
          </div>
        ) : (
          <>
            <div>
              <div className="flex items-center gap-2">
                <h1 className="text-lg font-bold tracking-tight text-white flex items-center gap-1.5">
                  <span className="text-indigo-400">Zara</span>
                  <span className="text-xs font-normal px-2 py-0.5 rounded-full bg-neutral-800 text-neutral-300">
                    {formattedBS}
                  </span>
                </h1>
              </div>
              <p className="text-xs text-neutral-400 font-medium">{weekday}</p>
            </div>

            <div className="flex items-center gap-2">
              {focusMode.active && (
                <button
                  onClick={() => {
                    haptic.medium()
                    endFocus()
                  }}
                  className="flex items-center gap-1 px-2.5 py-1 rounded-full bg-amber-500/20 text-amber-300 text-xs border border-amber-500/30 animate-pulse"
                >
                  <span className="w-1.5 h-1.5 rounded-full bg-amber-400"></span>
                  Focus
                </button>
              )}

              <button
                onClick={() => {
                  haptic.medium()
                  openSheet('create_task')
                }}
                className="w-8 h-8 rounded-full bg-indigo-600 hover:bg-indigo-500 active:scale-95 text-white flex items-center justify-center shadow-lg shadow-indigo-600/30 transition-all"
                aria-label="Add task"
              >
                <svg className="w-5 h-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M12 4v16m8-8H4" />
                </svg>
              </button>
            </div>
          </>
        )}
      </div>
    </header>
  )
}
