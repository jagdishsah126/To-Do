// ============================================================
// Settings Store — Zustand
// ============================================================

import { create } from 'zustand'
import type { AppSettings } from '../types'
import * as settingsDb from '../db/settingsDb'

interface SettingsState {
  settings: AppSettings | null
  isLoaded: boolean
  load: () => Promise<void>
  update: (partial: Partial<AppSettings>) => Promise<void>
  reset: () => Promise<void>
}

export const useSettingsStore = create<SettingsState>((set, get) => ({
  settings: null,
  isLoaded: false,

  load: async () => {
    const settings = await settingsDb.getSettings()
    set({ settings, isLoaded: true })
  },

  update: async (partial) => {
    const current = get().settings
    if (!current) return
    const updated = await settingsDb.updateSettings(partial)
    set({ settings: updated })
  },

  reset: async () => {
    const defaults = await settingsDb.resetSettings()
    set({ settings: defaults })
  },
}))
