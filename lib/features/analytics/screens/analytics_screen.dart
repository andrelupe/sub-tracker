import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subtracker/core/widgets/centered_content.dart';
import 'package:subtracker/core/widgets/responsive_layout.dart';
import 'package:subtracker/features/analytics/widgets/category_chart.dart';
import 'package:subtracker/features/analytics/widgets/monthly_trend_chart.dart';
import 'package:subtracker/features/analytics/widgets/period_selector.dart';
import 'package:subtracker/features/analytics/widgets/statistics_cards.dart';
import 'package:subtracker/features/subscriptions/providers/subscription_providers.dart';

/// Analytics screen with spending charts and statistics.
class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncSubscriptions = ref.watch(subscriptionsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
      ),
      body: asyncSubscriptions.when(
        data: (_) => ResponsiveLayout(
          mobile: _MobileLayout(),
          tablet: _TabletLayout(),
          desktop: _DesktopLayout(),
        ),
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

class _MobileLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StatisticsCards(),
          const SizedBox(height: 24),
          const PeriodSelector(),
          const SizedBox(height: 16),
          const MonthlyTrendChart(),
          const SizedBox(height: 24),
          Text(
            'Spending by Category',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const CategoryChart(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _TabletLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: CenteredContent(
        maxWidth: 700,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const StatisticsCards(),
            const SizedBox(height: 24),
            const PeriodSelector(),
            const SizedBox(height: 16),
            const MonthlyTrendChart(),
            const SizedBox(height: 24),
            Text(
              'Spending by Category',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const CategoryChart(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _DesktopLayout extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: CenteredContent(
        maxWidth: 1100,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left sidebar — statistics cards
            const SizedBox(
              width: 300,
              child: StatisticsCards(useColumn: true),
            ),
            const SizedBox(width: 24),
            // Right — period selector + charts
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PeriodSelector(),
                  const SizedBox(height: 16),
                  const MonthlyTrendChart(),
                  const SizedBox(height: 24),
                  Text(
                    'Spending by Category',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const CategoryChart(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
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
