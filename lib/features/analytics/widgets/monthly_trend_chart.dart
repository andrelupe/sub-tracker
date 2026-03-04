import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:subtracker/features/analytics/providers/analytics_providers.dart';
import 'package:subtracker/features/settings/models/user_settings.dart';

/// Line chart showing the monthly spending trend over the selected period.
class MonthlyTrendChart extends ConsumerWidget {
  const MonthlyTrendChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trend = ref.watch(monthlyTrendProvider);
    final stats = ref.watch(analyticsStatsProvider);
    final symbol = UserSettings.currencySymbol(stats.baseCurrency);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (trend.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'No data available',
            style: textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    final spots = trend
        .asMap()
        .entries
        .map(
          (e) => FlSpot(e.key.toDouble(), e.value.amount),
        )
        .toList();

    final maxY = spots.map((s) => s.y).reduce(
          (a, b) => a > b ? a : b,
        );
    final minY = spots.map((s) => s.y).reduce(
          (a, b) => a < b ? a : b,
        );
    // Add padding to the y-axis
    final yRange = maxY - minY;
    final chartMaxY = maxY + (yRange == 0 ? maxY * 0.2 + 10 : yRange * 0.15);
    final chartMinY =
        (minY - (yRange == 0 ? minY * 0.2 : yRange * 0.15)).clamp(0.0, minY);

    // Build accessible description of the trend for screen readers
    final trendDescription = StringBuffer('Monthly spending trend. ');
    for (final data in trend) {
      trendDescription.write(
        '${DateFormat.MMM().format(data.month)}: $symbol${data.amount.toStringAsFixed(2)}. ',
      );
    }

    return Semantics(
      label: trendDescription.toString(),
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(
              horizontalInterval:
                  yRange == 0 ? chartMaxY / 4 : (chartMaxY - chartMinY) / 4,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: const AxisTitles(),
              rightTitles: const AxisTitles(),
              topTitles: const AxisTitles(),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
                  interval: _bottomInterval(trend.length),
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= trend.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        DateFormat.MMM().format(trend[index].month),
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            minX: 0,
            maxX: (trend.length - 1).toDouble(),
            minY: chartMinY,
            maxY: chartMaxY,
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipColor: (_) => colorScheme.inverseSurface,
                getTooltipItems: (spots) => spots.map((spot) {
                  final month = trend[spot.x.toInt()].month;
                  return LineTooltipItem(
                    '${DateFormat.MMM().format(month)}\n'
                    '$symbol${spot.y.toStringAsFixed(2)}',
                    TextStyle(
                      color: colorScheme.onInverseSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: colorScheme.primary,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  getDotPainter: (spot, percent, barData, index) =>
                      FlDotCirclePainter(
                    radius: 4,
                    color: colorScheme.primary,
                    strokeWidth: 2,
                    strokeColor: colorScheme.surface,
                  ),
                ),
                belowBarData: BarAreaData(
                  show: true,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.15),
                      colorScheme.primary.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Calculate a suitable interval for bottom axis labels so they don't
  /// overlap. Show at most ~6 labels.
  double _bottomInterval(int count) {
    if (count <= 6) return 1;
    return (count / 6).ceilToDouble();
  }
}
