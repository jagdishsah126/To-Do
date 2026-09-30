enum TaskStatus {
  upcoming,
  completed,
  skipped,
  snoozed,
  missed,
  cancelled;

  static TaskStatus fromStorage(String value) => TaskStatus.values.firstWhere(
        (e) => e.name == value,
        orElse: () => TaskStatus.upcoming,
      );
}

enum TaskPriority {
  low,
  normal,
  high,
  urgent;

  static TaskPriority fromStorage(String value) =>
      TaskPriority.values.firstWhere(
        (e) => e.name == value,
        orElse: () => TaskPriority.normal,
      );

  String get label => switch (this) {
        TaskPriority.low => 'Low',
        TaskPriority.normal => 'Normal',
        TaskPriority.high => 'High',
        TaskPriority.urgent => 'Urgent',
      };
}

enum RecurrenceType {
  none,
  daily,
  weekdays,
  weekly,
  selectedWeekdays,
  monthly,
  yearly;

  static RecurrenceType fromStorage(String value) =>
      RecurrenceType.values.firstWhere(
        (e) => e.name == value,
        orElse: () => RecurrenceType.none,
      );

  String get label => switch (this) {
        RecurrenceType.none => 'None',
        RecurrenceType.daily => 'Daily',
        RecurrenceType.weekdays => 'Weekdays',
        RecurrenceType.weekly => 'Weekly',
        RecurrenceType.selectedWeekdays => 'Selected weekdays',
        RecurrenceType.monthly => 'Monthly',
        RecurrenceType.yearly => 'Yearly',
      };
}

enum DateDisplayMode {
  bsOnly,
  adOnly,
  bsAndAd;

  static DateDisplayMode fromStorage(String value) =>
      DateDisplayMode.values.firstWhere(
        (e) => e.name == value,
        orElse: () => DateDisplayMode.bsOnly,
      );
}

enum ThemePreference {
  system,
  light,
  dark;

  static ThemePreference fromStorage(String value) =>
      ThemePreference.values.firstWhere(
        (e) => e.name == value,
        orElse: () => ThemePreference.system,
      );
}

enum MissedTaskPolicy {
  markMissed,
  keepOverdue,
  moveTomorrow,
  askUser;

  static MissedTaskPolicy fromStorage(String value) =>
      MissedTaskPolicy.values.firstWhere(
        (e) => e.name == value,
        orElse: () => MissedTaskPolicy.keepOverdue,
      );
}

enum CarryForwardPolicy {
  keepOverdue,
  moveTomorrow,
  markMissed,
  askUser;

  static CarryForwardPolicy fromStorage(String value) =>
      CarryForwardPolicy.values.firstWhere(
        (e) => e.name == value,
        orElse: () => CarryForwardPolicy.keepOverdue,
      );
}
