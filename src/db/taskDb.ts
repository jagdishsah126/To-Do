// ============================================================
// Task Database — CRUD for TaskSeries & TaskOccurrence
//
// Architecture: Only this file accesses series/occurrences stores.
// Everything goes through here. Zustand stores call these functions.
// ============================================================

import { getDB, STORES } from './database'
import type { TaskSeries, TaskOccurrence } from '../types'
import { nowISO, generateId } from '../utils/dateUtils'

// ============================================================
// TaskSeries CRUD
// ============================================================

export async function getAllSeries(): Promise<TaskSeries[]> {
  const db = await getDB()
  return db.getAll(STORES.SERIES)
}

export async function getSeriesById(id: string): Promise<TaskSeries | undefined> {
  const db = await getDB()
  return db.get(STORES.SERIES, id)
}

export async function createSeries(
  data: Omit<TaskSeries, 'id' | 'createdAt' | 'updatedAt'>
): Promise<TaskSeries> {
  const db = await getDB()
  const series: TaskSeries = {
    ...data,
    id: generateId(),
    createdAt: nowISO(),
    updatedAt: nowISO(),
  }
  await db.add(STORES.SERIES, series)
  return series
}

export async function updateSeries(
  id: string,
  updates: Partial<Omit<TaskSeries, 'id' | 'createdAt'>>
): Promise<TaskSeries | undefined> {
  const db = await getDB()
  const existing = await db.get(STORES.SERIES, id)
  if (!existing) return undefined

  const updated: TaskSeries = {
    ...existing,
    ...updates,
    id,
    updatedAt: nowISO(),
  }
  await db.put(STORES.SERIES, updated)
  return updated
}

export async function deleteSeries(id: string): Promise<void> {
  const db = await getDB()
  await db.delete(STORES.SERIES, id)
}

export async function getSeriesByCategory(categoryId: string): Promise<TaskSeries[]> {
  const db = await getDB()
  return db.getAllFromIndex(STORES.SERIES, 'by_category', categoryId)
}

// ============================================================
// TaskOccurrence CRUD
// ============================================================

export async function getAllOccurrences(): Promise<TaskOccurrence[]> {
  const db = await getDB()
  return db.getAll(STORES.OCCURRENCES)
}

export async function getOccurrenceById(id: string): Promise<TaskOccurrence | undefined> {
  const db = await getDB()
  return db.get(STORES.OCCURRENCES, id)
}

export async function getOccurrencesBySeries(seriesId: string): Promise<TaskOccurrence[]> {
  const db = await getDB()
  return db.getAllFromIndex(STORES.OCCURRENCES, 'by_series', seriesId)
}

/**
 * Get all occurrences scheduled within a date range.
 * Uses the 'by_scheduled' index for efficient range queries.
 */
export async function getOccurrencesForDateRange(
  start: Date,
  end: Date
): Promise<TaskOccurrence[]> {
  const db = await getDB()
  const range = IDBKeyRange.bound(start.toISOString(), end.toISOString())
  return db.getAllFromIndex(STORES.OCCURRENCES, 'by_scheduled', range)
}

export async function getOccurrencesByStatus(
  status: TaskOccurrence['status']
): Promise<TaskOccurrence[]> {
  const db = await getDB()
  return db.getAllFromIndex(STORES.OCCURRENCES, 'by_status', status)
}

export async function createOccurrence(
  data: Omit<TaskOccurrence, 'id'>
): Promise<TaskOccurrence> {
  const db = await getDB()
  const occurrence: TaskOccurrence = {
    ...data,
    id: generateId(),
  }
  await db.add(STORES.OCCURRENCES, occurrence)
  return occurrence
}

export async function updateOccurrence(
  id: string,
  updates: Partial<Omit<TaskOccurrence, 'id'>>
): Promise<TaskOccurrence | undefined> {
  const db = await getDB()
  const existing = await db.get(STORES.OCCURRENCES, id)
  if (!existing) return undefined

  const updated: TaskOccurrence = { ...existing, ...updates, id }
  await db.put(STORES.OCCURRENCES, updated)
  return updated
}

export async function deleteOccurrence(id: string): Promise<void> {
  const db = await getDB()
  await db.delete(STORES.OCCURRENCES, id)
}

/**
 * Archive an occurrence (move from active to archivedOccurrences store).
 * Used instead of hard-deleting — preserves history.
 */
export async function archiveOccurrence(id: string): Promise<void> {
  const db = await getDB()
  const occurrence = await db.get(STORES.OCCURRENCES, id)
  if (!occurrence) return

  const tx = db.transaction(
    [STORES.OCCURRENCES, STORES.ARCHIVED_OCCURRENCES],
    'readwrite'
  )
  await tx.objectStore(STORES.ARCHIVED_OCCURRENCES).add(occurrence)
  await tx.objectStore(STORES.OCCURRENCES).delete(id)
  await tx.done
}

/**
 * Restore an archived occurrence back to active.
 */
export async function restoreOccurrence(id: string): Promise<void> {
  const db = await getDB()
  const occurrence = await db.get(STORES.ARCHIVED_OCCURRENCES, id)
  if (!occurrence) return

  const tx = db.transaction(
    [STORES.OCCURRENCES, STORES.ARCHIVED_OCCURRENCES],
    'readwrite'
  )
  await tx.objectStore(STORES.OCCURRENCES).add(occurrence)
  await tx.objectStore(STORES.ARCHIVED_OCCURRENCES).delete(id)
  await tx.done
}

export async function getArchivedOccurrences(): Promise<TaskOccurrence[]> {
  const db = await getDB()
  return db.getAll(STORES.ARCHIVED_OCCURRENCES)
}

// ============================================================
// Categories & Tags
// ============================================================

export async function getAllCategories() {
  const db = await getDB()
  return db.getAll(STORES.CATEGORIES)
}

export async function saveCategory(category: import('../types').Category) {
  const db = await getDB()
  await db.put(STORES.CATEGORIES, category)
}

export async function deleteCategory(id: string) {
  const db = await getDB()
  await db.delete(STORES.CATEGORIES, id)
}

export async function getAllTags() {
  const db = await getDB()
  return db.getAll(STORES.TAGS)
}

export async function saveTag(tag: import('../types').Tag) {
  const db = await getDB()
  await db.put(STORES.TAGS, tag)
}

export async function deleteTag(id: string) {
  const db = await getDB()
  await db.delete(STORES.TAGS, id)
}
