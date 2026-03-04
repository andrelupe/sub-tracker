import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subtracker/features/analytics/providers/analytics_providers.dart';
import 'package:subtracker/features/settings/models/user_settings.dart';

/// Grid of 4 KPI cards showing analytics stats.
///
/// In mobile/tablet mode renders a 2x2 grid.
/// When [useColumn] is true (desktop sidebar), renders a vertical column.
class StatisticsCards extends ConsumerWidget {
  const StatisticsCards({super.key, this.useColumn = false});

  final bool useColumn;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(analyticsStatsProvider);
    final symbol = UserSettings.currencySymbol(stats.baseCurrency);

    final cards = [
      _StatCard(
        icon: Icons.calendar_month,
        label: 'Monthly Total',
        value: '$symbol${stats.monthlyTotal.toStringAsFixed(2)}',
      ),
      _StatCard(
        icon: Icons.date_range,
        label: 'Yearly Total',
        value: '$symbol${stats.yearlyTotal.toStringAsFixed(2)}',
      ),
      _StatCard(
        icon: Icons.trending_up,
        label: 'Most Expensive',
        value: stats.mostExpensiveSubscription != null
            ? '${stats.mostExpensiveSubscription!.name}\n'
                '$symbol${stats.mostExpensiveAmount.toStringAsFixed(2)}'
            : '\u2014',
      ),
      _StatCard(
        icon: Icons.category,
        label: 'Top Category',
        value: stats.topCategory != null
            ? '${stats.topCategory!.category.label}\n'
                '$symbol${stats.topCategory!.monthlyAmount.toStringAsFixed(2)}'
            : '\u2014',
      ),
    ];

    if (useColumn) {
      return Column(
        children: cards
            .map(
              (card) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: card,
              ),
            )
            .toList(),
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: cards,
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      label: '$label: $value',
      child: Tooltip(
        message: '$label: $value',
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: colorScheme.primary, size: 20),
              const SizedBox(height: 8),
              Text(
                value,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
