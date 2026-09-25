// ============================================================
// Service Worker — Main Entry Point
// This file is the compiled SW served as /sw.js
// It imports Workbox manifest (injected by vite-plugin-pwa)
// and our notification handler.
// ============================================================

/// <reference lib="webworker" />
import { cleanupOutdatedCaches, precacheAndRoute } from 'workbox-precaching'

declare let self: ServiceWorkerGlobalScope & {
  __WB_MANIFEST: Array<{ url: string; revision: string | null }>
}

cleanupOutdatedCaches()
precacheAndRoute(self.__WB_MANIFEST)

// Import notification event handlers
import './notificationHandler'

// Activate immediately — skip waiting
self.addEventListener('install', () => {
  self.skipWaiting()
})

self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim())
})
