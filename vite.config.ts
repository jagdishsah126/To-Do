import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import tailwindcss from '@tailwindcss/vite'
import { VitePWA } from 'vite-plugin-pwa'

export default defineConfig({
  plugins: [
    react(),
    tailwindcss(),
    VitePWA({
      registerType: 'autoUpdate',
      devOptions: { enabled: true },
      includeAssets: ['icons/*.png', 'icons/*.svg'],
      manifest: {
        name: 'Zara To-Do',
        short_name: 'Zara',
        description: 'Personal offline-first todo & reminder app with Nepali calendar',
        theme_color: '#6366f1',
        background_color: '#0f0f11',
        display: 'standalone',
        orientation: 'portrait',
        start_url: '/',
        scope: '/',
        lang: 'en',
        icons: [
          {
            src: '/icons/icon-192.png',
            sizes: '192x192',
            type: 'image/png',
          },
          {
            src: '/icons/icon-512.png',
            sizes: '512x512',
            type: 'image/png',
          },
          {
            src: '/icons/icon-512-maskable.png',
            sizes: '512x512',
            type: 'image/png',
            purpose: 'maskable',
          },
        ],
        shortcuts: [
          {
            name: 'Add Task',
            short_name: 'Add',
            description: 'Quickly add a new task',
            url: '/?action=add_task',
            icons: [{ src: '/icons/shortcut-add.png', sizes: '96x96' }],
          },
          {
            name: 'Today',
            short_name: 'Today',
            description: 'View today\'s tasks',
            url: '/?tab=home',
            icons: [{ src: '/icons/shortcut-today.png', sizes: '96x96' }],
          },
        ],
        categories: ['productivity', 'utilities'],
      },
      workbox: {
        // Cache-first for all app assets — pure local app, no network needed
        globPatterns: ['**/*.{js,css,html,ico,png,svg,woff2}'],
        runtimeCaching: [],
        // Don't cache external resources
        navigateFallback: 'index.html',
      },
      // Custom Service Worker with notification handler
      strategies: 'injectManifest',
      srcDir: 'src/sw',
      filename: 'sw.ts',
    }),
  ],
  build: {
    target: 'es2020',
  },
})
