// ============================================================
// Backup Service — Versioned JSON Export & Import
//
// Rule: JSON exports are strictly versioned.
// Format: 'personal-todo-backup', Version: 1
// CSV is export-only (never for restore).
// ============================================================

import type { VersionedBackup } from '../types'
import { BACKUP_FORMAT, BACKUP_VERSION, APP_VERSION } from '../utils/constants'
import * as taskDb from '../db/taskDb'
import * as settingsDb from '../db/settingsDb'
import { nowISO } from '../utils/dateUtils'

/**
 * Export all local data as a versioned JSON file.
 */
export async function exportBackupJSON(): Promise<void> {
  const [series, occurrences, settings, categories, tags] = await Promise.all([
    taskDb.getAllSeries(),
    taskDb.getAllOccurrences(),
    settingsDb.getSettings(),
    taskDb.getAllCategories(),
    taskDb.getAllTags(),
  ])

  const backup: VersionedBackup = {
    format: BACKUP_FORMAT,
    version: BACKUP_VERSION,
    exportedAt: nowISO(),
    appVersion: APP_VERSION,
    data: {
      series,
      occurrences,
      settings,
      categories,
      tags,
    },
  }

  const blob = new Blob([JSON.stringify(backup, null, 2)], {
    type: 'application/json',
  })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  const dateStr = new Date().toISOString().slice(0, 10)
  a.href = url
  a.download = `zara-todo-backup-${dateStr}.json`
  document.body.appendChild(a)
  a.click()
  document.body.removeChild(a)
  URL.revokeObjectURL(url)
}

/**
 * Validate and restore a backup from a JSON file.
 */
export async function importBackupJSON(file: File): Promise<void> {
  const text = await file.text()
  let parsed: unknown

  try {
    parsed = JSON.parse(text)
  } catch {
    throw new Error('Invalid JSON file. Please ensure the file is valid.')
  }

  if (typeof parsed !== 'object' || parsed === null) {
    throw new Error('Invalid backup structure.')
  }

  const backup = parsed as Partial<VersionedBackup>

  if (backup.format !== BACKUP_FORMAT) {
    throw new Error(
      `Unsupported backup format: "${backup.format ?? 'unknown'}". Expected "${BACKUP_FORMAT}".`
    )
  }

  if (typeof backup.version !== 'number' || backup.version > BACKUP_VERSION) {
    throw new Error(
      `Backup version ${backup.version} is not supported by this version of Zara To-Do.`
    )
  }

  if (!backup.data || typeof backup.data !== 'object') {
    throw new Error('Backup data is missing or corrupted.')
  }

  const { series, occurrences, settings, categories, tags } = backup.data

  // Restore into IndexedDB
  if (Array.isArray(series)) {
    for (const s of series) {
      await taskDb.createSeries(s)
    }
  }

  if (Array.isArray(occurrences)) {
    for (const occ of occurrences) {
      await taskDb.createOccurrence(occ)
    }
  }

  if (settings && typeof settings === 'object') {
    await settingsDb.saveSettings(settings)
  }

  if (Array.isArray(categories)) {
    for (const cat of categories) {
      await taskDb.saveCategory(cat)
    }
  }

  if (Array.isArray(tags)) {
    for (const tag of tags) {
      await taskDb.saveTag(tag)
    }
  }
}
