import React, { useEffect } from 'react'
import { useTaskStore } from './store/taskStore'
import { useSettingsStore } from './store/settingsStore'
import { useUIStore } from './store/uiStore'
import { MobileLayout } from './components/layout/MobileLayout'
import { TodayPage } from './pages/TodayPage'
import { CalendarPage } from './pages/CalendarPage'
import { SearchPage } from './pages/SearchPage'
import { SettingsPage } from './pages/SettingsPage'
import { hydrateOccurrencesForRange } from './services/recurrenceService'
import { syncUpcomingReminders } from './services/notificationService'
import { initNotificationEngine } from './domain/notifications/NotificationScheduler'
import { onSWMessage } from './domain/notifications/ServiceWorkerBridge'
import { handleNotificationAction, type SWActionPayload } from './domain/notifications/NotificationActionHandler'

export const App: React.FC = () => {
  const { loadAll } = useTaskStore()
  const { load: loadSettings } = useSettingsStore()
  const { activeTab, setActiveTab, openSheet } = useUIStore()

  useEffect(() => {
    // Initial data hydration + recurrence window + reminder sync
    const initData = async () => {
      await initNotificationEngine()
      await loadAll()
      await loadSettings()

      const start = new Date()
      start.setDate(start.getDate() - 7)
      const end = new Date()
      end.setDate(end.getDate() + 30)

      const newlyGenerated = await hydrateOccurrencesForRange(start, end)
      if (newlyGenerated.length > 0) {
        await loadAll()
      }

      await syncUpcomingReminders()
    }

    initData()

    // Handle URL parameters for PWA shortcuts & actions
    const params = new URLSearchParams(window.location.search)
    const action = params.get('action')
    const tab = params.get('tab')
    const openOccurrenceId = params.get('open')

    if (action === 'add_task') {
      openSheet('create_task')
    }
    if (tab && ['home', 'calendar', 'search', 'settings'].includes(tab)) {
      setActiveTab(tab as typeof activeTab)
    }
    if (openOccurrenceId) {
      openSheet('task_detail', { occurrenceId: openOccurrenceId })
    }

    // Listen for Service Worker messages (e.g. actions triggered from notifications)
    const unsubscribe = onSWMessage((data) => {
      handleNotificationAction(data as unknown as SWActionPayload)
    })

    return () => {
      unsubscribe()
    }
  }, [loadAll, loadSettings, openSheet, setActiveTab])

  return (
    <MobileLayout>
      {activeTab === 'home' && <TodayPage />}
      {activeTab === 'calendar' && <CalendarPage />}
      {activeTab === 'search' && <SearchPage />}
      {activeTab === 'settings' && <SettingsPage />}
    </MobileLayout>
  )
}

export default App
