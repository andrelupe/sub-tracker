// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$spendingByCategoryHash() =>
    r'62ff4b461f17f7808028221f6e32d2d3c72d9e01';

/// Spending breakdown by category for active subscriptions.
///
/// Sums each category's monthly amount (converted to base currency)
/// and returns a descending-sorted list.
///
/// Copied from [spendingByCategory].
@ProviderFor(spendingByCategory)
final spendingByCategoryProvider =
    AutoDisposeProvider<List<CategorySpending>>.internal(
  spendingByCategory,
  name: r'spendingByCategoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$spendingByCategoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef SpendingByCategoryRef = AutoDisposeProviderRef<List<CategorySpending>>;
String _$monthlyTrendHash() => r'd108c88218ea68b1261d44b0935493664a91f1df';

/// Monthly spending trend for the selected period.
///
/// For each month (from `period - 1` months ago to the current month),
/// sums the monthly amount of active subscriptions whose [startDate]
/// is before the end of that month, converted to base currency.
///
/// Copied from [monthlyTrend].
@ProviderFor(monthlyTrend)
final monthlyTrendProvider =
    AutoDisposeProvider<List<MonthlySpending>>.internal(
  monthlyTrend,
  name: r'monthlyTrendProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$monthlyTrendHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef MonthlyTrendRef = AutoDisposeProviderRef<List<MonthlySpending>>;
String _$analyticsStatsHash() => r'b70e4c2e708afb91627f3d62cbbc89992d1d4bc9';

/// Aggregated analytics statistics.
///
/// Copied from [analyticsStats].
@ProviderFor(analyticsStats)
final analyticsStatsProvider = AutoDisposeProvider<AnalyticsStats>.internal(
  analyticsStats,
  name: r'analyticsStatsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$analyticsStatsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef AnalyticsStatsRef = AutoDisposeProviderRef<AnalyticsStats>;
String _$analyticsPeriodHash() => r'e37c1f1674004ef2e07bdbcf81b6ff840b648c46';

/// Selected analytics period in months (3, 6, or 12).
///
/// Copied from [AnalyticsPeriod].
@ProviderFor(AnalyticsPeriod)
final analyticsPeriodProvider =
    AutoDisposeNotifierProvider<AnalyticsPeriod, int>.internal(
  AnalyticsPeriod.new,
  name: r'analyticsPeriodProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$analyticsPeriodHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AnalyticsPeriod = AutoDisposeNotifier<int>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
