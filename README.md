# Personal Todo — Flutter Mobile App

Offline-first personal todo & reminder app for Android.

## Features in this build (v1.1)

* Today / Upcoming / BS Calendar tabs
* Create, edit, delete tasks
* Complete / Skip / Snooze / Reschedule
* Priority + categories
* Recurrence: daily, weekdays, weekly, selected weekdays, monthly, yearly
* Local SQLite storage
* BS date display (AD stored internally)
* Scheduled local notifications + lock-screen support
* Notification actions: Complete / Snooze / Skip
* Quiet hours + missed-task policy
* Theme / date display / reminder defaults
* Search
* Export / import JSON backup

## Build in Codespace

```bash
cd /workspaces/To-Do
git pull origin main
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools
flutter pub get
flutter build apk --debug
```

APK: `build/app/outputs/flutter-apk/app-debug.apk`

## Docs

* [`Plan.md`](./Plan.md) — product scope
* [`Process.md`](./Process.md) — Flutter implementation process
