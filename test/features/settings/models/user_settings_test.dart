import 'package:flutter_test/flutter_test.dart';
import 'package:subtracker/features/settings/models/user_settings.dart';

void main() {
  group('UserSettings', () {
    test('fromJson parses correctly', () {
      final json = {
        'baseCurrency': 'USD',
        'updatedAt': '2026-03-03T12:00:00Z',
      };

      final settings = UserSettings.fromJson(json);

      expect(settings.baseCurrency, equals('USD'));
      expect(settings.updatedAt, isA<DateTime>());
    });

    test('toJson serializes correctly', () {
      final settings = UserSettings(
        baseCurrency: 'GBP',
        updatedAt: DateTime.utc(2026, 3, 3, 12),
      );

      final json = settings.toJson();

      expect(json['baseCurrency'], equals('GBP'));
      expect(json['updatedAt'], contains('2026-03-03'));
    });

    test('supportedCurrencies contains EUR, USD, GBP', () {
      expect(UserSettings.supportedCurrencies, contains('EUR'));
      expect(UserSettings.supportedCurrencies, contains('USD'));
      expect(UserSettings.supportedCurrencies, contains('GBP'));
      expect(UserSettings.supportedCurrencies, hasLength(3));
    });

    test('currencySymbol returns correct symbols', () {
      expect(UserSettings.currencySymbol('EUR'), equals('\u20AC'));
      expect(UserSettings.currencySymbol('USD'), equals('\$'));
      expect(UserSettings.currencySymbol('GBP'), equals('\u00A3'));
    });

    test('currencySymbol returns code for unknown currency', () {
      expect(UserSettings.currencySymbol('JPY'), equals('JPY'));
    });

    test('currencySymbol is case insensitive', () {
      expect(UserSettings.currencySymbol('eur'), equals('\u20AC'));
      expect(UserSettings.currencySymbol('usd'), equals('\$'));
    });
  });
}
