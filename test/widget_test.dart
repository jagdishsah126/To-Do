import 'package:flutter_test/flutter_test.dart';
import 'package:personal_todo/services/recurrence_engine.dart';
import 'package:personal_todo/domain/enums.dart';
import 'package:personal_todo/domain/recurrence.dart';

void main() {
  test('daily recurrence advances one day', () {
    const engine = RecurrenceEngine();
    final next = engine.nextOccurrence(
      DateTime(2026, 9, 29, 19),
      const RecurrenceRule(type: RecurrenceType.daily),
    );
    expect(next, DateTime(2026, 9, 30, 19));
  });

  test('weekdays skip weekend', () {
    const engine = RecurrenceEngine();
    // Friday
    final next = engine.nextOccurrence(
      DateTime(2026, 9, 25, 9),
      const RecurrenceRule(type: RecurrenceType.weekdays),
    );
    expect(next!.weekday, DateTime.monday);
  });
}
