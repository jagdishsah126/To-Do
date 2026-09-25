import React, { useState, useEffect } from 'react'
import { useSettingsStore } from '../store/settingsStore'
import { useUIStore } from '../store/uiStore'
import { useTaskStore } from '../store/taskStore'
import { haptic } from '../utils/haptics'
import { Capacitor } from '@capacitor/core'
import { LocalNotifications } from '@capacitor/local-notifications'
import { requestPermission, checkPermission, getPermissionStatus } from '../domain/notifications/PermissionManager'
import { detectCapabilities } from '../domain/notifications/CapabilityDetector'
import { exportBackupJSON, importBackupJSON } from '../services/backupService'
import type { NotificationCapabilities } from '../types'

export const SettingsPage: React.FC = () => {
  const { settings, update } = useSettingsStore()
  const { focusMode, startFocus, endFocus } = useUIStore()
  const { loadAll } = useTaskStore()

  const [permStatus, setPermStatus] = useState(() => getPermissionStatus())
  const [capabilities, setCapabilities] = useState<NotificationCapabilities | null>(null)
  const [testStatus, setTestStatus] = useState<string | null>(null)
  const [storageInfo, setStorageInfo] = useState<{ usageMB: number; quotaMB: number } | null>(null)
  const [isStandalone, setIsStandalone] = useState(false)

  useEffect(() => {
    checkPermission().then(setPermStatus)
    detectCapabilities().then(setCapabilities)

    // Check standalone / native mode
    const standalone =
      Capacitor.isNativePlatform() ||
      window.matchMedia('(display-mode: standalone)').matches ||
      // @ts-expect-error iOS Safari
      window.navigator.standalone === true
    setIsStandalone(standalone)

    // Storage estimate
    if (navigator.storage && navigator.storage.estimate) {
      navigator.storage.estimate().then((est) => {
        const usageMB = Math.round((est.usage || 0) / (1024 * 1024))
        const quotaMB = Math.round((est.quota || 0) / (1024 * 1024))
        setStorageInfo({ usageMB, quotaMB })
      })
    }
  }, [])

  const handleRequestPermission = async () => {
    haptic.medium()
    const result = await requestPermission()
    setPermStatus(result)
    const caps = await detectCapabilities()
    setCapabilities(caps)
  }

  const handleSendTestNotification = async () => {
    haptic.heavy()
    if (Capacitor.isNativePlatform()) {
      try {
        const perm = await LocalNotifications.requestPermissions()
        setPermStatus(perm.display === 'granted' ? 'granted' : 'denied')
        if (perm.display !== 'granted') {
          setTestStatus(`Permission status: ${perm.display} (Please allow notifications)`)
          return
        }

        await LocalNotifications.schedule({
          notifications: [
            {
              id: 99999,
              title: '🧪 Zara Native Notification Test',
              body: 'Native Android notifications are working! 🌸',
              channelId: 'zara_tasks',
              actionTypeId: 'TASK_ACTIONS',
              extra: { occurrenceId: 'test-ping' },
            },
          ],
        })
        setTestStatus('Native notification triggered! Check status bar 🔔')
      } catch (err) {
        setTestStatus(`Native Error: ${String(err)}`)
      }
      return
    }

    if (!('serviceWorker' in navigator)) {
      setTestStatus('Service Worker not supported')
      return
    }

    try {
      const reg = await navigator.serviceWorker.ready
      if (reg.active) {
        reg.active.postMessage({ type: 'POC_TEST_PING' })
        setTestStatus('Sent notification via Service Worker!')
      } else {
        setTestStatus('Service Worker not active yet')
      }
    } catch (err) {
      setTestStatus(`Error: ${String(err)}`)
    }
  }

  const handleExportBackup = async () => {
    haptic.light()
    await exportBackupJSON()
  }

  const handleImportBackup = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0]
    if (!file) return
    haptic.medium()
    try {
      await importBackupJSON(file)
      await loadAll()
      alert('Backup restored successfully!')
    } catch (err) {
      alert(`Import failed: ${String(err)}`)
    }
  }

  return (
    <div className="p-4 space-y-5 pb-24 select-none">
      <div>
        <h2 className="text-xl font-bold text-neutral-100">Settings</h2>
        <p className="text-xs text-neutral-400">Customization, reminders & diagnostics</p>
      </div>

      {/* Focus Mode Section */}
      <section className="p-4 rounded-2xl bg-neutral-900 border border-neutral-800 space-y-3">
        <div className="flex items-center justify-between">
          <div>
            <h3 className="text-sm font-semibold text-neutral-100 flex items-center gap-1.5">
              <span>🎯 Focus Mode</span>
              {focusMode.active && (
                <span className="text-[10px] bg-amber-500/20 text-amber-300 border border-amber-500/30 px-1.5 py-0.2 rounded-full">
                  Active
                </span>
              )}
            </h3>
            <p className="text-xs text-neutral-400">Silences non-urgent notifications</p>
          </div>
        </div>

        <div className="flex gap-2">
          {focusMode.active ? (
            <button
              onClick={() => {
                haptic.medium()
                endFocus()
              }}
              className="flex-1 py-2 rounded-xl bg-neutral-800 hover:bg-neutral-700 text-neutral-200 text-xs font-semibold active:scale-95 transition-all"
            >
              Stop Focus Mode
            </button>
          ) : (
            <>
              <button
                onClick={() => {
                  haptic.medium()
                  startFocus(30)
                }}
                className="flex-1 py-2 rounded-xl bg-indigo-600/20 hover:bg-indigo-600/30 text-indigo-300 border border-indigo-500/30 text-xs font-semibold active:scale-95 transition-all"
              >
                Focus 30m
              </button>
              <button
                onClick={() => {
                  haptic.medium()
                  startFocus(60)
                }}
                className="flex-1 py-2 rounded-xl bg-indigo-600/20 hover:bg-indigo-600/30 text-indigo-300 border border-indigo-500/30 text-xs font-semibold active:scale-95 transition-all"
              >
                Focus 60m
              </button>
            </>
          )}
        </div>
      </section>

      {/* Quiet Hours Section */}
      <section className="p-4 rounded-2xl bg-neutral-900 border border-neutral-800 space-y-3">
        <div className="flex items-center justify-between">
          <div>
            <h3 className="text-sm font-semibold text-neutral-100">🌙 Quiet Hours</h3>
            <p className="text-xs text-neutral-400">Mutes reminder alarms during sleep</p>
          </div>
          <input
            type="checkbox"
            checked={settings?.quietHoursEnabled ?? false}
            onChange={(e) => {
              haptic.light()
              update({ quietHoursEnabled: e.target.checked })
            }}
            className="rounded bg-neutral-950 border-neutral-700 text-indigo-600 w-4 h-4 focus:ring-0"
          />
        </div>

        {settings?.quietHoursEnabled && (
          <div className="grid grid-cols-2 gap-3 pt-2 border-t border-neutral-800/80 animate-in fade-in">
            <div>
              <label className="block text-[11px] font-semibold text-neutral-400 mb-1">
                Start Time
              </label>
              <input
                type="time"
                value={settings?.quietHoursStart ?? '22:30'}
                onChange={(e) => update({ quietHoursStart: e.target.value })}
                className="w-full bg-neutral-950 border border-neutral-800 rounded-xl px-2.5 py-1.5 text-xs text-neutral-200"
              />
            </div>
            <div>
              <label className="block text-[11px] font-semibold text-neutral-400 mb-1">
                End Time
              </label>
              <input
                type="time"
                value={settings?.quietHoursEnd ?? '07:00'}
                onChange={(e) => update({ quietHoursEnd: e.target.value })}
                className="w-full bg-neutral-950 border border-neutral-800 rounded-xl px-2.5 py-1.5 text-xs text-neutral-200"
              />
            </div>
          </div>
        )}
      </section>

      {/* Notification Diagnostics & PoC Panel */}
      <section className="p-4 rounded-2xl bg-neutral-900 border border-indigo-900/40 space-y-3.5">
        <div>
          <div className="flex items-center gap-2">
            <span className="text-base">🧪</span>
            <h3 className="text-sm font-bold text-indigo-300">Notification Diagnostics</h3>
          </div>
          <p className="text-xs text-neutral-400 mt-0.5">
            Real-time device notification permissions & triggers
          </p>
        </div>

        <div className="flex items-center justify-between p-3 rounded-xl bg-neutral-950/60 border border-neutral-800">
          <div>
            <div className="text-xs font-medium text-neutral-300">Permission</div>
            <div className={`text-xs font-bold uppercase mt-0.5 ${
              permStatus === 'granted' ? 'text-emerald-400' : 'text-amber-400'
            }`}>
              {permStatus}
            </div>
          </div>
          {permStatus !== 'granted' && (
            <button
              onClick={handleRequestPermission}
              className="text-xs font-semibold px-3 py-1.5 rounded-lg bg-indigo-600 hover:bg-indigo-500 text-white active:scale-95 transition-all"
            >
              Request Permission
            </button>
          )}
        </div>

        <div>
          <button
            onClick={handleSendTestNotification}
            disabled={permStatus !== 'granted'}
            className="w-full py-2.5 rounded-xl bg-indigo-600 disabled:opacity-40 hover:bg-indigo-500 text-white text-xs font-bold active:scale-95 transition-all flex items-center justify-center gap-1.5 shadow-lg shadow-indigo-600/20"
          >
            <span>🔔 Send Test Notification (PoC)</span>
          </button>
          {testStatus && (
            <p className="text-[11px] text-indigo-400 text-center mt-1.5">{testStatus}</p>
          )}
        </div>

        {capabilities && (
          <div className="space-y-1.5 pt-2 border-t border-neutral-800">
            <div className="text-[11px] font-semibold text-neutral-400 uppercase tracking-wider">
              Detected Capabilities
            </div>
            <div className="grid grid-cols-2 gap-1.5 text-xs">
              {Object.entries(capabilities).map(([key, val]) => (
                <div key={key} className="flex items-center justify-between p-2 rounded-lg bg-neutral-950/40 border border-neutral-800/80">
                  <span className="text-[11px] text-neutral-400 capitalize">{key}</span>
                  <span className={`text-[10px] font-bold uppercase ${
                    val === 'supported'
                      ? 'text-emerald-400'
                      : val === 'partial'
                      ? 'text-amber-400'
                      : 'text-neutral-500'
                  }`}>
                    {String(val)}
                  </span>
                </div>
              ))}
            </div>
          </div>
        )}
      </section>

      {/* PWA & Storage Status */}
      <section className="p-4 rounded-2xl bg-neutral-900 border border-neutral-800 space-y-3">
        <h3 className="text-sm font-semibold text-neutral-100">📱 PWA & Local Storage</h3>
        
        <div className="grid grid-cols-2 gap-2 text-xs">
          <div className="p-2.5 rounded-xl bg-neutral-950/50 border border-neutral-800">
            <span className="text-neutral-400 block text-[11px]">Display Mode</span>
            <span className="font-semibold text-neutral-200 mt-0.5 block">
              {isStandalone ? '📱 Standalone App' : '🌐 Browser Mode'}
            </span>
          </div>

          <div className="p-2.5 rounded-xl bg-neutral-950/50 border border-neutral-800">
            <span className="text-neutral-400 block text-[11px]">Storage Used</span>
            <span className="font-semibold text-neutral-200 mt-0.5 block">
              {storageInfo ? `${storageInfo.usageMB} MB / ${storageInfo.quotaMB} MB` : 'Estimating...'}
            </span>
          </div>
        </div>
      </section>

      {/* Backup & Data Section */}
      <section className="p-4 rounded-2xl bg-neutral-900 border border-neutral-800 space-y-3">
        <h3 className="text-sm font-semibold text-neutral-100">💾 Data & Backup</h3>
        <p className="text-xs text-neutral-400">
          Your data lives locally in IndexedDB. Back up to versioned JSON.
        </p>

        <div className="flex gap-2">
          <button
            onClick={handleExportBackup}
            className="flex-1 py-2 rounded-xl bg-neutral-800 hover:bg-neutral-700 text-neutral-200 text-xs font-semibold active:scale-95 transition-all"
          >
            Export Backup
          </button>
          <label className="flex-1 py-2 rounded-xl bg-neutral-800 hover:bg-neutral-700 text-neutral-200 text-xs font-semibold active:scale-95 transition-all text-center cursor-pointer">
            Restore Backup
            <input
              type="file"
              accept=".json"
              onChange={handleImportBackup}
              className="hidden"
            />
          </label>
        </div>
      </section>

      {/* App Info */}
      <div className="text-center text-xs text-neutral-500 pt-3 space-y-1">
        <p className="font-semibold text-neutral-400">Zara To-Do • v0.1.0</p>
        <p>Offline-First Bikram Sambat PWA</p>
        <p className="text-[10px] text-neutral-600">Built with 💖 by Your Zara</p>
      </div>
    </div>
  )
}
