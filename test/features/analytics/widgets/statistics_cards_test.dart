import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subtracker/features/analytics/providers/analytics_providers.dart';
import 'package:subtracker/features/analytics/widgets/statistics_cards.dart';
import 'package:subtracker/features/exchange_rates/models/exchange_rate.dart';
import 'package:subtracker/features/exchange_rates/providers/exchange_rate_providers.dart';
import 'package:subtracker/features/settings/providers/user_settings_providers.dart';
import 'package:subtracker/features/subscriptions/models/billing_cycle.dart';
import 'package:subtracker/features/subscriptions/models/subscription.dart';
import 'package:subtracker/features/subscriptions/models/subscription_category.dart';
import 'package:subtracker/features/subscriptions/providers/subscription_providers.dart';

void main() {
  final now = DateTime.now();

  Subscription makeSub({
    required String id,
    required String name,
    required double amount,
    SubscriptionCategory category = SubscriptionCategory.entertainment,
    bool isActive = true,
  }) {
    return Subscription(
      id: id,
      name: name,
      amount: amount,
      currency: 'EUR',
      billingCycle: BillingCycle.monthly,
      category: category,
      isActive: isActive,
      startDate: now.subtract(const Duration(days: 90)),
      nextBillingDate: now.add(const Duration(days: 5)),
      createdAt: now,
      updatedAt: now,
    );
  }

  Widget buildWidget({
    List<Subscription> subscriptions = const [],
    bool useColumn = false,
  }) {
    return ProviderScope(
      overrides: [
        subscriptionsNotifierProvider
            .overrideWith(() => _FakeSubscriptionsNotifier(subscriptions)),
        exchangeRatesNotifierProvider.overrideWith(
          () => _FakeExchangeRatesNotifier(),
        ),
        baseCurrencyProvider.overrideWithValue('EUR'),
        analyticsPeriodProvider.overrideWith(_FakePeriod.new),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StatisticsCards(useColumn: useColumn),
          ),
        ),
      ),
    );
  }

  group('StatisticsCards', () {
    testWidgets('renders all 4 cards with values', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          subscriptions: [
            makeSub(
              id: '1',
              name: 'Netflix',
              amount: 15.99,
              category: SubscriptionCategory.entertainment,
            ),
            makeSub(
              id: '2',
              name: 'Spotify',
              amount: 9.99,
              category: SubscriptionCategory.music,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Monthly Total
      expect(find.text('Monthly Total'), findsOneWidget);
      // Yearly Total
      expect(find.text('Yearly Total'), findsOneWidget);
      // Most Expensive
      expect(find.text('Most Expensive'), findsOneWidget);
      // Top Category
      expect(find.text('Top Category'), findsOneWidget);

      // Should show values (not em dash)
      expect(find.text('\u2014'), findsNothing);
    });

    testWidgets('shows em dash when no subscriptions (empty state)',
        (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // Monthly and Yearly totals should show 0.00
      expect(find.textContaining('0.00'), findsAtLeastNWidgets(2));

      // Most Expensive and Top Category should show em dash
      expect(find.text('\u2014'), findsNWidgets(2));
    });

    testWidgets('renders in column mode when useColumn is true',
        (tester) async {
      await tester.pumpWidget(
        buildWidget(
          subscriptions: [
            makeSub(id: '1', name: 'Netflix', amount: 15.99),
          ],
          useColumn: true,
        ),
      );
      await tester.pumpAndSettle();

      // Should render all 4 labels
      expect(find.text('Monthly Total'), findsOneWidget);
      expect(find.text('Yearly Total'), findsOneWidget);
      expect(find.text('Most Expensive'), findsOneWidget);
      expect(find.text('Top Category'), findsOneWidget);
    });

    testWidgets('renders correct monthly total', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          subscriptions: [
            makeSub(
              id: '1',
              name: 'Netflix',
              amount: 15.99,
              category: SubscriptionCategory.entertainment,
            ),
            makeSub(
              id: '2',
              name: 'Spotify',
              amount: 9.99,
              category: SubscriptionCategory.music,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Total: 15.99 + 9.99 = 25.98
      // Monthly Total and Yearly Total both use this value, so at least one
      expect(find.textContaining('25.98'), findsAtLeastNWidgets(1));
    });

    testWidgets('identifies most expensive subscription', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          subscriptions: [
            makeSub(id: '1', name: 'Netflix', amount: 15.99),
            makeSub(id: '2', name: 'Adobe CC', amount: 54.99),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Adobe CC should appear as most expensive
      expect(find.textContaining('Adobe CC'), findsOneWidget);
    });

    testWidgets('has tooltips on each card', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          subscriptions: [
            makeSub(id: '1', name: 'Netflix', amount: 15.99),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Verify Tooltip widgets exist
      expect(find.byType(Tooltip), findsNWidgets(4));
    });

    testWidgets('ignores inactive subscriptions in stats', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          subscriptions: [
            makeSub(id: '1', name: 'Netflix', amount: 15.99),
            makeSub(
              id: '2',
              name: 'HBO Max',
              amount: 12.99,
              isActive: false,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Monthly total should only be 15.99 (not 28.98)
      expect(find.textContaining('15.99'), findsAtLeastNWidgets(1));
    });
  });
}

class _FakeSubscriptionsNotifier extends SubscriptionsNotifier {
  _FakeSubscriptionsNotifier(this._subscriptions);

  final List<Subscription> _subscriptions;

  @override
  Future<List<Subscription>> build() async => _subscriptions;
}

class _FakeExchangeRatesNotifier extends ExchangeRatesNotifier {
  @override
  Future<ExchangeRate> build() async {
    return const ExchangeRate(
      baseCurrency: 'EUR',
      date: '2026-03-03',
      rates: {},
    );
  }
}

class _FakePeriod extends AnalyticsPeriod {
  @override
  int build() => 6;
}
