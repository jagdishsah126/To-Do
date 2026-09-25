// ============================================================
// Task Store — Zustand
//
// Manages loaded series, occurrences, selection state, filters.
// All mutations go through DB first, then update store state.
// ============================================================

import { create } from 'zustand'
import type { TaskSeries, TaskOccurrence, OccurrenceStatus } from '../types'
import * as taskDb from '../db/taskDb'
import { nowISO } from '../utils/dateUtils'

interface TaskFilters {
  status?: OccurrenceStatus[]
  categoryId?: string
  priority?: string
  tagIds?: string[]
  searchQuery?: string
}

interface TaskState {
  series: TaskSeries[]
  occurrences: TaskOccurrence[]
  selectedIds: Set<string>
  isMultiSelect: boolean
  filters: TaskFilters
  isLoading: boolean
  error: string | null

  // Loaders
  loadAll: () => Promise<void>
  loadOccurrencesForRange: (start: Date, end: Date) => Promise<void>

  // Series mutations
  createSeries: (data: Omit<TaskSeries, 'id' | 'createdAt' | 'updatedAt'>) => Promise<TaskSeries>
  updateSeries: (id: string, updates: Partial<TaskSeries>) => Promise<void>
  deleteSeries: (id: string) => Promise<void>

  // Occurrence mutations
  createOccurrence: (data: Omit<TaskOccurrence, 'id'>) => Promise<TaskOccurrence>
  updateOccurrence: (id: string, updates: Partial<TaskOccurrence>) => Promise<void>
  archiveOccurrence: (id: string) => Promise<void>

  // Quick task actions
  completeOccurrence: (id: string) => Promise<void>
  skipOccurrence: (id: string) => Promise<void>
  snoozeOccurrence: (id: string, until: string) => Promise<void>

  // Selection
  toggleSelect: (id: string) => void
  selectAll: (ids: string[]) => void
  clearSelection: () => void
  setMultiSelect: (active: boolean) => void

  // Filters
  setFilters: (filters: TaskFilters) => void
  clearFilters: () => void

  // Pin
  togglePin: (seriesId: string) => Promise<void>
}

export const useTaskStore = create<TaskState>((set, get) => ({
  series: [],
  occurrences: [],
  selectedIds: new Set(),
  isMultiSelect: false,
  filters: {},
  isLoading: false,
  error: null,

  // ---- Loaders ----

  loadAll: async () => {
    set({ isLoading: true, error: null })
    try {
      const [series, occurrences] = await Promise.all([
        taskDb.getAllSeries(),
        taskDb.getAllOccurrences(),
      ])
      set({ series, occurrences, isLoading: false })
    } catch (err) {
      set({ error: String(err), isLoading: false })
    }
  },

  loadOccurrencesForRange: async (start, end) => {
    try {
      const rangeOccurrences = await taskDb.getOccurrencesForDateRange(start, end)
      set((state) => {
        const existingIds = new Set(rangeOccurrences.map((o) => o.id))
        const merged = [
          ...state.occurrences.filter((o) => !existingIds.has(o.id)),
          ...rangeOccurrences,
        ]
        return { occurrences: merged }
      })
    } catch (err) {
      set({ error: String(err) })
    }
  },

  // ---- Series mutations ----

  createSeries: async (data) => {
    const series = await taskDb.createSeries(data)
    set((state) => ({ series: [...state.series, series] }))
    return series
  },

  updateSeries: async (id, updates) => {
    const updated = await taskDb.updateSeries(id, updates)
    if (!updated) return
    set((state) => ({
      series: state.series.map((s) => (s.id === id ? updated : s)),
    }))
  },

  deleteSeries: async (id) => {
    await taskDb.deleteSeries(id)
    set((state) => ({
      series: state.series.filter((s) => s.id !== id),
      occurrences: state.occurrences.filter((o) => o.seriesId !== id),
    }))
  },

  // ---- Occurrence mutations ----

  createOccurrence: async (data) => {
    const occurrence = await taskDb.createOccurrence(data)
    set((state) => ({ occurrences: [...state.occurrences, occurrence] }))
    return occurrence
  },

  updateOccurrence: async (id, updates) => {
    const updated = await taskDb.updateOccurrence(id, updates)
    if (!updated) return
    set((state) => ({
      occurrences: state.occurrences.map((o) => (o.id === id ? updated : o)),
    }))
  },

  archiveOccurrence: async (id) => {
    await taskDb.archiveOccurrence(id)
    set((state) => ({
      occurrences: state.occurrences.filter((o) => o.id !== id),
    }))
  },

  // ---- Quick actions ----

  completeOccurrence: async (id) => {
    await get().updateOccurrence(id, {
      status: 'completed',
      completedAt: nowISO(),
    })
  },

  skipOccurrence: async (id) => {
    await get().updateOccurrence(id, {
      status: 'skipped',
      skippedAt: nowISO(),
    })
  },

  snoozeOccurrence: async (id, until) => {
    await get().updateOccurrence(id, {
      status: 'snoozed',
      snoozedUntil: until,
    })
  },

  // ---- Selection ----

  toggleSelect: (id) => {
    set((state) => {
      const next = new Set(state.selectedIds)
      if (next.has(id)) next.delete(id)
      else next.add(id)
      return { selectedIds: next, isMultiSelect: next.size > 0 }
    })
  },

  selectAll: (ids) => {
    set({ selectedIds: new Set(ids), isMultiSelect: true })
  },

  clearSelection: () => {
    set({ selectedIds: new Set(), isMultiSelect: false })
  },

  setMultiSelect: (active) => {
    set({ isMultiSelect: active, selectedIds: active ? get().selectedIds : new Set() })
  },

  // ---- Filters ----

  setFilters: (filters) => set({ filters }),
  clearFilters: () => set({ filters: {} }),

  // ---- Pin ----

  togglePin: async (seriesId) => {
    const s = get().series.find((x) => x.id === seriesId)
    if (!s) return
    await get().updateSeries(seriesId, { isPinned: !s.isPinned })
  },
}))
