import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:subtracker/features/analytics/models/analytics_data.dart';
import 'package:subtracker/features/exchange_rates/convert_amount.dart';
import 'package:subtracker/features/exchange_rates/models/exchange_rate.dart';
import 'package:subtracker/features/exchange_rates/providers/exchange_rate_providers.dart';
import 'package:subtracker/features/settings/providers/user_settings_providers.dart';
import 'package:subtracker/features/subscriptions/models/subscription.dart';
import 'package:subtracker/features/subscriptions/models/subscription_category.dart';
import 'package:subtracker/features/subscriptions/providers/subscription_providers.dart';

part 'analytics_providers.g.dart';

/// Selected analytics period in months (3, 6, or 12).
@riverpod
class AnalyticsPeriod extends _$AnalyticsPeriod {
  @override
  int build() => 6;

  // ignore: use_setters_to_change_properties
  void setPeriod(int months) => state = months;
}

/// Converts a monthly amount to the user's base currency.
double _convert(
  double amount,
  String fromCurrency,
  String baseCurrency,
  ExchangeRate? rates,
) {
  if (rates == null || fromCurrency == baseCurrency) return amount;
  return convertAmount(
    amount: amount,
    fromCurrency: fromCurrency,
    toCurrency: baseCurrency,
    ratesBaseCurrency: rates.baseCurrency,
    rates: rates.rates,
  );
}

/// Spending breakdown by category for active subscriptions.
///
/// Sums each category's monthly amount (converted to base currency)
/// and returns a descending-sorted list.
@riverpod
List<CategorySpending> spendingByCategory(SpendingByCategoryRef ref) {
  final subscriptions =
      ref.watch(subscriptionsNotifierProvider).valueOrNull ?? [];
  final rates = ref.watch(exchangeRatesNotifierProvider).valueOrNull;
  final baseCurrency = ref.watch(baseCurrencyProvider);

  final active = subscriptions.where((s) => s.isActive).toList();

  final totals = <SubscriptionCategory, double>{};
  for (final sub in active) {
    final converted = _convert(
      sub.monthlyAmount,
      sub.currency,
      baseCurrency,
      rates,
    );
    totals.update(
      sub.category,
      (v) => v + converted,
      ifAbsent: () => converted,
    );
  }

  return totals.entries
      .map((e) => CategorySpending(category: e.key, monthlyAmount: e.value))
      .toList()
    ..sort((a, b) => b.monthlyAmount.compareTo(a.monthlyAmount));
}

/// Monthly spending trend for the selected period.
///
/// For each month (from `period - 1` months ago to the current month),
/// sums the monthly amount of active subscriptions whose `startDate`
/// is before the end of that month, converted to base currency.
@riverpod
List<MonthlySpending> monthlyTrend(MonthlyTrendRef ref) {
  final subscriptions =
      ref.watch(subscriptionsNotifierProvider).valueOrNull ?? [];
  final rates = ref.watch(exchangeRatesNotifierProvider).valueOrNull;
  final baseCurrency = ref.watch(baseCurrencyProvider);
  final period = ref.watch(analyticsPeriodProvider);

  final active = subscriptions.where((s) => s.isActive).toList();
  final now = DateTime.now();
  final months = <MonthlySpending>[];

  for (var i = period - 1; i >= 0; i--) {
    final month = DateTime(now.year, now.month - i);
    final endOfMonth = DateTime(month.year, month.month + 1, 0);
    var total = 0.0;

    for (final sub in active) {
      // Include subscription if it started before the end of this month
      if (sub.startDate.isBefore(endOfMonth) ||
          sub.startDate.isAtSameMomentAs(endOfMonth)) {
        total += _convert(
          sub.monthlyAmount,
          sub.currency,
          baseCurrency,
          rates,
        );
      }
    }

    months.add(MonthlySpending(month: month, amount: total));
  }

  return months;
}

/// Aggregated analytics statistics.
@riverpod
AnalyticsStats analyticsStats(AnalyticsStatsRef ref) {
  final subscriptions =
      ref.watch(subscriptionsNotifierProvider).valueOrNull ?? [];
  final rates = ref.watch(exchangeRatesNotifierProvider).valueOrNull;
  final baseCurrency = ref.watch(baseCurrencyProvider);
  final categorySpending = ref.watch(spendingByCategoryProvider);

  final active = subscriptions.where((s) => s.isActive).toList();
  final inactive = subscriptions.where((s) => !s.isActive).toList();

  // Monthly total (converted)
  var monthlyTotal = 0.0;
  for (final sub in active) {
    monthlyTotal += _convert(
      sub.monthlyAmount,
      sub.currency,
      baseCurrency,
      rates,
    );
  }

  // Top category
  final topCategory =
      categorySpending.isNotEmpty ? categorySpending.first : null;

  // Most expensive subscription (by converted monthly amount)
  Subscription? mostExpensive;
  var highestAmount = 0.0;
  for (final sub in active) {
    final converted = _convert(
      sub.monthlyAmount,
      sub.currency,
      baseCurrency,
      rates,
    );
    if (converted > highestAmount) {
      highestAmount = converted;
      mostExpensive = sub;
    }
  }

  // Average per subscription
  final avgPerSubscription =
      active.isNotEmpty ? monthlyTotal / active.length : 0.0;

  // Next due subscription (earliest positive daysUntilNextBilling)
  final dueSoon = active.where((s) => s.daysUntilNextBilling >= 0).toList()
    ..sort(
      (a, b) => a.daysUntilNextBilling.compareTo(b.daysUntilNextBilling),
    );

  return AnalyticsStats(
    activeCount: active.length,
    inactiveCount: inactive.length,
    monthlyTotal: monthlyTotal,
    yearlyTotal: monthlyTotal * 12,
    avgPerSubscription: avgPerSubscription,
    topCategory: topCategory,
    mostExpensiveSubscription: mostExpensive,
    mostExpensiveAmount: highestAmount,
    nextDue: dueSoon.isNotEmpty ? dueSoon.first : null,
    baseCurrency: baseCurrency,
  );
}
