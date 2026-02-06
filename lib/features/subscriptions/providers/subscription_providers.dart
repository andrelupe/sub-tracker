import 'package:hive_flutter/hive_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:subtracker/core/storage/hive_storage_service.dart';
import 'package:subtracker/features/subscriptions/models/billing_cycle.dart';
import 'package:subtracker/features/subscriptions/models/sort_option.dart';
import 'package:subtracker/features/subscriptions/models/subscription.dart';
import 'package:subtracker/features/subscriptions/models/subscription_category.dart';
import 'package:uuid/uuid.dart';

part 'subscription_providers.g.dart';

const _uuid = Uuid();

Box<Subscription> get _box => HiveStorageService.subscriptionsBox;

/// Main provider that holds the list of all subscriptions.
/// This is the single source of truth - all other providers derive from this.
@Riverpod(keepAlive: true)
class SubscriptionsNotifier extends _$SubscriptionsNotifier {
  @override
  List<Subscription> build() {
    final data = _loadFromStorage();
    // ignore: avoid_print
    print(
        'SubscriptionsNotifier: Loaded ${data.length} subscriptions from storage');
    return data;
  }

  List<Subscription> _loadFromStorage() {
    final list = _box.values.toList()
      ..sort((a, b) => a.nextBillingDate.compareTo(b.nextBillingDate));
    return list;
  }

  void create({
    required String name,
    String? description,
    required double amount,
    required String currency,
    required BillingCycle billingCycle,
    required SubscriptionCategory category,
    required DateTime startDate,
    String? url,
  }) {
    final subscription = Subscription(
      id: _uuid.v4(),
      name: name,
      description: description,
      amount: amount,
      currency: currency,
      billingCycle: billingCycle,
      category: category,
      startDate: startDate,
      nextBillingDate: billingCycle.nextBillingDate(startDate),
      url: url,
    );

    _box.put(subscription.id, subscription);
    state = _loadFromStorage();
  }

  void update(Subscription subscription) {
    _box.put(subscription.id, subscription);
    state = _loadFromStorage();
  }

  void delete(String id) {
    _box.delete(id);
    state = _loadFromStorage();
  }

  void toggleActive(String id) {
    final sub = _box.get(id);
    if (sub != null) {
      final updated = sub.copyWith(isActive: !sub.isActive);
      _box.put(id, updated);
      state = _loadFromStorage();
    }
  }
}

@riverpod
List<Subscription> subscriptionsList(SubscriptionsListRef ref) {
  final all = ref.watch(subscriptionsNotifierProvider);
  return all.where((s) => s.isActive).toList();
}

@riverpod
double monthlyTotal(MonthlyTotalRef ref) {
  final active = ref.watch(subscriptionsListProvider);
  return active.fold(0, (sum, sub) => sum + sub.monthlyAmount);
}

@riverpod
double yearlyTotal(YearlyTotalRef ref) {
  final active = ref.watch(subscriptionsListProvider);
  return active.fold(0, (sum, sub) => sum + sub.yearlyAmount);
}

@riverpod
List<Subscription> dueSoonSubscriptions(DueSoonSubscriptionsRef ref) {
  final active = ref.watch(subscriptionsListProvider);
  return active.where((sub) => sub.isDueSoon).toList();
}

@riverpod
Subscription? subscriptionById(SubscriptionByIdRef ref, String id) {
  final all = ref.watch(subscriptionsNotifierProvider);
  try {
    return all.firstWhere((s) => s.id == id);
  } catch (_) {
    return null;
  }
}

/// Provider for the search query state.
@riverpod
class SearchQuery extends _$SearchQuery {
  @override
  String build() => '';

  void update(String query) {
    state = query;
  }

  void clear() {
    state = '';
  }
}

/// Provider for the selected category filter.
/// null means "All Categories".
@riverpod
class CategoryFilter extends _$CategoryFilter {
  @override
  SubscriptionCategory? build() => null;

  void select(SubscriptionCategory? category) {
    state = category;
  }

  void clear() {
    state = null;
  }
}

/// Provider for the current sort option.
@riverpod
class SortBy extends _$SortBy {
  @override
  SortOption build() => SortOption.nextBillingDate;

  void select(SortOption option) {
    state = option;
  }
}

/// Provider for the sort direction.
/// true = ascending, false = descending.
@riverpod
class SortAscending extends _$SortAscending {
  @override
  bool build() => true;

  void toggle() {
    state = !state;
  }

  void set(bool ascending) {
    state = ascending;
  }
}

/// Provider that filters active subscriptions based on the search query.
/// Searches in name, description, and category label.
@riverpod
List<Subscription> filteredSubscriptions(FilteredSubscriptionsRef ref) {
  final query = ref.watch(searchQueryProvider).toLowerCase().trim();
  final categoryFilter = ref.watch(categoryFilterProvider);
  final sortBy = ref.watch(sortByProvider);
  final sortAscending = ref.watch(sortAscendingProvider);
  final subscriptions = ref.watch(subscriptionsListProvider);

  // Filter by search query
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

  // Filter by category
  if (categoryFilter != null) {
    result = result.where((sub) => sub.category == categoryFilter).toList();
  }

  // Sort
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

/// Returns true if any filter or sort is active (non-default).
@riverpod
bool hasActiveFilters(HasActiveFiltersRef ref) {
  final query = ref.watch(searchQueryProvider);
  final category = ref.watch(categoryFilterProvider);
  final sortBy = ref.watch(sortByProvider);
  final sortAscending = ref.watch(sortAscendingProvider);

  return query.isNotEmpty ||
      category != null ||
      sortBy != SortOption.nextBillingDate ||
      !sortAscending;
}
