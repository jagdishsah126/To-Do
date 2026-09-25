// ============================================================
// Service Worker — Notification Handler
//
// This file is compiled separately as a Service Worker.
// It handles: notification display, notification click,
// notification action buttons (Complete / Snooze / Skip).
//
// Phase 0: PoC — test that this works on real Android device.
// ============================================================

/// <reference lib="webworker" />

declare const self: ServiceWorkerGlobalScope

// ---- Notification Click ----

self.addEventListener('notificationclick', (event: NotificationEvent) => {
  const notification = event.notification
  const action = event.action
  const data = notification.data ?? {}

  notification.close()

  if (action === 'complete') {
    // Send message to all clients to complete this occurrence
    event.waitUntil(
      notifyClients({ type: 'COMPLETE_OCCURRENCE', occurrenceId: data.occurrenceId })
    )
  } else if (action === 'snooze') {
    // Snooze for 15 minutes by default from notification action
    event.waitUntil(
      notifyClients({
        type: 'SNOOZE_OCCURRENCE',
        occurrenceId: data.occurrenceId,
        minutes: 15,
      })
    )
  } else if (action === 'skip') {
    event.waitUntil(
      notifyClients({ type: 'SKIP_OCCURRENCE', occurrenceId: data.occurrenceId })
    )
  } else {
    // Default click — open / focus the app
    event.waitUntil(
      focusOrOpenApp(data.occurrenceId)
    )
  }
})

// ---- Notification Close ----

self.addEventListener('notificationclose', (event: NotificationEvent) => {
  const data = event.notification.data ?? {}
  // Log dismissal — could be used for analytics later
  console.log('[SW] Notification dismissed:', data.occurrenceId)
})

// ---- Message from app ----

self.addEventListener('message', (event: ExtendableMessageEvent) => {
  const { type } = event.data ?? {}

  if (type === 'SHOW_NOTIFICATION') {
    const { title, body, occurrenceId, tag } = event.data
    event.waitUntil(
      self.registration.showNotification(title, {
        body,
        tag: tag ?? occurrenceId,
        icon: '/icons/icon-192.png',
        badge: '/icons/badge-72.png',
        data: { occurrenceId },
        actions: [
          { action: 'complete', title: '✅ Complete' },
          { action: 'snooze', title: '💤 Snooze 15m' },
          { action: 'skip', title: '⏭ Skip' },
        ],
        requireInteraction: false,
        silent: false,
      } as unknown as NotificationOptions)
    )
  }

  if (type === 'CANCEL_NOTIFICATION') {
    const { tag } = event.data
    event.waitUntil(
      self.registration.getNotifications({ tag }).then((notifications) => {
        notifications.forEach((n) => n.close())
      })
    )
  }

  // Phase 0 PoC test ping
  if (type === 'POC_TEST_PING') {
    event.waitUntil(
      self.registration.showNotification('🧪 Zara Notification PoC', {
        body: 'If you see this, Service Worker notifications work!',
        icon: '/icons/icon-192.png',
        tag: 'poc-test',
        data: { occurrenceId: 'poc-test' },
        actions: [
          { action: 'complete', title: '✅ Works!' },
          { action: 'snooze', title: '💤 Snooze Test' },
        ],
      } as unknown as NotificationOptions)
    )
  }
})

// ---- Helpers ----

async function notifyClients(message: Record<string, unknown>): Promise<void> {
  const clients = await self.clients.matchAll({ type: 'window' })
  for (const client of clients) {
    client.postMessage(message)
  }
}

async function focusOrOpenApp(occurrenceId?: string): Promise<void> {
  const clients = await self.clients.matchAll({
    type: 'window',
    includeUncontrolled: true,
  })

  for (const client of clients) {
    if ('focus' in client) {
      await (client as WindowClient).focus()
      client.postMessage({ type: 'OPEN_OCCURRENCE', occurrenceId })
      return
    }
  }

  // No existing window — open app
  await self.clients.openWindow(`/?open=${occurrenceId ?? ''}`)
}
