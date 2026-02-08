import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subtracker/features/subscriptions/models/billing_cycle.dart';
import 'package:subtracker/features/subscriptions/models/sort_option.dart';
import 'package:subtracker/features/subscriptions/models/subscription.dart';
import 'package:subtracker/features/subscriptions/models/subscription_category.dart';
import 'package:subtracker/features/subscriptions/providers/subscription_providers.dart';

void main() {
  group('SortOption', () {
    test('has correct default ascending values', () {
      expect(SortOption.nextBillingDate.defaultAscending, isTrue);
      expect(SortOption.name.defaultAscending, isTrue);
      expect(SortOption.amount.defaultAscending, isFalse);
      expect(SortOption.category.defaultAscending, isTrue);
    });

    test('has correct labels', () {
      expect(SortOption.nextBillingDate.label, 'Next Billing');
      expect(SortOption.name.label, 'Name');
      expect(SortOption.amount.label, 'Price');
      expect(SortOption.category.label, 'Category');
    });
  });

  group('Filter and Sort Providers', () {
    late ProviderContainer container;
    late List<Subscription> testSubscriptions;

    setUp(() {
      final now = DateTime.now();

      testSubscriptions = [
        Subscription(
          id: '1',
          name: 'Netflix',
          amount: 15.99,
          currency: 'EUR',
          billingCycle: BillingCycle.monthly,
          category: SubscriptionCategory.entertainment,
          startDate: now.subtract(const Duration(days: 30)),
          nextBillingDate: now.add(const Duration(days: 5)),
          createdAt: now,
          updatedAt: now,
        ),
        Subscription(
          id: '2',
          name: 'Spotify',
          amount: 9.99,
          currency: 'EUR',
          billingCycle: BillingCycle.monthly,
          category: SubscriptionCategory.music,
          startDate: now.subtract(const Duration(days: 20)),
          nextBillingDate: now.add(const Duration(days: 10)),
          createdAt: now,
          updatedAt: now,
        ),
        Subscription(
          id: '3',
          name: 'iCloud',
          description: 'Apple storage',
          amount: 2.99,
          currency: 'EUR',
          billingCycle: BillingCycle.monthly,
          category: SubscriptionCategory.cloud,
          startDate: now.subtract(const Duration(days: 90)),
          nextBillingDate: now.add(const Duration(days: 2)),
          createdAt: now,
          updatedAt: now,
        ),
        Subscription(
          id: '4',
          name: 'Adobe Creative Suite',
          amount: 54.99,
          currency: 'EUR',
          billingCycle: BillingCycle.monthly,
          category: SubscriptionCategory.productivity,
          startDate: now.subtract(const Duration(days: 10)),
          nextBillingDate: now.add(const Duration(days: 20)),
          createdAt: now,
          updatedAt: now,
        ),
      ];

      container = ProviderContainer(
        overrides: [
          subscriptionsListProvider.overrideWithValue(testSubscriptions),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('SearchQuery', () {
      test('initial value is empty string', () {
        expect(container.read(searchQueryProvider), isEmpty);
      });

      test('update changes the query', () {
        container.read(searchQueryProvider.notifier).update('netflix');
        expect(container.read(searchQueryProvider), 'netflix');
      });

      test('clear resets to empty string', () {
        container.read(searchQueryProvider.notifier).update('test');
        container.read(searchQueryProvider.notifier).clear();
        expect(container.read(searchQueryProvider), isEmpty);
      });
    });

    group('CategoryFilter', () {
      test('initial value is null (all categories)', () {
        expect(container.read(categoryFilterProvider), isNull);
      });

      test('select changes the category', () {
        container
            .read(categoryFilterProvider.notifier)
            .select(SubscriptionCategory.music);
        expect(
            container.read(categoryFilterProvider), SubscriptionCategory.music);
      });

      test('clear resets to null', () {
        container
            .read(categoryFilterProvider.notifier)
            .select(SubscriptionCategory.music);
        container.read(categoryFilterProvider.notifier).clear();
        expect(container.read(categoryFilterProvider), isNull);
      });
    });

    group('SortBy', () {
      test('initial value is nextBillingDate', () {
        expect(container.read(sortByProvider), SortOption.nextBillingDate);
      });

      test('select changes the sort option', () {
        container.read(sortByProvider.notifier).select(SortOption.name);
        expect(container.read(sortByProvider), SortOption.name);
      });
    });

    group('SortAscending', () {
      test('initial value is true', () {
        expect(container.read(sortAscendingProvider), isTrue);
      });

      test('toggle changes the value', () {
        container.read(sortAscendingProvider.notifier).toggle();
        expect(container.read(sortAscendingProvider), isFalse);
        container.read(sortAscendingProvider.notifier).toggle();
        expect(container.read(sortAscendingProvider), isTrue);
      });

      test('set changes to specific value', () {
        container.read(sortAscendingProvider.notifier).set(false);
        expect(container.read(sortAscendingProvider), isFalse);
      });
    });

    group('filteredSubscriptions', () {
      test('returns all subscriptions when no filters applied', () {
        final result = container.read(filteredSubscriptionsProvider);
        expect(result.length, 4);
      });

      test('filters by search query in name', () {
        container.read(searchQueryProvider.notifier).update('netflix');
        final result = container.read(filteredSubscriptionsProvider);
        expect(result.length, 1);
        expect(result.first.name, 'Netflix');
      });

      test('filters by search query in description', () {
        container.read(searchQueryProvider.notifier).update('apple');
        final result = container.read(filteredSubscriptionsProvider);
        expect(result.length, 1);
        expect(result.first.name, 'iCloud');
      });

      test('filters by search query in category label', () {
        container.read(searchQueryProvider.notifier).update('music');
        final result = container.read(filteredSubscriptionsProvider);
        expect(result.length, 1);
        expect(result.first.name, 'Spotify');
      });

      test('search is case insensitive', () {
        container.read(searchQueryProvider.notifier).update('NETFLIX');
        final result = container.read(filteredSubscriptionsProvider);
        expect(result.length, 1);
        expect(result.first.name, 'Netflix');
      });

      test('filters by category', () {
        container
            .read(categoryFilterProvider.notifier)
            .select(SubscriptionCategory.entertainment);
        final result = container.read(filteredSubscriptionsProvider);
        expect(result.length, 1);
        expect(result.first.name, 'Netflix');
      });

      test('combines search and category filters', () {
        container.read(searchQueryProvider.notifier).update('cloud');
        container
            .read(categoryFilterProvider.notifier)
            .select(SubscriptionCategory.cloud);
        final result = container.read(filteredSubscriptionsProvider);
        expect(result.length, 1);
        expect(result.first.name, 'iCloud');
      });

      test('returns empty list when no matches', () {
        container.read(searchQueryProvider.notifier).update('nonexistent');
        final result = container.read(filteredSubscriptionsProvider);
        expect(result, isEmpty);
      });

      test('sorts by name ascending', () {
        container.read(sortByProvider.notifier).select(SortOption.name);
        container.read(sortAscendingProvider.notifier).set(true);
        final result = container.read(filteredSubscriptionsProvider);
        expect(result.map((s) => s.name).toList(), [
          'Adobe Creative Suite',
          'iCloud',
          'Netflix',
          'Spotify',
        ]);
      });

      test('sorts by name descending', () {
        container.read(sortByProvider.notifier).select(SortOption.name);
        container.read(sortAscendingProvider.notifier).set(false);
        final result = container.read(filteredSubscriptionsProvider);
        expect(result.map((s) => s.name).toList(), [
          'Spotify',
          'Netflix',
          'iCloud',
          'Adobe Creative Suite',
        ]);
      });

      test('sorts by amount ascending', () {
        container.read(sortByProvider.notifier).select(SortOption.amount);
        container.read(sortAscendingProvider.notifier).set(true);
        final result = container.read(filteredSubscriptionsProvider);
        expect(
            result.map((s) => s.amount).toList(), [2.99, 9.99, 15.99, 54.99]);
      });

      test('sorts by amount descending', () {
        container.read(sortByProvider.notifier).select(SortOption.amount);
        container.read(sortAscendingProvider.notifier).set(false);
        final result = container.read(filteredSubscriptionsProvider);
        expect(
            result.map((s) => s.amount).toList(), [54.99, 15.99, 9.99, 2.99]);
      });

      test('sorts by next billing date ascending', () {
        container
            .read(sortByProvider.notifier)
            .select(SortOption.nextBillingDate);
        container.read(sortAscendingProvider.notifier).set(true);
        final result = container.read(filteredSubscriptionsProvider);
        // iCloud (2 days), Netflix (5 days), Spotify (10 days), Adobe (15 days)
        expect(result.map((s) => s.name).toList(), [
          'iCloud',
          'Netflix',
          'Spotify',
          'Adobe Creative Suite',
        ]);
      });

      test('sorts by category ascending', () {
        container.read(sortByProvider.notifier).select(SortOption.category);
        container.read(sortAscendingProvider.notifier).set(true);
        final result = container.read(filteredSubscriptionsProvider);
        expect(result.map((s) => s.category.label).toList(), [
          'Cloud Storage',
          'Entertainment',
          'Music',
          'Productivity',
        ]);
      });
    });

    group('hasActiveFilters', () {
      test('returns false when no filters are active', () {
        expect(container.read(hasActiveFiltersProvider), isFalse);
      });

      test('returns true when search query is set', () {
        container.read(searchQueryProvider.notifier).update('test');
        expect(container.read(hasActiveFiltersProvider), isTrue);
      });

      test('returns true when category filter is set', () {
        container
            .read(categoryFilterProvider.notifier)
            .select(SubscriptionCategory.music);
        expect(container.read(hasActiveFiltersProvider), isTrue);
      });

      test('returns true when sort option is non-default', () {
        container.read(sortByProvider.notifier).select(SortOption.name);
        expect(container.read(hasActiveFiltersProvider), isTrue);
      });

      test('returns true when sort direction is descending', () {
        container.read(sortAscendingProvider.notifier).set(false);
        expect(container.read(hasActiveFiltersProvider), isTrue);
      });
    });
  });
}
