// ============================================================
// Notification Capability Detector
//
// Phase 0 PoC: Detect what this platform actually supports.
// Results are stored in localStorage for the Settings screen.
// ============================================================

import type { NotificationCapabilities, CapabilityState } from '../../types'

const STORAGE_KEY = 'zara-notification-capabilities'

/** Run capability detection and persist results */
export async function detectCapabilities(): Promise<NotificationCapabilities> {
  const caps: NotificationCapabilities = {
    permission: checkPermissionAPI(),
    display: checkNotificationDisplay(),
    actions: checkNotificationActions(),
    backgroundScheduling: 'unknown',     // can only be tested on a real device
    lockedScreen: 'unknown',             // can only be tested on a real device
    afterRestart: 'unknown',             // can only be tested on a real device
    offline: checkOfflineCapability(),
  }

  localStorage.setItem(STORAGE_KEY, JSON.stringify(caps))
  return caps
}

export function getStoredCapabilities(): NotificationCapabilities | null {
  const stored = localStorage.getItem(STORAGE_KEY)
  if (!stored) return null
  try {
    return JSON.parse(stored) as NotificationCapabilities
  } catch {
    return null
  }
}

export function updateCapability(
  key: keyof NotificationCapabilities,
  state: CapabilityState
): void {
  const current = getStoredCapabilities() ?? {}
  const updated = { ...current, [key]: state }
  localStorage.setItem(STORAGE_KEY, JSON.stringify(updated))
}

// ------------------------------------------------------------
// Individual checks
// ------------------------------------------------------------

function checkPermissionAPI(): CapabilityState {
  if (!('Notification' in window)) return 'unsupported'
  return 'supported'
}

function checkNotificationDisplay(): CapabilityState {
  if (!('Notification' in window)) return 'unsupported'
  if (!('serviceWorker' in navigator)) return 'partial'  // no SW = no background
  return 'supported'
}

function checkNotificationActions(): CapabilityState {
  // Notification actions require Service Worker + platform support
  // Chrome Android supports them; iOS Safari historically does not
  if (!('ServiceWorkerRegistration' in window)) return 'unsupported'
  const notif = Notification as unknown as { maxActions?: number }
  if (typeof notif.maxActions !== 'number') return 'unknown'
  if (notif.maxActions >= 1) return 'supported'
  return 'unsupported'
}

function checkOfflineCapability(): CapabilityState {
  // If SW is supported, notifications can fire offline (SW is the scheduler)
  if ('serviceWorker' in navigator) return 'supported'
  return 'unsupported'
}
