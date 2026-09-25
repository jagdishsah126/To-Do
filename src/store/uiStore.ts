// ============================================================
// UI Store — Zustand
// Controls modals, bottom sheets, undo stack, focus mode,
// current navigation state, and transient UI state.
// ============================================================

import { create } from 'zustand'
import type { UndoAction } from '../types'

type BottomSheetType =
  | 'create_task'
  | 'edit_task'
  | 'task_detail'
  | 'snooze'
  | 'reschedule'
  | 'day_tasks'
  | null

interface FocusMode {
  active: boolean
  endsAt: number | null  // Date.now() timestamp
}

interface UIState {
  // Navigation
  activeTab: 'home' | 'calendar' | 'search' | 'settings'
  setActiveTab: (tab: UIState['activeTab']) => void

  // Bottom Sheet
  bottomSheet: BottomSheetType
  bottomSheetData: Record<string, unknown>
  openSheet: (type: NonNullable<BottomSheetType>, data?: Record<string, unknown>) => void
  closeSheet: () => void

  // Undo
  undoActions: UndoAction[]
  pushUndo: (action: Omit<UndoAction, 'id' | 'expiresAt'>) => void
  popUndo: (id: string) => void
  clearExpiredUndo: () => void

  // Focus Mode
  focusMode: FocusMode
  startFocus: (durationMinutes: number) => void
  endFocus: () => void

  // Selected calendar day
  selectedCalendarDate: string | null   // AD ISO date string (YYYY-MM-DD)
  setSelectedCalendarDate: (date: string | null) => void

  // Search query
  searchQuery: string
  setSearchQuery: (q: string) => void
}

export const useUIStore = create<UIState>((set, get) => ({
  // ---- Navigation ----
  activeTab: 'home',
  setActiveTab: (tab) => set({ activeTab: tab }),

  // ---- Bottom Sheet ----
  bottomSheet: null,
  bottomSheetData: {},
  openSheet: (type, data = {}) => set({ bottomSheet: type, bottomSheetData: data }),
  closeSheet: () => set({ bottomSheet: null, bottomSheetData: {} }),

  // ---- Undo ----
  undoActions: [],

  pushUndo: ({ label, undo }) => {
    const id = `undo-${Date.now()}`
    const action: UndoAction = {
      id,
      label,
      expiresAt: Date.now() + 4000,
      undo,
    }
    set((state) => ({ undoActions: [...state.undoActions, action] }))

    // Auto-remove after 4 seconds
    setTimeout(() => get().popUndo(id), 4000)
  },

  popUndo: (id) => {
    set((state) => ({ undoActions: state.undoActions.filter((a) => a.id !== id) }))
  },

  clearExpiredUndo: () => {
    const now = Date.now()
    set((state) => ({
      undoActions: state.undoActions.filter((a) => a.expiresAt > now),
    }))
  },

  // ---- Focus Mode ----
  focusMode: { active: false, endsAt: null },

  startFocus: (durationMinutes) => {
    const endsAt = Date.now() + durationMinutes * 60 * 1000
    set({ focusMode: { active: true, endsAt } })
    // Auto-end focus mode
    setTimeout(() => {
      const current = get().focusMode
      if (current.active && current.endsAt && Date.now() >= current.endsAt) {
        set({ focusMode: { active: false, endsAt: null } })
      }
    }, durationMinutes * 60 * 1000 + 100)
  },

  endFocus: () => set({ focusMode: { active: false, endsAt: null } }),

  // ---- Calendar ----
  selectedCalendarDate: null,
  setSelectedCalendarDate: (date) => set({ selectedCalendarDate: date }),

  // ---- Search ----
  searchQuery: '',
  setSearchQuery: (q) => set({ searchQuery: q }),
}))
