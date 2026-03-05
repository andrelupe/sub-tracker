import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subtracker/features/settings/providers/settings_providers.dart';

/// Promotional banner shown on the Home screen when Analytics is disabled
/// and the user hasn't dismissed it yet.
class AnalyticsBanner extends ConsumerWidget {
  const AnalyticsBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsEnabled = ref.watch(analyticsEnabledNotifierProvider);
    final dismissed = ref.watch(analyticsBannerDismissedNotifierProvider);

    if (analyticsEnabled || dismissed) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        color: colorScheme.primaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: colorScheme.onPrimaryContainer,
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Track your spending trends',
                      style: textTheme.titleSmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Enable Analytics in Settings to see charts and insights.',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        FilledButton.tonal(
                          onPressed: () => ref
                              .read(
                                analyticsEnabledNotifierProvider.notifier,
                              )
                              .setEnabled(enabled: true),
                          child: const Text('Enable'),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => ref
                              .read(
                                analyticsBannerDismissedNotifierProvider
                                    .notifier,
                              )
                              .dismiss(),
                          child: Text(
                            'Dismiss',
                            style: TextStyle(
                              color: colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
