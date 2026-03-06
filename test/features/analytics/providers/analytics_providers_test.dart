import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subtracker/features/analytics/providers/analytics_providers.dart';
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
    String currency = 'EUR',
    BillingCycle billingCycle = BillingCycle.monthly,
    SubscriptionCategory category = SubscriptionCategory.entertainment,
    bool isActive = true,
    DateTime? startDate,
    DateTime? nextBillingDate,
  }) {
    return Subscription(
      id: id,
      name: name,
      amount: amount,
      currency: currency,
      billingCycle: billingCycle,
      category: category,
      isActive: isActive,
      startDate: startDate ?? now.subtract(const Duration(days: 90)),
      nextBillingDate: nextBillingDate ?? now.add(const Duration(days: 5)),
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Creates a [ProviderContainer] with the subscriptions notifier already
  /// resolved so that derived providers can read `.valueOrNull` synchronously.
  Future<ProviderContainer> createContainer({
    List<Subscription> subscriptions = const [],
    ExchangeRate? exchangeRate,
    String baseCurrency = 'EUR',
    int period = 6,
  }) async {
    final container = ProviderContainer(
      overrides: [
        subscriptionsNotifierProvider
            .overrideWith(() => _FakeSubscriptionsNotifier(subscriptions)),
        exchangeRatesNotifierProvider.overrideWith(
          () => _FakeExchangeRatesNotifier(exchangeRate),
        ),
        baseCurrencyProvider.overrideWithValue(baseCurrency),
        analyticsPeriodProvider.overrideWith(() => _FakePeriod(period)),
      ],
    );

    // Wait for async notifiers to resolve so .valueOrNull returns data.
    await container.read(subscriptionsNotifierProvider.future);
    await container.read(exchangeRatesNotifierProvider.future);

    return container;
  }

  group('AnalyticsPeriod', () {
    test('default value is 6', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(analyticsPeriodProvider), 6);
    });

    test('setPeriod changes value', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(analyticsPeriodProvider.notifier).setPeriod(3);
      expect(container.read(analyticsPeriodProvider), 3);

      container.read(analyticsPeriodProvider.notifier).setPeriod(12);
      expect(container.read(analyticsPeriodProvider), 12);
    });
  });

  group('spendingByCategory', () {
    test('groups correctly by category', () async {
      final container = await createContainer(
        subscriptions: [
          makeSub(
            id: '1',
            name: 'Netflix',
            amount: 15.99,
            category: SubscriptionCategory.entertainment,
          ),
          makeSub(
            id: '2',
            name: 'Disney+',
            amount: 8.99,
            category: SubscriptionCategory.entertainment,
          ),
          makeSub(
            id: '3',
            name: 'Spotify',
            amount: 9.99,
            category: SubscriptionCategory.music,
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(spendingByCategoryProvider);

      expect(result.length, 2);
      // Entertainment: 15.99 + 8.99 = 24.98
      expect(result[0].category, SubscriptionCategory.entertainment);
      expect(result[0].monthlyAmount, closeTo(24.98, 0.01));
      // Music: 9.99
      expect(result[1].category, SubscriptionCategory.music);
      expect(result[1].monthlyAmount, closeTo(9.99, 0.01));
    });

    test('converts different currencies to base currency', () async {
      final container = await createContainer(
        subscriptions: [
          makeSub(
            id: '1',
            name: 'Netflix',
            amount: 15.99,
            currency: 'USD',
            category: SubscriptionCategory.entertainment,
          ),
          makeSub(
            id: '2',
            name: 'Spotify',
            amount: 9.99,
            category: SubscriptionCategory.music,
          ),
        ],
        exchangeRate: const ExchangeRate(
          baseCurrency: 'EUR',
          date: '2026-03-03',
          rates: {'USD': 1.08, 'GBP': 0.86},
        ),
      );
      addTearDown(container.dispose);

      final result = container.read(spendingByCategoryProvider);

      // Netflix: 15.99 USD -> EUR = 15.99 / 1.08 ~ 14.806
      expect(result.length, 2);
      final entertainment = result.firstWhere(
        (e) => e.category == SubscriptionCategory.entertainment,
      );
      expect(entertainment.monthlyAmount, closeTo(14.806, 0.01));
      final music = result.firstWhere(
        (e) => e.category == SubscriptionCategory.music,
      );
      expect(music.monthlyAmount, closeTo(9.99, 0.01));
    });

    test('sorts by value descending', () async {
      final container = await createContainer(
        subscriptions: [
          makeSub(
            id: '1',
            name: 'Spotify',
            amount: 9.99,
            category: SubscriptionCategory.music,
          ),
          makeSub(
            id: '2',
            name: 'Netflix',
            amount: 15.99,
            category: SubscriptionCategory.entertainment,
          ),
          makeSub(
            id: '3',
            name: 'Gym',
            amount: 29.99,
            category: SubscriptionCategory.fitness,
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(spendingByCategoryProvider);

      expect(result.length, 3);
      expect(result[0].category, SubscriptionCategory.fitness);
      expect(result[1].category, SubscriptionCategory.entertainment);
      expect(result[2].category, SubscriptionCategory.music);
    });

    test('returns empty list when no active subscriptions', () async {
      final container = await createContainer();
      addTearDown(container.dispose);

      final result = container.read(spendingByCategoryProvider);

      expect(result, isEmpty);
    });

    test('ignores inactive subscriptions', () async {
      final container = await createContainer(
        subscriptions: [
          makeSub(
            id: '1',
            name: 'Netflix',
            amount: 15.99,
            category: SubscriptionCategory.entertainment,
          ),
          makeSub(
            id: '2',
            name: 'HBO Max',
            amount: 12.99,
            category: SubscriptionCategory.entertainment,
            isActive: false,
          ),
        ],
      );
      addTearDown(container.dispose);

      final result = container.read(spendingByCategoryProvider);

      expect(result.length, 1);
      expect(result[0].category, SubscriptionCategory.entertainment);
      expect(result[0].monthlyAmount, closeTo(15.99, 0.01));
    });
  });

  group('monthlyTrend', () {
    test('generates correct number of months for period', () async {
      final container = await createContainer(period: 6);
      addTearDown(container.dispose);

      final result = container.read(monthlyTrendProvider);

      expect(result.length, 6);
    });

    test('generates 3 months for period 3', () async {
      final container = await createContainer(period: 3);
      addTearDown(container.dispose);

      final result = container.read(monthlyTrendProvider);

      expect(result.length, 3);
    });

    test('generates 12 months for period 12', () async {
      final container = await createContainer(period: 12);
      addTearDown(container.dispose);

      final result = container.read(monthlyTrendProvider);

      expect(result.length, 12);
    });

    test('last month is the current month', () async {
      final container = await createContainer(period: 6);
      addTearDown(container.dispose);

      final result = container.read(monthlyTrendProvider);

      expect(result.last.month.year, now.year);
      expect(result.last.month.month, now.month);
    });

    test(
      'respects startDate - subscription not counted before it existed',
      () async {
        // Subscription started 2 months ago
        final twoMonthsAgo = DateTime(now.year, now.month - 2, 15);

        final container = await createContainer(
          subscriptions: [
            makeSub(
              id: '1',
              name: 'Netflix',
              amount: 15.99,
              startDate: twoMonthsAgo,
            ),
          ],
          period: 6,
        );
        addTearDown(container.dispose);

        final result = container.read(monthlyTrendProvider);

        // The subscription started mid-way through (now.month - 2).
        // Months before that should be 0, months from that point should
        // have the amount.
        final firstNonZeroIndex = result.indexWhere((m) => m.amount > 0);
        expect(firstNonZeroIndex, greaterThan(0));

        // All months before the subscription started should be 0
        for (var i = 0; i < firstNonZeroIndex; i++) {
          expect(
            result[i].amount,
            0.0,
            reason: 'Month at index $i should be 0',
          );
        }

        // Months from subscription start onward should have the amount
        for (var i = firstNonZeroIndex; i < result.length; i++) {
          expect(
            result[i].amount,
            closeTo(15.99, 0.01),
            reason: 'Month at index $i should have the subscription amount',
          );
        }
      },
    );

    test('converts currencies for monthly trend', () async {
      final container = await createContainer(
        subscriptions: [
          makeSub(
            id: '1',
            name: 'Netflix US',
            amount: 15.99,
            currency: 'USD',
          ),
        ],
        exchangeRate: const ExchangeRate(
          baseCurrency: 'EUR',
          date: '2026-03-03',
          rates: {'USD': 1.08, 'GBP': 0.86},
        ),
        period: 3,
      );
      addTearDown(container.dispose);

      final result = container.read(monthlyTrendProvider);

      // All months should have the converted amount (15.99 / 1.08)
      for (final month in result) {
        expect(month.amount, closeTo(14.806, 0.01));
      }
    });

    test('returns zero amounts when no active subscriptions', () async {
      final container = await createContainer(period: 3);
      addTearDown(container.dispose);

      final result = container.read(monthlyTrendProvider);

      expect(result.length, 3);
      for (final month in result) {
        expect(month.amount, 0.0);
      }
    });
  });

  group('analyticsStats', () {
    test('calculates activeCount and inactiveCount', () async {
      final container = await createContainer(
        subscriptions: [
          makeSub(id: '1', name: 'Netflix', amount: 15.99),
          makeSub(id: '2', name: 'Spotify', amount: 9.99),
          makeSub(
            id: '3',
            name: 'HBO Max',
            amount: 12.99,
            isActive: false,
          ),
        ],
      );
      addTearDown(container.dispose);

      final stats = container.read(analyticsStatsProvider);

      expect(stats.activeCount, 2);
      expect(stats.inactiveCount, 1);
    });

    test('monthlyTotal and yearlyTotal are correct', () async {
      final container = await createContainer(
        subscriptions: [
          makeSub(id: '1', name: 'Netflix', amount: 15.99),
          makeSub(id: '2', name: 'Spotify', amount: 9.99),
        ],
      );
      addTearDown(container.dispose);

      final stats = container.read(analyticsStatsProvider);

      expect(stats.monthlyTotal, closeTo(25.98, 0.01));
      expect(stats.yearlyTotal, closeTo(25.98 * 12, 0.01));
    });

    test('identifies top category', () async {
      final container = await createContainer(
        subscriptions: [
          makeSub(
            id: '1',
            name: 'Netflix',
            amount: 15.99,
            category: SubscriptionCategory.entertainment,
          ),
          makeSub(
            id: '2',
            name: 'Gym',
            amount: 29.99,
            category: SubscriptionCategory.fitness,
          ),
        ],
      );
      addTearDown(container.dispose);

      final stats = container.read(analyticsStatsProvider);

      expect(stats.topCategory, isNotNull);
      expect(stats.topCategory!.category, SubscriptionCategory.fitness);
    });

    test('identifies most expensive subscription', () async {
      final container = await createContainer(
        subscriptions: [
          makeSub(id: '1', name: 'Netflix', amount: 15.99),
          makeSub(id: '2', name: 'Adobe', amount: 54.99),
          makeSub(id: '3', name: 'Spotify', amount: 9.99),
        ],
      );
      addTearDown(container.dispose);

      final stats = container.read(analyticsStatsProvider);

      expect(stats.mostExpensiveSubscription, isNotNull);
      expect(stats.mostExpensiveSubscription!.name, 'Adobe');
      expect(stats.mostExpensiveAmount, closeTo(54.99, 0.01));
    });

    test('calculates average per subscription', () async {
      final container = await createContainer(
        subscriptions: [
          makeSub(id: '1', name: 'Netflix', amount: 15.99),
          makeSub(id: '2', name: 'Spotify', amount: 9.99),
          makeSub(id: '3', name: 'iCloud', amount: 2.99),
        ],
      );
      addTearDown(container.dispose);

      final stats = container.read(analyticsStatsProvider);

      // Average: (15.99 + 9.99 + 2.99) / 3 = 9.6567
      expect(stats.avgPerSubscription, closeTo(9.6567, 0.01));
    });

    test('includes baseCurrency in stats', () async {
      final container = await createContainer(baseCurrency: 'USD');
      addTearDown(container.dispose);

      final stats = container.read(analyticsStatsProvider);

      expect(stats.baseCurrency, 'USD');
    });

    test('edge case: no subscriptions returns zeros and nulls', () async {
      final container = await createContainer();
      addTearDown(container.dispose);

      final stats = container.read(analyticsStatsProvider);

      expect(stats.activeCount, 0);
      expect(stats.inactiveCount, 0);
      expect(stats.monthlyTotal, 0.0);
      expect(stats.yearlyTotal, 0.0);
      expect(stats.avgPerSubscription, 0.0);
      expect(stats.topCategory, isNull);
      expect(stats.mostExpensiveSubscription, isNull);
      expect(stats.mostExpensiveAmount, 0.0);
      expect(stats.nextDue, isNull);
      expect(stats.baseCurrency, 'EUR');
    });

    test('edge case: only inactive subscriptions', () async {
      final container = await createContainer(
        subscriptions: [
          makeSub(
            id: '1',
            name: 'Netflix',
            amount: 15.99,
            isActive: false,
          ),
          makeSub(
            id: '2',
            name: 'Spotify',
            amount: 9.99,
            isActive: false,
          ),
        ],
      );
      addTearDown(container.dispose);

      final stats = container.read(analyticsStatsProvider);

      expect(stats.activeCount, 0);
      expect(stats.inactiveCount, 2);
      expect(stats.monthlyTotal, 0.0);
      expect(stats.yearlyTotal, 0.0);
      expect(stats.avgPerSubscription, 0.0);
      expect(stats.topCategory, isNull);
      expect(stats.mostExpensiveSubscription, isNull);
      expect(stats.nextDue, isNull);
    });

    test('converts currencies for stats calculation', () async {
      final container = await createContainer(
        subscriptions: [
          makeSub(
            id: '1',
            name: 'Netflix US',
            amount: 15.99,
            currency: 'USD',
          ),
          makeSub(id: '2', name: 'Spotify', amount: 9.99),
        ],
        exchangeRate: const ExchangeRate(
          baseCurrency: 'EUR',
          date: '2026-03-03',
          rates: {'USD': 1.08, 'GBP': 0.86},
        ),
      );
      addTearDown(container.dispose);

      final stats = container.read(analyticsStatsProvider);

      // Netflix: 15.99 / 1.08 ~ 14.806, Spotify: 9.99
      // Total ~ 24.796
      expect(stats.monthlyTotal, closeTo(24.796, 0.01));
      expect(stats.yearlyTotal, closeTo(24.796 * 12, 0.1));
    });

    test('nextDue identifies subscription due soonest', () async {
      final container = await createContainer(
        subscriptions: [
          makeSub(
            id: '1',
            name: 'Netflix',
            amount: 15.99,
            nextBillingDate: now.add(const Duration(days: 10)),
          ),
          makeSub(
            id: '2',
            name: 'Spotify',
            amount: 9.99,
            nextBillingDate: now.add(const Duration(days: 2)),
          ),
          makeSub(
            id: '3',
            name: 'iCloud',
            amount: 2.99,
            nextBillingDate: now.add(const Duration(days: 5)),
          ),
        ],
      );
      addTearDown(container.dispose);

      final stats = container.read(analyticsStatsProvider);

      expect(stats.nextDue, isNotNull);
      expect(stats.nextDue!.name, 'Spotify');
    });

    test('handles yearly billing cycle correctly in monthly amount', () async {
      final container = await createContainer(
        subscriptions: [
          makeSub(
            id: '1',
            name: 'Annual Plan',
            amount: 120,
            billingCycle: BillingCycle.yearly,
          ),
        ],
      );
      addTearDown(container.dispose);

      final stats = container.read(analyticsStatsProvider);

      // 120 / 12 = 10.0 monthly
      expect(stats.monthlyTotal, closeTo(10.0, 0.01));
      expect(stats.yearlyTotal, closeTo(120.0, 0.01));
    });
  });
}

/// Fake notifier that returns a pre-set list of subscriptions.
class _FakeSubscriptionsNotifier extends SubscriptionsNotifier {
  _FakeSubscriptionsNotifier(this._subscriptions);

  final List<Subscription> _subscriptions;

  @override
  Future<List<Subscription>> build() async => _subscriptions;
}

/// Fake notifier that returns a pre-set exchange rate (or empty rates).
class _FakeExchangeRatesNotifier extends ExchangeRatesNotifier {
  _FakeExchangeRatesNotifier(this._rate);

  final ExchangeRate? _rate;

  @override
  Future<ExchangeRate> build() async {
    if (_rate != null) return _rate;
    return const ExchangeRate(
      baseCurrency: 'EUR',
      date: '2026-03-03',
      rates: {},
    );
  }
}

/// Fake period notifier with configurable initial value.
class _FakePeriod extends AnalyticsPeriod {
  _FakePeriod(this._initial);

  final int _initial;

  @override
  int build() => _initial;
}
