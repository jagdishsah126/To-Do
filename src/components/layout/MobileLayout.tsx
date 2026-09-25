import React from 'react'
import { TopHeader } from './TopHeader'
import { BottomNav } from './BottomNav'
import { UndoToast } from '../common/UndoToast'
import { GlobalBottomSheet } from '../common/GlobalBottomSheet'
import { PWAInstallPrompt } from '../common/PWAInstallPrompt'

interface MobileLayoutProps {
  children: React.ReactNode
}

export const MobileLayout: React.FC<MobileLayoutProps> = ({ children }) => {
  return (
    <div className="relative w-full h-full max-w-md mx-auto bg-neutral-950 flex flex-col overflow-hidden shadow-2xl border-x border-neutral-900/60">
      <PWAInstallPrompt />
      <TopHeader />
      <main className="flex-1 overflow-y-auto overscroll-contain scroll-container">
        {children}
      </main>
      <UndoToast />
      <GlobalBottomSheet />
      <BottomNav />
    </div>
  )
}
