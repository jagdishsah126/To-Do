# Notification Capabilities & Fallback Strategy

> **Project:** Zara To-Do (Personal Todo PWA)
> **Target:** Mobile Android Chrome (PWA)
> **Architecture:** Offline-First, Local Notifications (Service Worker + Notification API)

---

## 📊 Capability Matrix

| Feature | Status | Android Chrome PWA | iOS Safari PWA | Desktop Browsers | Fallback Strategy |
|---|---|---|---|---|---|
| **Notification Permission Request** | ✅ Guaranteed | Supported | Supported (iOS 16.4+) | Supported | Explain value before browser dialog; if denied, show toggle in Settings |
| **Notification Display** | ✅ Guaranteed | Supported via SW | Supported via SW (Web Push required on iOS) | Supported | In-app notification toast / banner if Notification API is unavailable |
| **Notification Click (Open/Focus App)** | ✅ Guaranteed | Supported via `clients.matchAll()` / `openWindow()` | Supported | Supported | Direct link to `/?open={occurrenceId}` |
| **Notification Actions (Complete / Snooze / Skip)** | ⚠️ Platform Dependent | Supported (up to 3 actions in Android notification shade) | ❌ Not supported in Safari | Supported on Chrome/Edge | Standard UI buttons in-app for complete/snooze/skip; notification tap opens task detail |
| **Background Alarm Scheduling** | ⚠️ Platform Dependent | Service Worker timer / Periodic Sync / Web Alarms (limited precision) | ❌ Suspended when closed | ⚠️ Browser process dependent | On app foreground / wake, compute and notify overdue or due tasks; schedule next 24h reminders |
| **Locked Screen Actions** | ⚠️ Device Dependent | Supported on modern Android with notifications enabled on lock screen | ❌ Tap only | N/A | Respect Android OS lock screen settings; provide full action suite inside app on unlock |
| **Offline Notifications** | ✅ Supported | Supported (Service Worker runs locally without internet) | Partial | Supported | All assets cached via Workbox cache-first; IndexedDB queried locally |
| **After Device Restart** | ⚠️ OS Dependent | SW wakes on next app launch or notification event | Requires user to open app | Depends on autostart | On app launch, query IndexedDB for missed tasks and fire catch-up notification if configured |

---

## 🛡️ Non-Guaranteed Capabilities & Fallbacks

### 1. What happens if the phone is restarted or killed by Android battery manager?
- **Reality:** Aggressive battery savers (MIUI, OneUI, ColorOS) might terminate the Service Worker background process.
- **Fallback:** 
  1. The app detects when it was reopened.
  2. The `taskStore` checks for occurrences whose `scheduledAt < now` and status is still `upcoming`.
  3. Depending on user settings (`missedTaskBehavior`):
     - Mark as `missed` or keep `overdue` with a red warning badge.
     - Present an immediate "Missed Tasks" catch-up banner.

### 2. What happens if notification actions (Complete/Snooze/Skip) aren't rendered by the OS?
- **Reality:** Some OEM notification shades or iOS do not display action buttons.
- **Fallback:** 
  - Clicking the notification body directly opens the app to `/?open={occurrenceId}`, immediately displaying the `TaskDetailSheet` with large, one-tap Complete, Snooze, and Skip buttons.
