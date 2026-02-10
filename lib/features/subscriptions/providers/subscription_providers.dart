import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:subtracker/core/providers/api_providers.dart';
import 'package:subtracker/features/subscriptions/models/billing_cycle.dart';
import 'package:subtracker/features/subscriptions/models/sort_option.dart';
import 'package:subtracker/features/subscriptions/models/subscription.dart';
import 'package:subtracker/features/subscriptions/models/subscription_category.dart';

part 'subscription_providers.g.dart';

/// Main async notifier for subscriptions
@Riverpod(keepAlive: true)
class SubscriptionsNotifier extends _$SubscriptionsNotifier {
  @override
  Future<List<Subscription>> build() async {
    final apiService = ref.read(subscriptionApiServiceProvider);
    final subscriptions = await apiService.getAllSubscriptions();
    return subscriptions
      ..sort((a, b) => a.nextBillingDate.compareTo(b.nextBillingDate));
  }

  Future<void> create({
    required String name,
    String? description,
    required double amount,
    required String currency,
    required BillingCycle billingCycle,
    required SubscriptionCategory category,
    required DateTime startDate,
    String? url,
    int reminderDaysBefore = 2,
  }) async {
    final apiService = ref.read(subscriptionApiServiceProvider);

    await apiService.createSubscription(
      name: name,
      description: description,
      amount: amount,
      currency: currency,
      billingCycle: billingCycle,
      category: category,
      startDate: startDate,
      url: url,
      reminderDaysBefore: reminderDaysBefore,
    );

    ref.invalidateSelf();
  }

  Future<void> updateSubscription(Subscription subscription) async {
    final apiService = ref.read(subscriptionApiServiceProvider);

    await apiService.updateSubscription(
      id: subscription.id,
      name: subscription.name,
      description: subscription.description,
      amount: subscription.amount,
      currency: subscription.currency,
      billingCycle: subscription.billingCycle,
      category: subscription.category,
      startDate: subscription.startDate,
      url: subscription.url,
      reminderDaysBefore: subscription.reminderDaysBefore,
      isActive: subscription.isActive,
    );

    ref.invalidateSelf();
  }

  Future<void> delete(String id) async {
    final apiService = ref.read(subscriptionApiServiceProvider);
    await apiService.deleteSubscription(id);
    ref.invalidateSelf();
  }

  Future<void> toggleActive(String id) async {
    final apiService = ref.read(subscriptionApiServiceProvider);

    // Get current subscription
    final current = state.valueOrNull ?? [];
    final subscription = current.firstWhere((s) => s.id == id);

    await apiService.toggleSubscriptionStatus(id, !subscription.isActive);
    ref.invalidateSelf();
  }
}

// Simple derived providers
@riverpod
List<Subscription> subscriptionsList(SubscriptionsListRef ref) {
  final asyncSubs = ref.watch(subscriptionsNotifierProvider);
  final showInactive = ref.watch(showInactiveProvider);
  return asyncSubs.when(
    data: (subs) => showInactive
        ? subs.where((s) => !s.isActive).toList()
        : subs.where((s) => s.isActive).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
}

@riverpod
double monthlyTotal(MonthlyTotalRef ref) {
  final asyncSubs = ref.watch(subscriptionsNotifierProvider);
  return asyncSubs.when(
    data: (allSubs) {
      final active = allSubs.where((s) => s.isActive);
      return active.fold(0.0, (sum, sub) => sum + sub.monthlyAmount);
    },
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
}

@riverpod
double yearlyTotal(YearlyTotalRef ref) {
  final asyncSubs = ref.watch(subscriptionsNotifierProvider);
  return asyncSubs.when(
    data: (allSubs) {
      final active = allSubs.where((s) => s.isActive);
      return active.fold(0.0, (sum, sub) => sum + sub.yearlyAmount);
    },
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
}

@riverpod
List<Subscription> dueSoonSubscriptions(DueSoonSubscriptionsRef ref) {
  final asyncSubs = ref.watch(subscriptionsNotifierProvider);
  return asyncSubs.when(
    data: (allSubs) {
      final active = allSubs.where((s) => s.isActive);
      return active.where((sub) => sub.isDueSoon).toList();
    },
    loading: () => <Subscription>[],
    error: (_, __) => <Subscription>[],
  );
}

@riverpod
Subscription? subscriptionById(SubscriptionByIdRef ref, String id) {
  final asyncSubs = ref.watch(subscriptionsNotifierProvider);
  return asyncSubs.when(
    data: (subs) {
      try {
        return subs.firstWhere((s) => s.id == id);
      } catch (_) {
        return null;
      }
    },
    loading: () => null,
    error: (_, __) => null,
  );
}

// Filter providers
@riverpod
class ShowInactive extends _$ShowInactive {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

@riverpod
class SearchQuery extends _$SearchQuery {
  @override
  String build() => '';

  void update(String query) => state = query;
  void clear() => state = '';
}

@riverpod
class CategoryFilter extends _$CategoryFilter {
  @override
  SubscriptionCategory? build() => null;

  void select(SubscriptionCategory? category) => state = category;
  void clear() => state = null;
}

@riverpod
class SortBy extends _$SortBy {
  @override
  SortOption build() => SortOption.nextBillingDate;

  void select(SortOption option) => state = option;
}

@riverpod
class SortAscending extends _$SortAscending {
  @override
  bool build() => true;

  void toggle() => state = !state;
  void set(bool ascending) => state = ascending;
}

// Filtered subscriptions
@riverpod
List<Subscription> filteredSubscriptions(FilteredSubscriptionsRef ref) {
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();
  final categoryFilter = ref.watch(categoryFilterProvider);
  final sortBy = ref.watch(sortByProvider);
  final sortAscending = ref.watch(sortAscendingProvider);
  final subscriptions = ref.watch(subscriptionsListProvider);

  var result = subscriptions.where((sub) {
    if (query.isNotEmpty) {
      final nameMatch = sub.name.toLowerCase().contains(query);
      final descriptionMatch =
          sub.description?.toLowerCase().contains(query) ?? false;
      final categoryMatch = sub.category.label.toLowerCase().contains(query);
      if (!nameMatch && !descriptionMatch && !categoryMatch) {
        return false;
      }
    }
    return true;
  }).toList();

  if (categoryFilter != null) {
    result = result.where((sub) => sub.category == categoryFilter).toList();
  }

  result.sort((a, b) {
    int comparison;
    switch (sortBy) {
      case SortOption.nextBillingDate:
        comparison = a.nextBillingDate.compareTo(b.nextBillingDate);
      case SortOption.name:
        comparison = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      case SortOption.amount:
        comparison = a.monthlyAmount.compareTo(b.monthlyAmount);
      case SortOption.category:
        comparison = a.category.label.compareTo(b.category.label);
    }
    return sortAscending ? comparison : -comparison;
  });

  return result;
}

@riverpod
bool hasActiveFilters(HasActiveFiltersRef ref) {
  final query = ref.watch(searchQueryProvider);
  final category = ref.watch(categoryFilterProvider);
  final sortBy = ref.watch(sortByProvider);
  final sortAscending = ref.watch(sortAscendingProvider);
  final showInactive = ref.watch(showInactiveProvider);

  return query.isNotEmpty ||
      category != null ||
      sortBy != SortOption.nextBillingDate ||
      !sortAscending ||
      showInactive;
}
