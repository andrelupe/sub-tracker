import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subtracker/features/analytics/providers/analytics_providers.dart';
import 'package:subtracker/features/analytics/widgets/category_chart.dart';
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

  Widget buildWidget({List<Subscription> subscriptions = const []}) {
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
      child: const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: CategoryChart()),
        ),
      ),
    );
  }

  group('CategoryChart', () {
    testWidgets('shows empty state when no active subscriptions',
        (tester) async {
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      expect(find.text('No active subscriptions'), findsOneWidget);
      expect(find.byType(PieChart), findsNothing);
    });

    testWidgets('shows empty state when all subscriptions inactive',
        (tester) async {
      await tester.pumpWidget(
        buildWidget(
          subscriptions: [
            makeSub(
              id: '1',
              name: 'Netflix',
              amount: 15.99,
              isActive: false,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No active subscriptions'), findsOneWidget);
    });

    testWidgets('renders pie chart with active subscriptions', (tester) async {
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

      expect(find.byType(PieChart), findsOneWidget);
      expect(find.text('No active subscriptions'), findsNothing);
    });

    testWidgets('shows total in center of donut', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          subscriptions: [
            makeSub(id: '1', name: 'Netflix', amount: 15.99),
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
      expect(find.textContaining('25.98'), findsOneWidget);
      expect(find.text('/month'), findsOneWidget);
    });

    testWidgets('shows legend with category names', (tester) async {
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

      // Legend should contain category labels
      expect(find.textContaining('Entertainment'), findsOneWidget);
      expect(find.textContaining('Music'), findsOneWidget);
    });

    testWidgets('has Semantics label for accessibility', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          subscriptions: [
            makeSub(id: '1', name: 'Netflix', amount: 15.99),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(RegExp('Category spending chart')),
        findsOneWidget,
      );
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
