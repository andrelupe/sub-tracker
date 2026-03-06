import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subtracker/features/settings/providers/settings_providers.dart';

/// Toggle switch to enable/disable the Analytics screen.
class AnalyticsToggle extends ConsumerWidget {
  const AnalyticsToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(analyticsEnabledNotifierProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Features',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: SwitchListTile(
            secondary: const Icon(Icons.analytics_outlined),
            title: const Text('Analytics'),
            subtitle: const Text('Show spending charts and statistics'),
            value: enabled,
            onChanged: (_) =>
                ref.read(analyticsEnabledNotifierProvider.notifier).toggle(),
          ),
        ),
      ],
    );
  }
}
