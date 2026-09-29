# Personal Todo — Flutter Mobile App

This repository was reset. The previous **Vite / React / PWA / Capacitor** codebase was removed.

## Current contents

| File | Purpose |
| --- | --- |
| [`Plan.md`](./Plan.md) | Product scope, features, Flutter tech decision |
| [`Process.md`](./Process.md) | How to build it in Flutter (architecture, phases, notifications) |

## Why the reset

PWA reminders were unreliable when the app was closed. The project is now **Flutter, Android-first, offline/local-first**, with native local notifications.

## What is not here yet

There is **no Flutter app source** in this commit yet — only the plan and process docs.

Next step (on a machine/Codespace with enough disk):

```bash
flutter create . --org com.jagdish.todo --project-name personal_todo
# then implement from Process.md
```

Or develop in **GitHub Codespaces** / a remote VM, build an APK, and install it on your Android phone.

## Principles (short)

- Offline first, local SQLite, no account/backend in V1
- AD dates internally, **BS** calendar for display
- Reliable native reminders (not browser notifications)
- Mobile only — no website / PWA target
