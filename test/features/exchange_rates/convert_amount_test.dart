import 'package:flutter_test/flutter_test.dart';
import 'package:subtracker/features/exchange_rates/convert_amount.dart';

void main() {
  group('convertAmount', () {
    // Rates as if base is EUR: 1 EUR = 1.08 USD, 1 EUR = 0.86 GBP
    const rates = {
      'USD': 1.08,
      'GBP': 0.86,
    };

    test('same currency returns unchanged amount', () {
      final result = convertAmount(
        amount: 10.0,
        fromCurrency: 'EUR',
        toCurrency: 'EUR',
        ratesBaseCurrency: 'EUR',
        rates: rates,
      );

      expect(result, equals(10.0));
    });

    test('converts from base to target', () {
      final result = convertAmount(
        amount: 100.0,
        fromCurrency: 'EUR',
        toCurrency: 'USD',
        ratesBaseCurrency: 'EUR',
        rates: rates,
      );

      expect(result, closeTo(108.0, 0.01));
    });

    test('converts from target to base', () {
      final result = convertAmount(
        amount: 108.0,
        fromCurrency: 'USD',
        toCurrency: 'EUR',
        ratesBaseCurrency: 'EUR',
        rates: rates,
      );

      expect(result, closeTo(100.0, 0.01));
    });

    test('cross conversion between non-base currencies', () {
      // 100 USD -> EUR -> GBP
      // 100 / 1.08 * 0.86 = ~79.63
      final result = convertAmount(
        amount: 100.0,
        fromCurrency: 'USD',
        toCurrency: 'GBP',
        ratesBaseCurrency: 'EUR',
        rates: rates,
      );

      expect(result, closeTo(79.63, 0.01));
    });

    test('returns amount unchanged when fromCurrency rate not found', () {
      final result = convertAmount(
        amount: 50.0,
        fromCurrency: 'JPY',
        toCurrency: 'EUR',
        ratesBaseCurrency: 'EUR',
        rates: rates,
      );

      expect(result, equals(50.0));
    });

    test('returns amount unchanged when toCurrency rate not found', () {
      final result = convertAmount(
        amount: 50.0,
        fromCurrency: 'EUR',
        toCurrency: 'JPY',
        ratesBaseCurrency: 'EUR',
        rates: rates,
      );

      expect(result, equals(50.0));
    });

    test('handles zero amount', () {
      final result = convertAmount(
        amount: 0.0,
        fromCurrency: 'EUR',
        toCurrency: 'USD',
        ratesBaseCurrency: 'EUR',
        rates: rates,
      );

      expect(result, equals(0.0));
    });

    test('handles empty rates map', () {
      final result = convertAmount(
        amount: 100.0,
        fromCurrency: 'EUR',
        toCurrency: 'USD',
        ratesBaseCurrency: 'EUR',
        rates: const {},
      );

      // Falls back to returning the original amount
      expect(result, equals(100.0));
    });
  });
}
