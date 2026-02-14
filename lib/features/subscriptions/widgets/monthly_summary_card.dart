import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subtracker/features/subscriptions/providers/subscription_providers.dart';

class MonthlySummaryCard extends ConsumerWidget {
  const MonthlySummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionsAsync = ref.watch(subscriptionsNotifierProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: subscriptionsAsync.when(
          data: (subscriptions) {
            final monthlyTotal = ref.read(monthlyTotalProvider);
            final yearlyTotal = ref.read(yearlyTotalProvider);
            final dueSoon = ref.read(dueSoonSubscriptionsProvider);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monthly Spending',
                  style: textTheme.titleSmall?.copyWith(
                    color:
                        colorScheme.onPrimaryContainer.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '€${monthlyTotal.toStringAsFixed(2)}',
                  style: textTheme.headlineLarge?.copyWith(
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _SummaryItem(
                        label: 'Yearly',
                        value: '€${yearlyTotal.toStringAsFixed(2)}',
                        icon: Icons.calendar_today_outlined,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color:
                          colorScheme.onPrimaryContainer.withValues(alpha: 0.3),
                    ),
                    Expanded(
                      child: _SummaryItem(
                        label: 'Due Soon',
                        value: '${dueSoon.length}',
                        icon: Icons.notifications_outlined,
                        highlight: dueSoon.isNotEmpty,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
          loading: () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Monthly Spending',
                style: textTheme.titleSmall?.copyWith(
                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Loading...',
                    style: textTheme.headlineLarge?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          error: (error, stackTrace) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Monthly Spending',
                style: textTheme.titleSmall?.copyWith(
                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Failed to load',
                style: textTheme.headlineLarge?.copyWith(
                  color: colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final textColor = highlight
        ? colorScheme.error
        : colorScheme.onPrimaryContainer.withValues(alpha: 0.85);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: textColor),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.85),
                ),
              ),
              Text(
                value,
                style: textTheme.titleMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
