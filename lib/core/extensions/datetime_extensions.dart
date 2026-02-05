import 'package:intl/intl.dart';

extension DateTimeX on DateTime {
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  String get formatted => DateFormat('dd MMM yyyy').format(this);

  int get daysFromNow => difference(DateTime.now()).inDays;

  DateTime addMonths(int months) {
    var newMonth = month + months;
    var newYear = year;

    while (newMonth > 12) {
      newMonth -= 12;
      newYear++;
    }

    while (newMonth < 1) {
      newMonth += 12;
      newYear--;
    }

    final maxDay = DateTime(newYear, newMonth + 1, 0).day;
    final newDay = day > maxDay ? maxDay : day;

    return DateTime(newYear, newMonth, newDay, hour, minute, second);
  }

  DateTime addYears(int years) => DateTime(
        year + years,
        month,
        day,
        hour,
        minute,
        second,
      );
}
