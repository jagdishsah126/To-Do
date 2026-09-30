import 'package:personal_todo/domain/enums.dart';

class AppSettings {
  const AppSettings({
    this.theme = ThemePreference.system,
    this.dateDisplay = DateDisplayMode.bsOnly,
    this.defaultReminderMinutes = 0,
    this.notificationsEnabled = true,
    this.snoozeMinutes = const [5, 10, 15, 30, 60],
    this.quietHoursEnabled = false,
    this.quietStartMinute = 22 * 60 + 30,
    this.quietEndMinute = 7 * 60,
    this.missedPolicy = MissedTaskPolicy.keepOverdue,
    this.use24HourClock = false,
    this.accentColor = 0xFF00D4AA,
  });

  final ThemePreference theme;
  final DateDisplayMode dateDisplay;
  final int defaultReminderMinutes;
  final bool notificationsEnabled;
  final List<int> snoozeMinutes;
  final bool quietHoursEnabled;
  final int quietStartMinute;
  final int quietEndMinute;
  final MissedTaskPolicy missedPolicy;
  final bool use24HourClock;
  final int accentColor;

  AppSettings copyWith({
    ThemePreference? theme,
    DateDisplayMode? dateDisplay,
    int? defaultReminderMinutes,
    bool? notificationsEnabled,
    List<int>? snoozeMinutes,
    bool? quietHoursEnabled,
    int? quietStartMinute,
    int? quietEndMinute,
    MissedTaskPolicy? missedPolicy,
    bool? use24HourClock,
    int? accentColor,
  }) {
    return AppSettings(
      theme: theme ?? this.theme,
      dateDisplay: dateDisplay ?? this.dateDisplay,
      defaultReminderMinutes:
          defaultReminderMinutes ?? this.defaultReminderMinutes,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      snoozeMinutes: snoozeMinutes ?? this.snoozeMinutes,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietStartMinute: quietStartMinute ?? this.quietStartMinute,
      quietEndMinute: quietEndMinute ?? this.quietEndMinute,
      missedPolicy: missedPolicy ?? this.missedPolicy,
      use24HourClock: use24HourClock ?? this.use24HourClock,
      accentColor: accentColor ?? this.accentColor,
    );
  }

  Map<String, String> toStorageMap() => {
        'theme': theme.name,
        'dateDisplay': dateDisplay.name,
        'defaultReminderMinutes': '$defaultReminderMinutes',
        'notificationsEnabled': '$notificationsEnabled',
        'snoozeMinutes': snoozeMinutes.join(','),
        'quietHoursEnabled': '$quietHoursEnabled',
        'quietStartMinute': '$quietStartMinute',
        'quietEndMinute': '$quietEndMinute',
        'missedPolicy': missedPolicy.name,
        'use24HourClock': '$use24HourClock',
        'accentColor': '$accentColor',
      };

  factory AppSettings.fromStorageMap(Map<String, String> map) {
    return AppSettings(
      theme: ThemePreference.fromStorage(map['theme'] ?? 'system'),
      dateDisplay: DateDisplayMode.fromStorage(map['dateDisplay'] ?? 'bsOnly'),
      defaultReminderMinutes:
          int.tryParse(map['defaultReminderMinutes'] ?? '0') ?? 0,
      notificationsEnabled: (map['notificationsEnabled'] ?? 'true') == 'true',
      snoozeMinutes: (map['snoozeMinutes'] ?? '5,10,15,30,60')
          .split(',')
          .map((e) => int.tryParse(e) ?? 0)
          .where((e) => e > 0 && e <= 1440)
          .toList(),
      quietHoursEnabled: (map['quietHoursEnabled'] ?? 'false') == 'true',
      quietStartMinute: int.tryParse(map['quietStartMinute'] ?? '1350') ?? 1350,
      quietEndMinute: int.tryParse(map['quietEndMinute'] ?? '420') ?? 420,
      missedPolicy:
          MissedTaskPolicy.fromStorage(map['missedPolicy'] ?? 'keepOverdue'),
      use24HourClock: (map['use24HourClock'] ?? 'false') == 'true',
      accentColor: int.tryParse(map['accentColor'] ?? '0xFF00D4AA') ?? 0xFF00D4AA,
    );
  }
}
