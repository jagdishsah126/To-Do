// ============================================================
// Haptics Utility
// Wraps navigator.vibrate with graceful fallback.
// Does nothing silently on platforms that don't support it.
// ============================================================

const canVibrate = (): boolean =>
  typeof navigator !== 'undefined' && 'vibrate' in navigator

const vibrate = (pattern: number | number[]): void => {
  if (canVibrate()) {
    try {
      navigator.vibrate(pattern)
    } catch {
      // Silently ignore — some browsers throw on vibrate
    }
  }
}

export const haptic = {
  /** Very short tap — UI feedback */
  light: () => vibrate(10),

  /** Medium tap — confirmations */
  medium: () => vibrate(20),

  /** Strong tap — important actions */
  heavy: () => vibrate([30, 10, 30]),

  /** Success pattern — task completed */
  success: () => vibrate([15, 30, 60]),

  /** Error pattern — invalid action */
  error: () => vibrate([50, 30, 50, 30, 50]),

  /** Swipe completion */
  swipeComplete: () => vibrate([10, 20, 40]),
}
