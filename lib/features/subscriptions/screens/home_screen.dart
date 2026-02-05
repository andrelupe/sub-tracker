import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:subtracker/core/router/app_router.dart';
import 'package:subtracker/features/subscriptions/providers/subscription_providers.dart';
import 'package:subtracker/features/subscriptions/widgets/monthly_summary_card.dart';
import 'package:subtracker/features/subscriptions/widgets/subscription_list_tile.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptions = ref.watch(subscriptionsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SubTracker'),
      ),
      body: subscriptions.isEmpty
          ? _EmptyState(onAdd: () => context.push(AppRoutes.addSubscription))
          : RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(subscriptionsListProvider);
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const MonthlySummaryCard(),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Active Subscriptions',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${subscriptions.length}',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...subscriptions.map(
                    (sub) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SubscriptionListTile(
                        subscription: sub,
                        onTap: () => context.push(
                          AppRoutes.editSubscriptionPath(sub.id),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.addSubscription),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.subscriptions_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 24),
            Text(
              'No subscriptions yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Start tracking your recurring payments by adding your first subscription.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add Subscription'),
            ),
          ],
        ),
      ),
    );
  }
}
