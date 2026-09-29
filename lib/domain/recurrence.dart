import 'package:personal_todo/domain/enums.dart';

class RecurrenceRule {
  const RecurrenceRule({
    this.type = RecurrenceType.none,
    this.weekdays = const <int>[],
    this.interval = 1,
  });

  final RecurrenceType type;

  /// Dart DateTime.weekday style: 1=Mon ... 7=Sun
  final List<int> weekdays;
  final int interval;

  bool get isRecurring => type != RecurrenceType.none;

  Map<String, Object?> toMap() => {
        'type': type.name,
        'weekdays': weekdays.join(','),
        'interval': interval,
      };

  factory RecurrenceRule.fromMap(Map<String, Object?> map) {
    final rawDays = (map['weekdays'] as String?) ?? '';
    return RecurrenceRule(
      type: RecurrenceType.fromStorage((map['type'] as String?) ?? 'none'),
      weekdays: rawDays.isEmpty
          ? const <int>[]
          : rawDays
              .split(',')
              .map((e) => int.tryParse(e.trim()) ?? 0)
              .where((e) => e >= 1 && e <= 7)
              .toList(),
      interval: (map['interval'] as int?) ?? 1,
    );
  }

  static RecurrenceRule none() => const RecurrenceRule();
}
