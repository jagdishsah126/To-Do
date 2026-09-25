import React, { useState, useEffect } from 'react'

interface CountdownProps {
  scheduledAt: string
  className?: string
}

/**
 * Live countdown/countup timer for a task.
 * Shows time remaining until due, or time overdue.
 * Updates every second.
 */
export const TaskCountdown: React.FC<CountdownProps> = ({ scheduledAt, className = '' }) => {
  const [, setTick] = useState(0)

  // Re-render every second
  useEffect(() => {
    const id = setInterval(() => setTick((t) => t + 1), 1000)
    return () => clearInterval(id)
  }, [])

  const scheduled = new Date(scheduledAt)
  const now = new Date()
  const diffMs = scheduled.getTime() - now.getTime()
  const isOverdue = diffMs < 0
  const absDiffMs = Math.abs(diffMs)

  const totalSeconds = Math.floor(absDiffMs / 1000)
  const hours = Math.floor(totalSeconds / 3600)
  const minutes = Math.floor((totalSeconds % 3600) / 60)
  const seconds = totalSeconds % 60

  // If more than 24h away, don't show countdown (not urgent enough)
  if (diffMs > 24 * 60 * 60 * 1000) return null
  // If overdue by more than 24h, show static "overdue" label instead
  if (diffMs < -24 * 60 * 60 * 1000) return null

  let label: string
  if (hours > 0) {
    label = `${hours}h ${String(minutes).padStart(2, '0')}m`
  } else if (minutes > 0) {
    label = `${minutes}m ${String(seconds).padStart(2, '0')}s`
  } else {
    label = `${String(seconds).padStart(2, '0')}s`
  }

  if (isOverdue) {
    return (
      <span
        className={`inline-flex items-center gap-0.5 text-[10px] font-mono font-semibold text-rose-400 ${className}`}
        title="Overdue by"
      >
        <span className="text-rose-500">+</span>{label}
      </span>
    )
  }

  // Color changes as deadline approaches
  const colorClass =
    totalSeconds < 60
      ? 'text-rose-400 animate-pulse'      // < 1 min: red pulse
      : totalSeconds < 300
      ? 'text-amber-400'                    // < 5 min: amber
      : totalSeconds < 3600
      ? 'text-yellow-300/80'               // < 1h: yellow
      : 'text-neutral-400'                 // > 1h: muted

  return (
    <span
      className={`inline-flex items-center gap-0.5 text-[10px] font-mono ${colorClass} ${className}`}
      title="Time remaining"
    >
      <span className="opacity-60">⏱</span>{label}
    </span>
  )
}
