import React, { useState, useMemo } from 'react'
import { useTaskStore } from '../store/taskStore'
import { useUIStore } from '../store/uiStore'
import { formatTime, isOverdue } from '../utils/dateUtils'
import { formatBS, adToBS } from '../utils/bsUtils'
import { haptic } from '../utils/haptics'
import type { TaskSeries } from '../types'

export const SearchPage: React.FC = () => {
  const [query, setQuery] = useState('')
  const [activeFilter, setActiveFilter] = useState<'all' | 'incomplete' | 'completed' | 'overdue' | 'pinned'>('all')
  const { series, occurrences } = useTaskStore()
  const { openSheet } = useUIStore()

  const seriesMap = useMemo(() => new Map<string, TaskSeries>(series.map((s) => [s.id, s])), [series])

  const filteredResults = useMemo(() => {
    const q = query.trim().toLowerCase()

    return occurrences.filter((occ) => {
      const s = seriesMap.get(occ.seriesId)
      if (!s) return false

      // Match query
      if (q) {
        const titleMatch = s.title.toLowerCase().includes(q)
        const descMatch = s.description?.toLowerCase().includes(q) ?? false
        const tagMatch = s.tags.some((t) => t.toLowerCase().includes(q))
        if (!titleMatch && !descMatch && !tagMatch) return false
      }

      // Filter category
      if (activeFilter === 'incomplete') return occ.status !== 'completed' && occ.status !== 'skipped'
      if (activeFilter === 'completed') return occ.status === 'completed'
      if (activeFilter === 'overdue') return isOverdue(occ.scheduledAt) && occ.status !== 'completed'
      if (activeFilter === 'pinned') return s.isPinned

      return true
    })
  }, [occurrences, seriesMap, query, activeFilter])

  return (
    <div className="p-4 space-y-4 pb-24 select-none">
      {/* Search Input Bar */}
      <div className="relative">
        <input
          type="text"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="Search tasks, notes, tags..."
          className="w-full bg-neutral-900 border border-neutral-800 rounded-2xl pl-10 pr-4 py-2.5 text-sm text-neutral-100 placeholder-neutral-500 focus:outline-none focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 transition-all"
        />
        <svg className="w-5 h-5 text-neutral-500 absolute left-3 top-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
        </svg>
        {query && (
          <button
            onClick={() => setQuery('')}
            className="absolute right-3 top-3 text-neutral-400 hover:text-neutral-200"
          >
            ✕
          </button>
        )}
      </div>

      {/* Filter chips */}
      <div className="flex gap-2 overflow-x-auto pb-1 scrollbar-none">
        {[
          { id: 'all', label: 'All' },
          { id: 'incomplete', label: 'Upcoming' },
          { id: 'overdue', label: 'Overdue' },
          { id: 'completed', label: 'Completed' },
          { id: 'pinned', label: 'Pinned' },
        ].map((f) => (
          <button
            key={f.id}
            onClick={() => {
              haptic.light()
              setActiveFilter(f.id as typeof activeFilter)
            }}
            className={`px-3 py-1.5 rounded-full text-xs font-medium whitespace-nowrap transition-colors active:scale-95 ${
              activeFilter === f.id
                ? 'bg-indigo-600 text-white shadow-sm'
                : 'bg-neutral-900 text-neutral-400 hover:text-neutral-200 border border-neutral-800'
            }`}
          >
            {f.label}
          </button>
        ))}
      </div>

      {/* Results */}
      <div className="space-y-2 pt-1">
        {filteredResults.length === 0 ? (
          <div className="py-16 text-center text-xs text-neutral-500">
            {query ? `No tasks found matching "${query}"` : 'No tasks in this category'}
          </div>
        ) : (
          filteredResults.map((occ) => {
            const s = seriesMap.get(occ.seriesId)
            const dateObj = new Date(occ.scheduledAt)
            const bsDate = adToBS(dateObj)
            const timeFormatted = formatTime(dateObj, '12h')

            return (
              <div
                key={occ.id}
                onClick={() => {
                  haptic.light()
                  openSheet('task_detail', { occurrenceId: occ.id, seriesId: occ.seriesId })
                }}
                className="p-3.5 rounded-2xl bg-neutral-900/70 border border-neutral-800/80 hover:border-neutral-700/80 transition-colors select-none"
              >
                <div className="flex items-center justify-between">
                  <h4 className={`text-sm font-semibold truncate ${occ.status === 'completed' ? 'line-through text-neutral-400' : 'text-neutral-100'}`}>
                    {s?.title ?? 'Untitled Task'}
                  </h4>
                  <span className={`text-[10px] uppercase font-bold px-2 py-0.5 rounded-full ${
                    occ.status === 'completed'
                      ? 'bg-emerald-500/20 text-emerald-400'
                      : isOverdue(occ.scheduledAt)
                      ? 'bg-rose-500/20 text-rose-400'
                      : 'bg-neutral-800 text-neutral-300'
                  }`}>
                    {occ.status}
                  </span>
                </div>

                {s?.description && (
                  <p className="text-xs text-neutral-400 line-clamp-1 mt-1">{s.description}</p>
                )}

                <div className="flex items-center gap-2 mt-2 text-[11px] text-neutral-400">
                  <span>{timeFormatted}</span>
                  <span>•</span>
                  <span>{formatBS(bsDate)}</span>
                </div>
              </div>
            )
          })
        )}
      </div>
    </div>
  )
}
