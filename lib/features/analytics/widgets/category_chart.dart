import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subtracker/features/analytics/models/analytics_data.dart';
import 'package:subtracker/features/analytics/providers/analytics_providers.dart';
import 'package:subtracker/features/settings/models/user_settings.dart';

/// Donut chart showing spending breakdown by subscription category.
class CategoryChart extends ConsumerStatefulWidget {
  const CategoryChart({super.key});

  @override
  ConsumerState<CategoryChart> createState() => _CategoryChartState();
}

class _CategoryChartState extends ConsumerState<CategoryChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final spending = ref.watch(spendingByCategoryProvider);
    final stats = ref.watch(analyticsStatsProvider);
    final symbol = UserSettings.currencySymbol(stats.baseCurrency);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (spending.isEmpty) {
      return SizedBox(
        height: 250,
        child: Center(
          child: Text(
            'No active subscriptions',
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final total = spending.fold<double>(0, (sum, s) => sum + s.monthlyAmount);

    // Build accessible description of the chart for screen readers
    final chartDescription = StringBuffer(
      'Category spending chart. Total: $symbol${total.toStringAsFixed(2)} per month. ',
    );
    for (final item in spending) {
      final pct = (item.monthlyAmount / total * 100).round();
      chartDescription.write(
        '${item.category.label}: $symbol${item.monthlyAmount.toStringAsFixed(2)}, $pct%. ',
      );
    }

    return Semantics(
      label: chartDescription.toString(),
      child: Column(
        children: [
          SizedBox(
            height: 250,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        setState(() {
                          if (!event.isInterestedForInteractions ||
                              response == null ||
                              response.touchedSection == null) {
                            _touchedIndex = -1;
                            return;
                          }
                          _touchedIndex =
                              response.touchedSection!.touchedSectionIndex;
                        });
                      },
                    ),
                    borderData: FlBorderData(show: false),
                    sectionsSpace: 2,
                    centerSpaceRadius: 60,
                    sections: _buildSections(spending, total),
                  ),
                ),
                // Center label
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$symbol${total.toStringAsFixed(2)}',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '/month',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: spending.map((item) {
              final percentage = (item.monthlyAmount / total * 100).round();
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: item.category.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${item.category.label} $symbol${item.monthlyAmount.toStringAsFixed(0)} ($percentage%)',
                    style: textTheme.bodySmall,
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildSections(
    List<CategorySpending> spending,
    double total,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return List.generate(spending.length, (i) {
      final item = spending[i];
      final isTouched = i == _touchedIndex;
      final percentage = (item.monthlyAmount / total * 100).round();

      return PieChartSectionData(
        color: item.category.color,
        value: item.monthlyAmount,
        title: '$percentage%',
        radius: isTouched ? 65 : 55,
        titleStyle: TextStyle(
          fontSize: isTouched ? 14 : 12,
          fontWeight: FontWeight.bold,
          color: colorScheme.onInverseSurface,
        ),
        badgePositionPercentageOffset: isTouched ? 1.2 : .98,
      );
    });
  }
}
