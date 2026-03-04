import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subtracker/features/settings/models/user_settings.dart';
import 'package:subtracker/features/settings/providers/user_settings_providers.dart';
import 'package:subtracker/features/settings/widgets/currency_selector.dart';

void main() {
  group('CurrencySelector', () {
    testWidgets('displays all supported currencies', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userSettingsNotifierProvider.overrideWith(
              () => _FakeUserSettingsNotifier(),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: CurrencySelector()),
          ),
        ),
      );

      // Wait for async data to load
      await tester.pumpAndSettle();

      // All three currencies should appear as text
      expect(find.text('\u20AC EUR'), findsOneWidget);
      expect(find.text('\$ USD'), findsOneWidget);
      expect(find.text('\u00A3 GBP'), findsOneWidget);
    });

    testWidgets('displays section title', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userSettingsNotifierProvider.overrideWith(
              () => _FakeUserSettingsNotifier(),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: CurrencySelector()),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Currency'), findsOneWidget);
      expect(find.text('Base Currency'), findsOneWidget);
    });

    testWidgets('shows loading state', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userSettingsNotifierProvider.overrideWith(
              () => _LoadingUserSettingsNotifier(),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(body: CurrencySelector()),
          ),
        ),
      );

      // Pump a single frame — the provider should still be loading
      await tester.pump();

      // In loading state, the widget shows a constrained SizedBox with
      // a loading indicator inside. Verify the loading text or absence
      // of currency labels.
      expect(find.text('\u20AC EUR'), findsNothing);
      expect(find.text('\$ USD'), findsNothing);
      expect(find.text('\u00A3 GBP'), findsNothing);
    });
  });
}

/// Fake notifier that immediately returns EUR settings.
class _FakeUserSettingsNotifier extends UserSettingsNotifier {
  @override
  Future<UserSettings> build() async {
    return UserSettings(
      baseCurrency: 'EUR',
      updatedAt: DateTime.utc(2026, 3, 3),
    );
  }

  @override
  Future<void> updateBaseCurrency(String currency) async {
    state = AsyncData(UserSettings(
      baseCurrency: currency,
      updatedAt: DateTime.now(),
    ));
  }
}

/// Fake notifier that never completes (stays in loading state).
class _LoadingUserSettingsNotifier extends UserSettingsNotifier {
  @override
  Future<UserSettings> build() {
    // Never completes — keeps the provider in loading state
    return Future.delayed(const Duration(days: 1));
  }
}
