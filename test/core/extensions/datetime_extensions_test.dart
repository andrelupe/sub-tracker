import 'package:flutter_test/flutter_test.dart';
import 'package:subtracker/core/extensions/datetime_extensions.dart';

void main() {
  group('DateTimeX', () {
    test('isToday returns true for today', () {
      expect(DateTime.now().isToday, isTrue);
    });

    test('isToday returns false for yesterday', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(yesterday.isToday, isFalse);
    });

    test('addMonths handles normal case', () {
      final date = DateTime(2024, 1, 15);
      final result = date.addMonths(3);

      expect(result.year, equals(2024));
      expect(result.month, equals(4));
      expect(result.day, equals(15));
    });

    test('addMonths handles year overflow', () {
      final date = DateTime(2024, 11, 15);
      final result = date.addMonths(3);

      expect(result.year, equals(2025));
      expect(result.month, equals(2));
      expect(result.day, equals(15));
    });

    test('addMonths handles month-end overflow', () {
      final date = DateTime(2024, 1, 31);
      final result = date.addMonths(1);

      // February doesn't have 31 days
      expect(result.year, equals(2024));
      expect(result.month, equals(2));
      expect(result.day, equals(29)); // 2024 is a leap year
    });

    test('addYears works correctly', () {
      final date = DateTime(2024, 6, 15);
      final result = date.addYears(2);

      expect(result.year, equals(2026));
      expect(result.month, equals(6));
      expect(result.day, equals(15));
    });

    test('daysFromNow calculates correctly', () {
      final future = DateTime.now().add(const Duration(days: 5));
      // Allow for slight timing differences (4-5 days depending on time of day)
      expect(future.daysFromNow, greaterThanOrEqualTo(4));
      expect(future.daysFromNow, lessThanOrEqualTo(5));
    });

    test('formatted returns correct format', () {
      final date = DateTime(2024, 1, 15);
      expect(date.formatted, equals('15 Jan 2024'));
    });
  });
}
