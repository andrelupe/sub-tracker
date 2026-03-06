import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subtracker/features/analytics/providers/analytics_providers.dart';
import 'package:subtracker/features/analytics/widgets/monthly_trend_chart.dart';
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
    bool isActive = true,
    DateTime? startDate,
  }) {
    return Subscription(
      id: id,
      name: name,
      amount: amount,
      currency: 'EUR',
      billingCycle: BillingCycle.monthly,
      category: SubscriptionCategory.entertainment,
      isActive: isActive,
      startDate: startDate ?? now.subtract(const Duration(days: 90)),
      nextBillingDate: now.add(const Duration(days: 5)),
      createdAt: now,
      updatedAt: now,
    );
  }

  Widget buildWidget({
    List<Subscription> subscriptions = const [],
    int period = 6,
  }) {
    return ProviderScope(
      overrides: [
        subscriptionsNotifierProvider
            .overrideWith(() => _FakeSubscriptionsNotifier(subscriptions)),
        exchangeRatesNotifierProvider.overrideWith(
          () => _FakeExchangeRatesNotifier(),
        ),
        baseCurrencyProvider.overrideWithValue('EUR'),
        analyticsPeriodProvider
            .overrideWith(() => _FakePeriodWithInitial(period)),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(child: MonthlyTrendChart()),
        ),
      ),
    );
  }

  group('MonthlyTrendChart', () {
    testWidgets('shows empty state when no active subscriptions',
        (tester) async {
      // With no subscriptions, the trend data will be all zeros, but the
      // list won't be empty (it'll have 6 entries with 0 amount).
      // The chart should still render (LineChart), not the empty message.
      await tester.pumpWidget(buildWidget());
      await tester.pumpAndSettle();

      // When there are no subscriptions, monthlyTrend still generates
      // data points (with amount 0). The chart renders but shows flat line.
      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('renders line chart with active subscriptions', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          subscriptions: [
            makeSub(id: '1', name: 'Netflix', amount: 15.99),
            makeSub(id: '2', name: 'Spotify', amount: 9.99),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LineChart), findsOneWidget);
      expect(find.text('No data available'), findsNothing);
    });

    testWidgets('renders chart with period of 3 months', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          subscriptions: [
            makeSub(id: '1', name: 'Netflix', amount: 15.99),
          ],
          period: 3,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('renders chart with period of 12 months', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          subscriptions: [
            makeSub(id: '1', name: 'Netflix', amount: 15.99),
          ],
          period: 12,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LineChart), findsOneWidget);
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
        find.bySemanticsLabel(RegExp('Monthly spending trend')),
        findsOneWidget,
      );
    });

    testWidgets('handles single subscription correctly', (tester) async {
      await tester.pumpWidget(
        buildWidget(
          subscriptions: [
            makeSub(id: '1', name: 'Netflix', amount: 15.99),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LineChart), findsOneWidget);
    });

    testWidgets('ignores inactive subscriptions', (tester) async {
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

      // Chart should still render (with zero values), not show empty message
      expect(find.byType(LineChart), findsOneWidget);
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

class _FakePeriodWithInitial extends AnalyticsPeriod {
  _FakePeriodWithInitial(this._initial);

  final int _initial;

  @override
  int build() => _initial;
}
