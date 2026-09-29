# Personal Todo — Flutter Mobile App

This repository was reset. The previous **Vite / React / PWA / Capacitor** codebase was removed.

## Current contents

| File | Purpose |
| --- | --- |
| [`Plan.md`](./Plan.md) | Product scope, features, Flutter tech decision |
| [`Process.md`](./Process.md) | How to build it in Flutter (architecture, phases, notifications) |

## Why the reset

PWA reminders were unreliable when the app was closed. The project is now **Flutter, Android-first, offline/local-first**, with native local notifications.

## Current app (V0.2)

Flutter Android app with:

* Today screen
* Add task (title, description, date, time)
* Complete / uncomplete
* Swipe to delete
* Local SQLite storage (survives app restart)
* Local scheduled notifications at task time
* Bell icon → test notification in 10 seconds

Not yet: BS calendar, recurrence, settings, notification actions.

### Build in Codespace

```bash
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools
flutter pub get
flutter build apk --debug
```

APK: `build/app/outputs/flutter-apk/app-debug.apk`

## Principles (short)

- Offline first, local SQLite, no account/backend in V1
- AD dates internally, **BS** calendar for display
- Reliable native reminders (not browser notifications)
- Mobile only — no website / PWA target
