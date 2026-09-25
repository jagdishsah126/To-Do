// ============================================================
// IndexedDB — Database Initialization & Schema
//
// Architecture rule: All IndexedDB access goes through db/*.ts
// The UI layer NEVER touches IndexedDB directly.
//
// Schema version history:
//   v1 — Initial schema (series, occurrences, settings,
//         categories, tags, archivedOccurrences)
// ============================================================

import { openDB, type IDBPDatabase } from 'idb'
import { DB_NAME, DB_VERSION } from '../utils/constants'
import { runMigrations } from './migrations'

export type ZaraDB = IDBPDatabase<unknown>

let dbPromise: Promise<ZaraDB> | null = null

/**
 * Open (or reuse) the IndexedDB connection.
 * Call this from db/taskDb.ts and db/settingsDb.ts — not from components.
 */
export async function getDB(): Promise<ZaraDB> {
  if (!dbPromise) {
    dbPromise = openDB(DB_NAME, DB_VERSION, {
      upgrade(db, oldVersion, newVersion, transaction) {
        runMigrations(db, oldVersion, newVersion ?? DB_VERSION, transaction)
      },
      blocked() {
        console.warn('[DB] Upgrade blocked — another tab has the DB open.')
      },
      blocking() {
        // This tab is blocking an upgrade elsewhere — close and reopen
        dbPromise = null
      },
      terminated() {
        console.error('[DB] Connection terminated unexpectedly.')
        dbPromise = null
      },
    })
  }
  return dbPromise
}

// Object store names — use these constants everywhere
export const STORES = {
  SERIES: 'series',
  OCCURRENCES: 'occurrences',
  SETTINGS: 'settings',
  CATEGORIES: 'categories',
  TAGS: 'tags',
  ARCHIVED_OCCURRENCES: 'archivedOccurrences',
} as const

export type StoreName = (typeof STORES)[keyof typeof STORES]
