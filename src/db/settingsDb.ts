// ============================================================
// Settings Database
// ============================================================

import { getDB, STORES } from './database'
import type { AppSettings } from '../types'
import { DEFAULT_SETTINGS } from '../utils/constants'

const SETTINGS_KEY = 'settings'

export async function getSettings(): Promise<AppSettings> {
  const db = await getDB()
  const stored = await db.get(STORES.SETTINGS, SETTINGS_KEY)
  if (!stored) return { ...DEFAULT_SETTINGS }
  // Merge with defaults so new settings fields always have a value
  return { ...DEFAULT_SETTINGS, ...(stored as AppSettings) }
}

export async function saveSettings(settings: AppSettings): Promise<void> {
  const db = await getDB()
  await db.put(STORES.SETTINGS, settings, SETTINGS_KEY)
}

export async function updateSettings(
  partial: Partial<AppSettings>
): Promise<AppSettings> {
  const current = await getSettings()
  const updated = { ...current, ...partial }
  await saveSettings(updated)
  return updated
}

export async function resetSettings(): Promise<AppSettings> {
  const db = await getDB()
  await db.put(STORES.SETTINGS, { ...DEFAULT_SETTINGS }, SETTINGS_KEY)
  return { ...DEFAULT_SETTINGS }
}
