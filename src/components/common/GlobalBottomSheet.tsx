import React from 'react'
import { useUIStore } from '../../store/uiStore'
import { BottomSheet } from './BottomSheet'
import { CreateTaskSheet } from '../tasks/CreateTaskSheet'
import { TaskDetailSheet } from '../tasks/TaskDetailSheet'
import { SnoozeSheet } from '../tasks/SnoozeSheet'

export const GlobalBottomSheet: React.FC = () => {
  const { bottomSheet } = useUIStore()

  if (!bottomSheet) return null

  const getTitle = () => {
    switch (bottomSheet) {
      case 'create_task':
        return 'New Task'
      case 'task_detail':
        return 'Task Details'
      case 'snooze':
        return 'Snooze Task'
      default:
        return undefined
    }
  }

  return (
    <BottomSheet title={getTitle()}>
      {bottomSheet === 'create_task' && <CreateTaskSheet />}
      {bottomSheet === 'task_detail' && <TaskDetailSheet />}
      {bottomSheet === 'snooze' && <SnoozeSheet />}
    </BottomSheet>
  )
}
