import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:subtracker/core/router/app_router.dart';
import 'package:subtracker/core/widgets/centered_content.dart';
import 'package:subtracker/core/widgets/responsive_layout.dart';
import 'package:subtracker/features/subscriptions/models/sort_option.dart';
import 'package:subtracker/features/subscriptions/models/subscription.dart';
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
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
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

  Widget _buildSearchBar(String searchQuery) {
    return SearchBar(
      controller: _searchController,
      hintText: 'Search subscriptions...',
      textInputAction: TextInputAction.search,
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
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(milliseconds: 300), () {
          ref.read(searchQueryProvider.notifier).update(value);
        });
      },
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 8),
      ),
      elevation: const WidgetStatePropertyAll(0),
      backgroundColor: WidgetStatePropertyAll(
        Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
    );
  }

  Widget _buildSectionHeader(
    List<Subscription> filteredSubscriptions,
    bool hasActiveFilters,
    bool showInactive,
  ) {
    return Row(
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
    );
  }

  Widget _buildSubscriptionList(
    List<Subscription> filteredSubscriptions,
    bool hasActiveFilters,
    String searchQuery,
  ) {
    return Column(
      children: [
        _AddSubscriptionCard(
          onTap: () => context.push(AppRoutes.addSubscription),
        ),
        const SizedBox(height: 8),
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
      ],
    );
  }

  Widget _buildMobileLayout({
    required String searchQuery,
    required List<Subscription> filteredSubscriptions,
    required bool hasActiveFilters,
    required bool showInactive,
  }) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(subscriptionsNotifierProvider);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const MonthlySummaryCard(),
          const SizedBox(height: 16),
          _buildSearchBar(searchQuery),
          const SizedBox(height: 12),
          FilterSortBar(
            onClearFilters: () => _clearAllFilters(ref),
          ),
          const SizedBox(height: 24),
          _buildSectionHeader(
            filteredSubscriptions,
            hasActiveFilters,
            showInactive,
          ),
          const SizedBox(height: 12),
          _buildSubscriptionList(
            filteredSubscriptions,
            hasActiveFilters,
            searchQuery,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout({
    required String searchQuery,
    required List<Subscription> filteredSubscriptions,
    required bool hasActiveFilters,
    required bool showInactive,
  }) {
    return CenteredContent(
      maxWidth: 1100,
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sidebar
                  SizedBox(
                    width: 320,
                    child: ListView(
                      children: [
                        const MonthlySummaryCard(),
                        const SizedBox(height: 16),
                        _buildSearchBar(searchQuery),
                        const SizedBox(height: 16),
                        FilterSortBar(
                          onClearFilters: () => _clearAllFilters(ref),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  // Main content
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(subscriptionsNotifierProvider);
                      },
                      child: ListView(
                        children: [
                          _buildSectionHeader(
                            filteredSubscriptions,
                            hasActiveFilters,
                            showInactive,
                          ),
                          const SizedBox(height: 12),
                          _buildSubscriptionList(
                            filteredSubscriptions,
                            hasActiveFilters,
                            searchQuery,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncSubscriptions = ref.watch(subscriptionsNotifierProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        centerTitle: true,
        title: CenteredContent(
          maxWidth: isDesktop ? 1100 : double.infinity,
          padding: EdgeInsets.symmetric(horizontal: isDesktop ? 24 : 16),
          child: Row(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/icon.png',
                    height: 32,
                    width: 32,
                  ),
                  const SizedBox(width: 10),
                  const Text('Subscription Tracker'),
                ],
              ),
              const Spacer(),
              if (ResponsiveLayout.isDesktop(context))
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh',
                  onPressed: () =>
                      ref.invalidate(subscriptionsNotifierProvider),
                ),
              IconButton(
                icon: const Icon(Icons.settings),
                tooltip: 'Settings',
                onPressed: () => context.push(AppRoutes.settings),
              ),
            ],
          ),
        ),
        actions: const [SizedBox.shrink()],
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

          return ResponsiveLayout(
            mobile: _buildMobileLayout(
              searchQuery: searchQuery,
              filteredSubscriptions: filteredSubscriptions,
              hasActiveFilters: hasActiveFilters,
              showInactive: showInactive,
            ),
            tablet: CenteredContent(
              maxWidth: 600,
              padding: EdgeInsets.zero,
              child: _buildMobileLayout(
                searchQuery: searchQuery,
                filteredSubscriptions: filteredSubscriptions,
                hasActiveFilters: hasActiveFilters,
                showInactive: showInactive,
              ),
            ),
            desktop: _buildDesktopLayout(
              searchQuery: searchQuery,
              filteredSubscriptions: filteredSubscriptions,
              hasActiveFilters: hasActiveFilters,
              showInactive: showInactive,
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

class _AddSubscriptionCard extends StatelessWidget {
  const _AddSubscriptionCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: CustomPaint(
        painter: _DashedBorderPainter(
          color: colorScheme.outline,
          borderRadius: 12,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_circle_outline,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Add Subscription',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  _DashedBorderPainter({
    required this.color,
    required this.borderRadius,
  });

  final Color color;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final path = Path()..addRRect(rrect);
    final dashPath = _createDashedPath(path);
    canvas.drawPath(dashPath, paint);
  }

  Path _createDashedPath(Path source) {
    const dashWidth = 6.0;
    const dashSpace = 4.0;
    final dashedPath = Path();

    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + dashWidth, metric.length);
        dashedPath.addPath(
          metric.extractPath(distance, end),
          Offset.zero,
        );
        distance += dashWidth + dashSpace;
      }
    }

    return dashedPath;
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      color != oldDelegate.color || borderRadius != oldDelegate.borderRadius;
}
