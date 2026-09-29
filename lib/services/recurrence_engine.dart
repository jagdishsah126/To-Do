import 'package:personal_todo/domain/recurrence.dart';
import 'package:personal_todo/domain/enums.dart';

class RecurrenceEngine {
  const RecurrenceEngine();

  DateTime? nextOccurrence(DateTime from, RecurrenceRule rule) {
    if (!rule.isRecurring) return null;

    switch (rule.type) {
      case RecurrenceType.none:
        return null;
      case RecurrenceType.daily:
        return from.add(Duration(days: rule.interval <= 0 ? 1 : rule.interval));
      case RecurrenceType.weekdays:
        return _nextWeekday(from, const [1, 2, 3, 4, 5]);
      case RecurrenceType.weekly:
        return from.add(Duration(days: 7 * (rule.interval <= 0 ? 1 : rule.interval)));
      case RecurrenceType.selectedWeekdays:
        final days =
            rule.weekdays.isEmpty ? <int>[from.weekday] : List<int>.from(rule.weekdays);
        return _nextWeekday(from, days);
      case RecurrenceType.monthly:
        return _addMonths(from, rule.interval <= 0 ? 1 : rule.interval);
      case RecurrenceType.yearly:
        return DateTime(
          from.year + (rule.interval <= 0 ? 1 : rule.interval),
          from.month,
          from.day,
          from.hour,
          from.minute,
        );
    }
  }

  DateTime _nextWeekday(DateTime from, List<int> weekdays) {
    final sorted = [...weekdays]..sort();
    var cursor = from.add(const Duration(days: 1));
    for (var i = 0; i < 14; i++) {
      if (sorted.contains(cursor.weekday)) {
        return DateTime(
          cursor.year,
          cursor.month,
          cursor.day,
          from.hour,
          from.minute,
        );
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    return from.add(const Duration(days: 1));
  }

  DateTime _addMonths(DateTime from, int months) {
    final totalMonths = from.month - 1 + months;
    final year = from.year + totalMonths ~/ 12;
    final month = totalMonths % 12 + 1;
    final day = from.day.clamp(1, _daysInMonth(year, month));
    return DateTime(year, month, day, from.hour, from.minute);
  }

  int _daysInMonth(int year, int month) => DateTime(year, month + 1, 0).day;
}
