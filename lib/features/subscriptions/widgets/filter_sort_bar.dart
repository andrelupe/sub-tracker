import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subtracker/features/subscriptions/models/sort_option.dart';
import 'package:subtracker/features/subscriptions/models/subscription_category.dart';
import 'package:subtracker/features/subscriptions/providers/subscription_providers.dart';

/// A horizontal bar with filter chips for category and sort options.
class FilterSortBar extends ConsumerWidget {
  const FilterSortBar({super.key, this.onClearFilters});

  final VoidCallback? onClearFilters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(categoryFilterProvider);
    final sortBy = ref.watch(sortByProvider);
    final sortAscending = ref.watch(sortAscendingProvider);
    final showInactive = ref.watch(showInactiveProvider);
    final hasActiveFilters = ref.watch(hasActiveFiltersProvider);

    final children = [
      // Category filter chip
      _CategoryFilterChip(
        selectedCategory: selectedCategory,
        onSelected: (category) {
          ref.read(categoryFilterProvider.notifier).select(category);
        },
      ),
      // Sort option chip
      _SortChip(
        sortBy: sortBy,
        sortAscending: sortAscending,
        onSortChanged: (option) {
          final currentSort = ref.read(sortByProvider);
          if (currentSort == option) {
            // Toggle direction if same sort option
            ref.read(sortAscendingProvider.notifier).toggle();
          } else {
            // Set new sort option with its default direction
            ref.read(sortByProvider.notifier).select(option);
            ref
                .read(sortAscendingProvider.notifier)
                .set(option.defaultAscending);
          }
        },
      ),
      // Show inactive toggle chip
      FilterChip(
        avatar: Icon(
          showInactive ? Icons.visibility : Icons.visibility_off,
          size: 18,
        ),
        label: const Text('Show inactive'),
        selected: showInactive,
        showCheckmark: false,
        onSelected: (_) {
          ref.read(showInactiveProvider.notifier).toggle();
        },
      ),
      // Clear all filters chip
      if (hasActiveFilters)
        ActionChip(
          avatar: const Icon(Icons.clear_all, size: 18),
          label: const Text('Clear'),
          onPressed: onClearFilters,
        ),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: children,
    );
  }
}

class _CategoryFilterChip extends StatelessWidget {
  const _CategoryFilterChip({
    required this.selectedCategory,
    required this.onSelected,
  });

  final SubscriptionCategory? selectedCategory;
  final ValueChanged<SubscriptionCategory?> onSelected;

  @override
  Widget build(BuildContext context) {
    final isFiltered = selectedCategory != null;

    return FilterChip(
      avatar: Icon(
        selectedCategory?.icon ?? Icons.category_outlined,
        size: 18,
        color: isFiltered ? selectedCategory!.color : null,
      ),
      label: Text(selectedCategory?.label ?? 'All Categories'),
      selected: isFiltered,
      showCheckmark: false,
      onSelected: (_) => _showCategoryPicker(context),
    );
  }

  void _showCategoryPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => _CategoryPickerSheet(
        selectedCategory: selectedCategory,
        onSelected: (category) {
          onSelected(category);
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

class _CategoryPickerSheet extends StatelessWidget {
  const _CategoryPickerSheet({
    required this.selectedCategory,
    required this.onSelected,
  });

  final SubscriptionCategory? selectedCategory;
  final ValueChanged<SubscriptionCategory?> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Filter by Category',
              style: theme.textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 16),
          // "All Categories" option
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: const Text('All Categories'),
            selected: selectedCategory == null,
            trailing: selectedCategory == null
                ? Icon(Icons.check, color: theme.colorScheme.primary)
                : null,
            onTap: () => onSelected(null),
          ),
          const Divider(),
          // Category list
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: SubscriptionCategory.values.length,
              itemBuilder: (context, index) {
                final category = SubscriptionCategory.values[index];
                final isSelected = category == selectedCategory;

                return ListTile(
                  leading: Icon(category.icon, color: category.color),
                  title: Text(category.label),
                  selected: isSelected,
                  trailing: isSelected
                      ? Icon(Icons.check, color: theme.colorScheme.primary)
                      : null,
                  onTap: () => onSelected(category),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.sortBy,
    required this.sortAscending,
    required this.onSortChanged,
  });

  final SortOption sortBy;
  final bool sortAscending;
  final ValueChanged<SortOption> onSortChanged;

  @override
  Widget build(BuildContext context) {
    final isNonDefault = sortBy != SortOption.nextBillingDate || !sortAscending;

    return FilterChip(
      avatar: Icon(
        sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
        size: 18,
      ),
      label: Text(sortBy.label),
      selected: isNonDefault,
      showCheckmark: false,
      onSelected: (_) => _showSortPicker(context),
    );
  }

  void _showSortPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => _SortPickerSheet(
        sortBy: sortBy,
        sortAscending: sortAscending,
        onSelected: (option) {
          onSortChanged(option);
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

class _SortPickerSheet extends StatelessWidget {
  const _SortPickerSheet({
    required this.sortBy,
    required this.sortAscending,
    required this.onSelected,
  });

  final SortOption sortBy;
  final bool sortAscending;
  final ValueChanged<SortOption> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Sort by',
              style: theme.textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 16),
          ...SortOption.values.map((option) {
            final isSelected = option == sortBy;

            return ListTile(
              leading: Icon(
                _getIconForSortOption(option),
                color: isSelected ? theme.colorScheme.primary : null,
              ),
              title: Text(option.label),
              subtitle: Text(
                isSelected
                    ? (sortAscending ? 'Ascending' : 'Descending')
                    : (option.defaultAscending
                        ? 'A to Z / Low to High'
                        : 'High to Low'),
              ),
              selected: isSelected,
              trailing: isSelected
                  ? Icon(
                      sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                      color: theme.colorScheme.primary,
                    )
                  : null,
              onTap: () => onSelected(option),
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  IconData _getIconForSortOption(SortOption option) {
    return switch (option) {
      SortOption.nextBillingDate => Icons.calendar_today,
      SortOption.name => Icons.sort_by_alpha,
      SortOption.amount => Icons.attach_money,
      SortOption.category => Icons.category,
    };
  }
}
