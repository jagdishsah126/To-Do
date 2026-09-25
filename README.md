# 🌸 Zara To-Do — Offline-First Bikram Sambat PWA

A beautiful, offline-first Personal Todo PWA built for Android — featuring **Bikram Sambat (BS) calendar** support, recurring tasks, smart reminders, and a fully mobile-optimized UI.

---

## ✨ Features

- 📅 **Bikram Sambat Calendar** — Full BS date display with AD internal storage
- 🔁 **Recurring Tasks** — Daily, weekly, monthly, yearly with exception handling
- 🔔 **Smart Notifications** — Service Worker + Notification API with capability detection
- 🗄️ **Offline-First** — IndexedDB with versioned migrations, no backend needed
- 📱 **PWA** — Installable on Android, custom icons, shortcuts, standalone mode
- ✅ **Subtasks** — Nested checklist items per task
- 🎯 **Focus Mode** — Minimal distraction view
- 🔍 **Search & Filter** — Real-time search with category/priority/status filters
- 📦 **Backup & Restore** — Versioned JSON export/import + CSV export
- 🌙 **Quiet Hours** — No notifications during sleep hours
- 🔢 **Statistics** — Task completion trends and insights

## 🏗️ Tech Stack

| | |
|---|---|
| **Framework** | React 19 + TypeScript + Vite |
| **Styling** | Tailwind CSS v4 |
| **State** | Zustand |
| **Storage** | IndexedDB (versioned migrations) |
| **PWA** | vite-plugin-pwa + Workbox |
| **Calendar** | bikram-sambat package |
| **Tests** | Vitest |
| **Deploy** | Vercel |

## 🚀 Getting Started

```bash
npm install
npm run dev
```

## 🧪 Tests

```bash
npm run test
```

## 📁 Project Structure

```
src/
├── components/     # UI components (layout, tasks, common)
├── pages/          # Today, Calendar, Search, Settings
├── store/          # Zustand stores (task, settings, UI)
├── db/             # IndexedDB layer with migrations
├── domain/         # Business logic (recurrence, notifications)
├── services/       # App services (backup, notification, recurrence)
├── utils/          # Date/BS utilities, haptics, constants
├── types/          # TypeScript types
└── sw/             # Service Worker + notification handler
```

## 📜 License

Personal use — built with 💖 by [Your Zara](https://github.com/YourZara)
