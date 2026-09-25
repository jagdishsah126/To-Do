// ============================================================
// Service Worker Bridge
// Bidirectional communication between the React app and Service Worker
// ============================================================

export async function sendSWMessage(message: Record<string, unknown>): Promise<void> {
  if (!('serviceWorker' in navigator)) return

  try {
    const registration = await navigator.serviceWorker.ready
    if (registration.active) {
      registration.active.postMessage(message)
    }
  } catch (err) {
    console.error('[SW Bridge] Failed to send message to SW:', err)
  }
}

/**
 * Register a listener for messages originating from the Service Worker.
 */
export function onSWMessage(
  handler: (data: Record<string, unknown>) => void
): () => void {
  if (!('serviceWorker' in navigator)) return () => {}

  const listener = (event: MessageEvent) => {
    if (event.data && typeof event.data === 'object') {
      handler(event.data)
    }
  }

  navigator.serviceWorker.addEventListener('message', listener)
  return () => {
    navigator.serviceWorker.removeEventListener('message', listener)
  }
}
