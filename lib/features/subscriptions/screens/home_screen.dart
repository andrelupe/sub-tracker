import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:subtracker/core/constants/app_constants.dart';
import 'package:subtracker/core/router/app_router.dart';
import 'package:subtracker/features/subscriptions/models/sort_option.dart';
import 'package:subtracker/features/subscriptions/providers/subscription_providers.dart';
import 'package:subtracker/features/subscriptions/widgets/filter_sort_bar.dart';
import 'package:subtracker/features/subscriptions/widgets/monthly_summary_card.dart';
import 'package:subtracker/features/subscriptions/widgets/subscription_list_tile.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearAllFilters(WidgetRef ref) {
    _searchController.clear();
    ref.read(searchQueryProvider.notifier).clear();
    ref.read(categoryFilterProvider.notifier).clear();
    ref.read(sortByProvider.notifier).select(SortOption.nextBillingDate);
    ref.read(sortAscendingProvider.notifier).set(true);
    if (ref.read(showInactiveProvider)) {
      ref.read(showInactiveProvider.notifier).toggle();
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncSubscriptions = ref.watch(subscriptionsNotifierProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SubTracker'),
        actions: [
          if (asyncSubscriptions.hasValue)
            if (ref.watch(hasActiveFiltersProvider))
              TextButton.icon(
                onPressed: () => _clearAllFilters(ref),
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear'),
              ),
        ],
      ),
      body: asyncSubscriptions.when(
        data: (allSubscriptions) {
          if (allSubscriptions.isEmpty) {
            return _EmptyState(
              onAdd: () => context.push(AppRoutes.addSubscription),
            );
          }

          final filteredSubscriptions =
              ref.watch(filteredSubscriptionsProvider);
          final hasActiveFilters = ref.watch(hasActiveFiltersProvider);
          final showInactive = ref.watch(showInactiveProvider);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(subscriptionsNotifierProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const MonthlySummaryCard(),
                const SizedBox(height: 16),
                SearchBar(
                  controller: _searchController,
                  hintText: 'Search subscriptions...',
                  leading: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.search),
                  ),
                  trailing: searchQuery.isNotEmpty
                      ? [
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(searchQueryProvider.notifier).clear();
                            },
                          ),
                        ]
                      : null,
                  onChanged: (value) {
                    ref.read(searchQueryProvider.notifier).update(value);
                  },
                  padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 8),
                  ),
                  elevation: const WidgetStatePropertyAll(0),
                  backgroundColor: WidgetStatePropertyAll(
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                  ),
                ),
                const SizedBox(height: 12),
                const FilterSortBar(),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      hasActiveFilters
                          ? 'Filtered Results'
                          : showInactive
                              ? 'Inactive Subscriptions'
                              : 'Active Subscriptions',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      '${filteredSubscriptions.length}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (filteredSubscriptions.isEmpty && hasActiveFilters)
                  _NoResultsState(query: searchQuery)
                else
                  ...filteredSubscriptions.map(
                    (sub) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SubscriptionListTile(
                        subscription: sub,
                        onTap: () => context.push(
                          AppRoutes.editSubscriptionPath(sub.id),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 32),
                const _VersionFooter(),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, _) => _ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(subscriptionsNotifierProvider),
        ),
      ),
      floatingActionButton: asyncSubscriptions.hasValue
          ? FloatingActionButton.extended(
              onPressed: () => context.push(AppRoutes.addSubscription),
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            )
          : null,
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.subscriptions_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 24),
            Text(
              'No subscriptions yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Start tracking your recurring payments by adding your first subscription.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add Subscription'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load subscriptions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoResultsState extends StatelessWidget {
  const _NoResultsState({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    final hasSearchQuery = query.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            hasSearchQuery ? Icons.search_off : Icons.filter_list_off,
            size: 48,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            hasSearchQuery
                ? 'No results for "$query"'
                : 'No matching subscriptions',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            hasSearchQuery
                ? 'Try a different search term'
                : 'Try adjusting your filters',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _VersionFooter extends StatelessWidget {
  const _VersionFooter();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'v${AppConstants.version}',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
      ),
    );
  }
}
