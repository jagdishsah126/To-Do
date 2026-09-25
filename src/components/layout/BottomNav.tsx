import React from 'react'
import { useUIStore } from '../../store/uiStore'
import { haptic } from '../../utils/haptics'

export const BottomNav: React.FC = () => {
  const { activeTab, setActiveTab } = useUIStore()

  const tabs = [
    {
      id: 'home' as const,
      label: 'Today',
      icon: (active: boolean) => (
        <svg className={`w-6 h-6 transition-transform ${active ? 'scale-110' : ''}`} fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={active ? 2.5 : 1.8} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4" />
        </svg>
      ),
    },
    {
      id: 'calendar' as const,
      label: 'Calendar',
      icon: (active: boolean) => (
        <svg className={`w-6 h-6 transition-transform ${active ? 'scale-110' : ''}`} fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={active ? 2.5 : 1.8} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
        </svg>
      ),
    },
    {
      id: 'search' as const,
      label: 'Search',
      icon: (active: boolean) => (
        <svg className={`w-6 h-6 transition-transform ${active ? 'scale-110' : ''}`} fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={active ? 2.5 : 1.8} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
        </svg>
      ),
    },
    {
      id: 'settings' as const,
      label: 'Settings',
      icon: (active: boolean) => (
        <svg className={`w-6 h-6 transition-transform ${active ? 'scale-110' : ''}`} fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={active ? 2.5 : 1.8} d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={active ? 2.5 : 1.8} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
        </svg>
      ),
    },
  ]

  const handleTabClick = (tabId: typeof activeTab) => {
    haptic.light()
    setActiveTab(tabId)
  }

  return (
    <nav className="fixed bottom-0 left-0 right-0 z-40 bg-neutral-900/90 backdrop-blur-md border-t border-neutral-800/80 px-2 py-1 safe-area-bottom">
      <div className="max-w-md mx-auto flex items-center justify-around">
        {tabs.map((tab) => {
          const isActive = activeTab === tab.id
          return (
            <button
              key={tab.id}
              onClick={() => handleTabClick(tab.id)}
              className={`flex flex-col items-center justify-center flex-1 py-1.5 select-none transition-colors ${
                isActive ? 'text-indigo-400 font-medium' : 'text-neutral-400 hover:text-neutral-200'
              }`}
            >
              {tab.icon(isActive)}
              <span className="text-[11px] mt-0.5 tracking-tight">{tab.label}</span>
            </button>
          )
        })}
      </div>
    </nav>
  )
}
