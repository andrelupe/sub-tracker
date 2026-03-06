import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subtracker/features/analytics/providers/analytics_providers.dart';

/// Segmented button for selecting the analytics period (3, 6, or 12 months).
class PeriodSelector extends ConsumerWidget {
  const PeriodSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(analyticsPeriodProvider);

    return Semantics(
      label: 'Analytics period selector. Selected: $period months',
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<int>(
          segments: const [
            ButtonSegment(
              value: 3,
              label: Text('3M'),
              tooltip: '3 months',
            ),
            ButtonSegment(
              value: 6,
              label: Text('6M'),
              tooltip: '6 months',
            ),
            ButtonSegment(
              value: 12,
              label: Text('12M'),
              tooltip: '12 months',
            ),
          ],
          selected: {period},
          onSelectionChanged: (value) =>
              ref.read(analyticsPeriodProvider.notifier).setPeriod(value.first),
        ),
      ),
    );
  }
}
