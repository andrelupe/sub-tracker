import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subtracker/features/analytics/providers/analytics_providers.dart';
import 'package:subtracker/features/settings/models/user_settings.dart';

/// Grid of 4 KPI cards showing analytics stats.
///
/// In mobile/tablet mode renders a 2x2 grid.
/// When [useColumn] is true (desktop sidebar), renders a vertical column
/// where every card has the same height thanks to paired [IntrinsicHeight]
/// rows.
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
        subtitle: '',
      ),
      _StatCard(
        icon: Icons.date_range,
        label: 'Yearly Total',
        value: '$symbol${stats.yearlyTotal.toStringAsFixed(2)}',
        subtitle: '',
      ),
      _StatCard(
        icon: Icons.trending_up,
        label: 'Most Expensive',
        value: stats.mostExpensiveSubscription != null
            ? stats.mostExpensiveSubscription!.name
            : '\u2014',
        subtitle: stats.mostExpensiveSubscription != null
            ? '$symbol${stats.mostExpensiveAmount.toStringAsFixed(2)}'
            : '',
      ),
      _StatCard(
        icon: Icons.category,
        label: 'Top Category',
        value: stats.topCategory != null
            ? stats.topCategory!.category.label
            : '\u2014',
        subtitle: stats.topCategory != null
            ? '$symbol${stats.topCategory!.monthlyAmount.toStringAsFixed(2)}'
            : '',
      ),
    ];

    if (useColumn) {
      // Pair cards in IntrinsicHeight rows so each pair shares the same
      // height (the tallest of the two). With 4 cards this gives 2 rows.
      final rows = <Widget>[];
      for (var i = 0; i < cards.length; i += 2) {
        final end = (i + 2).clamp(0, cards.length);
        final pair = cards.sublist(i, end);
        rows.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var j = 0; j < pair.length; j++) ...[
                    if (j > 0) const SizedBox(width: 12),
                    Expanded(child: pair[j]),
                  ],
                ],
              ),
            ),
          ),
        );
      }
      return Column(children: rows);
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
    required this.subtitle,
  });

  final IconData icon;
  final String label;
  final String value;
  final String subtitle;

  String get _semanticsValue => subtitle.isEmpty ? value : '$value $subtitle';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      label: '$label: $_semanticsValue',
      child: Tooltip(
        message: '$label: $_semanticsValue',
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: colorScheme.primary, size: 20),
              const SizedBox(height: 8),
              Text(
                value,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle.isNotEmpty) ...[
                Text(
                  subtitle,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
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
