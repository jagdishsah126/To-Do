import React, { useState, useEffect } from 'react'
import { haptic } from '../../utils/haptics'

interface BeforeInstallPromptEvent extends Event {
  prompt: () => Promise<void>
  userChoice: Promise<{ outcome: 'accepted' | 'dismissed' }>
}

export const PWAInstallPrompt: React.FC = () => {
  const [deferredPrompt, setDeferredPrompt] = useState<BeforeInstallPromptEvent | null>(null)
  const [isVisible, setIsVisible] = useState(false)

  useEffect(() => {
    // Check if already in standalone mode
    const isStandalone =
      window.matchMedia('(display-mode: standalone)').matches ||
      // @ts-expect-error iOS Safari navigator.standalone
      window.navigator.standalone === true

    if (isStandalone) return

    const handleBeforeInstall = (e: Event) => {
      e.preventDefault()
      setDeferredPrompt(e as BeforeInstallPromptEvent)
      // Show install prompt if not previously dismissed in this session
      const dismissed = sessionStorage.getItem('pwa_install_dismissed')
      if (!dismissed) {
        setIsVisible(true)
      }
    }

    window.addEventListener('beforeinstallprompt', handleBeforeInstall)
    return () => window.removeEventListener('beforeinstallprompt', handleBeforeInstall)
  }, [])

  const handleInstallClick = async () => {
    if (!deferredPrompt) return
    haptic.medium()
    setIsVisible(false)
    await deferredPrompt.prompt()
    const { outcome } = await deferredPrompt.userChoice
    if (outcome === 'accepted') {
      console.log('[PWA] User accepted install prompt')
    }
    setDeferredPrompt(null)
  }

  const handleDismiss = () => {
    haptic.light()
    setIsVisible(false)
    sessionStorage.setItem('pwa_install_dismissed', 'true')
  }

  if (!isVisible || !deferredPrompt) return null

  return (
    <div className="fixed top-3 left-3 right-3 z-50 max-w-md mx-auto animate-in fade-in slide-in-from-top-3 duration-200">
      <div className="bg-neutral-900/95 border border-indigo-500/40 rounded-2xl p-3.5 shadow-2xl backdrop-blur-md flex items-center justify-between gap-3">
        <div className="flex items-center gap-3 min-w-0">
          <img
            src="/icons/icon-192.png"
            alt="Zara App"
            className="w-10 h-10 rounded-xl shadow-md flex-shrink-0"
          />
          <div className="min-w-0">
            <h4 className="text-xs font-bold text-neutral-100 truncate">Install Zara To-Do</h4>
            <p className="text-[11px] text-neutral-400 truncate">
              Install for instant offline access & notifications
            </p>
          </div>
        </div>

        <div className="flex items-center gap-1.5 flex-shrink-0">
          <button
            onClick={handleInstallClick}
            className="px-3 py-1.5 rounded-xl bg-indigo-600 hover:bg-indigo-500 text-white text-xs font-bold shadow-md shadow-indigo-600/30 active:scale-95 transition-all"
          >
            Install
          </button>
          <button
            onClick={handleDismiss}
            className="p-1.5 text-neutral-500 hover:text-neutral-300 transition-colors"
            aria-label="Dismiss"
          >
            ✕
          </button>
        </div>
      </div>
    </div>
  )
}
