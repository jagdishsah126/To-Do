// ============================================================
// Permission Manager
// Handles requesting, checking, and tracking notification permission.
// Supports both Capacitor Native Android and Web fallback.
// ============================================================

import { Capacitor } from '@capacitor/core'
import { LocalNotifications } from '@capacitor/local-notifications'

export type PermissionStatus = 'granted' | 'denied' | 'default' | 'unsupported'

let cachedStatus: PermissionStatus = 'default'

export function getPermissionStatus(): PermissionStatus {
  if (Capacitor.isNativePlatform()) {
    return cachedStatus
  }
  if (typeof window === 'undefined' || !('Notification' in window)) return 'unsupported'
  return Notification.permission as PermissionStatus
}

/**
 * Check permission status asynchronously (crucial for native platforms).
 */
export async function checkPermission(): Promise<PermissionStatus> {
  if (Capacitor.isNativePlatform()) {
    try {
      const status = await LocalNotifications.checkPermissions()
      cachedStatus = status.display === 'granted' ? 'granted' : status.display === 'denied' ? 'denied' : 'default'
      return cachedStatus
    } catch {
      return 'unsupported'
    }
  }

  if (typeof window === 'undefined' || !('Notification' in window)) return 'unsupported'
  cachedStatus = Notification.permission as PermissionStatus
  return cachedStatus
}

/**
 * Request notification permission.
 * Returns the resulting status.
 */
export async function requestPermission(): Promise<PermissionStatus> {
  if (Capacitor.isNativePlatform()) {
    try {
      const result = await LocalNotifications.requestPermissions()
      cachedStatus = result.display === 'granted' ? 'granted' : result.display === 'denied' ? 'denied' : 'default'
      return cachedStatus
    } catch {
      return 'unsupported'
    }
  }

  if (typeof window === 'undefined' || !('Notification' in window)) return 'unsupported'
  if (Notification.permission === 'granted') return 'granted'
  if (Notification.permission === 'denied') return 'denied'

  try {
    const result = await Notification.requestPermission()
    cachedStatus = result as PermissionStatus
    return cachedStatus
  } catch {
    return new Promise((resolve) => {
      Notification.requestPermission((result) => {
        cachedStatus = result as PermissionStatus
        resolve(cachedStatus)
      })
    })
  }
}

export function isGranted(): boolean {
  if (Capacitor.isNativePlatform()) {
    return cachedStatus === 'granted'
  }
  return getPermissionStatus() === 'granted'
}

export function isDenied(): boolean {
  if (Capacitor.isNativePlatform()) {
    return cachedStatus === 'denied'
  }
  return getPermissionStatus() === 'denied'
}
