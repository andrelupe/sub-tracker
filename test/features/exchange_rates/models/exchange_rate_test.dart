import 'package:flutter_test/flutter_test.dart';
import 'package:subtracker/features/exchange_rates/models/exchange_rate.dart';

void main() {
  group('ExchangeRate', () {
    test('fromJson parses correctly', () {
      final json = {
        'base': 'EUR',
        'date': '2026-03-03',
        'rates': {
          'USD': 1.08,
          'GBP': 0.86,
        },
      };

      final rate = ExchangeRate.fromJson(json);

      expect(rate.baseCurrency, equals('EUR'));
      expect(rate.date, equals('2026-03-03'));
      expect(rate.rates, hasLength(2));
      expect(rate.rates['USD'], equals(1.08));
      expect(rate.rates['GBP'], equals(0.86));
    });

    test('toJson serializes correctly', () {
      const rate = ExchangeRate(
        baseCurrency: 'USD',
        date: '2026-03-01',
        rates: {'EUR': 0.92, 'GBP': 0.79},
      );

      final json = rate.toJson();

      expect(json['base'], equals('USD'));
      expect(json['date'], equals('2026-03-01'));
      expect((json['rates'] as Map)['EUR'], equals(0.92));
      expect((json['rates'] as Map)['GBP'], equals(0.79));
    });

    test('fromJson handles integer rates', () {
      final json = {
        'base': 'GBP',
        'date': '2026-03-03',
        'rates': {
          'EUR': 1,
          'USD': 1,
        },
      };

      final rate = ExchangeRate.fromJson(json);

      expect(rate.rates['EUR'], isA<double>());
      expect(rate.rates['EUR'], equals(1.0));
    });

    test('roundtrip fromJson/toJson preserves data', () {
      final original = {
        'base': 'EUR',
        'date': '2026-03-03',
        'rates': {'USD': 1.08, 'GBP': 0.86},
      };

      final rate = ExchangeRate.fromJson(original);
      final serialized = rate.toJson();

      expect(serialized['base'], equals(original['base']));
      expect(serialized['date'], equals(original['date']));
      expect(
        (serialized['rates'] as Map)['USD'],
        equals((original['rates'] as Map)['USD']),
      );
    });
  });
}
