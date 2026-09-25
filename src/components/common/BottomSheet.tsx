import React, { useEffect } from 'react'
import { useUIStore } from '../../store/uiStore'
import { haptic } from '../../utils/haptics'

interface BottomSheetProps {
  title?: string
  children: React.ReactNode
}

export const BottomSheet: React.FC<BottomSheetProps> = ({ title, children }) => {
  const { bottomSheet, closeSheet } = useUIStore()

  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape') closeSheet()
    }
    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [closeSheet])

  if (!bottomSheet) return null

  return (
    <div className="fixed inset-0 z-50 flex flex-col justify-end">
      {/* Backdrop */}
      <div
        className="fixed inset-0 bg-black/60 backdrop-blur-sm transition-opacity animate-in fade-in"
        onClick={() => {
          haptic.light()
          closeSheet()
        }}
      />

      {/* Sheet panel */}
      <div className="relative w-full max-w-md mx-auto bg-neutral-900 border-t border-neutral-800 rounded-t-3xl shadow-2xl p-5 max-h-[85vh] overflow-y-auto overscroll-contain animate-in slide-in-from-bottom duration-200">
        {/* Drag Handle */}
        <div className="flex justify-center pb-3">
          <div className="w-12 h-1.5 rounded-full bg-neutral-700/80" />
        </div>

        {title && (
          <div className="flex items-center justify-between pb-3 mb-2 border-b border-neutral-800/80">
            <h3 className="text-base font-bold text-neutral-100">{title}</h3>
            <button
              onClick={() => {
                haptic.light()
                closeSheet()
              }}
              className="p-1 rounded-full text-neutral-400 hover:text-neutral-200 hover:bg-neutral-800 transition-colors"
            >
              ✕
            </button>
          </div>
        )}

        {children}
      </div>
    </div>
  )
}
