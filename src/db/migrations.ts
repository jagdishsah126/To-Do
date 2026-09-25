// ============================================================
// IndexedDB — Migrations
//
// Every schema change gets a migration function here.
// NEVER modify an existing migration — only add new ones.
// NEVER drop object stores without archiving data first.
// ============================================================

import type { IDBPDatabase, IDBPTransaction } from 'idb'

type UpgradeTransaction = IDBPTransaction<unknown, string[], 'versionchange'>

/**
 * Run all pending migrations from oldVersion to newVersion.
 * Each migration is additive — earlier ones are never modified.
 */
export function runMigrations(
  db: IDBPDatabase<unknown>,
  oldVersion: number,
  newVersion: number,
  _transaction: UpgradeTransaction
): void {
  console.log(`[DB] Migrating ${oldVersion} → ${newVersion}`)

  if (oldVersion < 1) {
    migrateV1(db)
  }

  // Future migrations:
  // if (oldVersion < 2) migrateV2(db, transaction)
  // if (oldVersion < 3) migrateV3(db, transaction)
}

// ------------------------------------------------------------
// v1 — Initial schema
// ------------------------------------------------------------

function migrateV1(db: IDBPDatabase<unknown>): void {
  // TaskSeries — the definition of a task/recurring series
  if (!db.objectStoreNames.contains('series')) {
    const seriesStore = db.createObjectStore('series', { keyPath: 'id' })
    seriesStore.createIndex('by_title', 'title')
    seriesStore.createIndex('by_category', 'categoryId')
    seriesStore.createIndex('by_priority', 'priority')
    seriesStore.createIndex('by_created', 'createdAt')
    seriesStore.createIndex('by_updated', 'updatedAt')
  }

  // TaskOccurrence — individual scheduled instances
  if (!db.objectStoreNames.contains('occurrences')) {
    const occStore = db.createObjectStore('occurrences', { keyPath: 'id' })
    occStore.createIndex('by_series', 'seriesId')
    occStore.createIndex('by_scheduled', 'scheduledAt')
    occStore.createIndex('by_status', 'status')
  }

  // AppSettings — single record store (key = 'settings')
  if (!db.objectStoreNames.contains('settings')) {
    db.createObjectStore('settings')
  }

  // Categories
  if (!db.objectStoreNames.contains('categories')) {
    const catStore = db.createObjectStore('categories', { keyPath: 'id' })
    catStore.createIndex('by_name', 'name')
  }

  // Tags
  if (!db.objectStoreNames.contains('tags')) {
    const tagStore = db.createObjectStore('tags', { keyPath: 'id' })
    tagStore.createIndex('by_name', 'name')
  }

  // Archived occurrences — completed/deleted but preserved
  if (!db.objectStoreNames.contains('archivedOccurrences')) {
    const archStore = db.createObjectStore('archivedOccurrences', { keyPath: 'id' })
    archStore.createIndex('by_series', 'seriesId')
    archStore.createIndex('by_scheduled', 'scheduledAt')
  }

  console.log('[DB] v1 schema created.')
}
