import 'package:intl/intl.dart';
import 'package:nepali_utils/nepali_utils.dart';
import 'package:personal_todo/domain/enums.dart';

class BsDateHelper {
  static NepaliDateTime toBs(DateTime ad) => NepaliDateTime.fromDateTime(ad);

  static DateTime toAd(NepaliDateTime bs) => bs.toDateTime();

  static String formatBs(NepaliDateTime bs) {
    return NepaliDateFormat('yyyy MMMM dd').format(bs);
  }

  static String formatTaskDate(
    DateTime ad, {
    required DateDisplayMode mode,
    bool withTime = true,
    bool use24Hour = false,
  }) {
    final bs = toBs(ad);
    final time = DateFormat(use24Hour ? 'HH:mm' : 'h:mm a').format(ad);
    final bsLabel = formatBs(bs);
    final adLabel = DateFormat('d MMM yyyy').format(ad);

    final datePart = switch (mode) {
      DateDisplayMode.bsOnly => bsLabel,
      DateDisplayMode.adOnly => adLabel,
      DateDisplayMode.bsAndAd => '$bsLabel · $adLabel',
    };

    return withTime ? '$datePart · $time' : datePart;
  }

  static String monthTitle(NepaliDateTime bs) =>
      NepaliDateFormat('MMMM yyyy').format(bs);

  static int daysInMonth(int year, int month) {
    final start = NepaliDateTime(year, month, 1).toDateTime();
    final next = month == 12
        ? NepaliDateTime(year + 1, 1, 1).toDateTime()
        : NepaliDateTime(year, month + 1, 1).toDateTime();
    return next.difference(start).inDays;
  }
}
