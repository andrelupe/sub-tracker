import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:subtracker/core/extensions/datetime_extensions.dart';
import 'package:subtracker/features/subscriptions/models/subscription.dart';
import 'package:subtracker/features/subscriptions/providers/subscription_providers.dart';

class SubscriptionListTile extends ConsumerWidget {
  const SubscriptionListTile({
    super.key,
    required this.subscription,
    this.onTap,
  });

  final Subscription subscription;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isInactive = !subscription.isActive;

    return Opacity(
      opacity: isInactive ? 0.6 : 1.0,
      child: Slidable(
        endActionPane: ActionPane(
          motion: const BehindMotion(),
          children: [
            SlidableAction(
              onPressed: (_) {
                ref
                    .read(subscriptionsNotifierProvider.notifier)
                    .toggleActive(subscription.id);
              },
              backgroundColor: colorScheme.secondary,
              foregroundColor: colorScheme.onSecondary,
              icon: subscription.isActive ? Icons.pause : Icons.play_arrow,
              label: subscription.isActive ? 'Pause' : 'Resume',
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
            ),
            SlidableAction(
              onPressed: (_) async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Subscription'),
                    content: Text(
                      'Are you sure you want to delete "${subscription.name}"?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.error,
                        ),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  ref
                      .read(subscriptionsNotifierProvider.notifier)
                      .delete(subscription.id);
                }
              },
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
              icon: Icons.delete_outline,
              label: 'Delete',
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(16),
              ),
            ),
          ],
        ),
        child: Card(
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color:
                          subscription.category.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      subscription.category.icon,
                      color: subscription.category.color,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subscription.name,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 14,
                              color: subscription.isDueSoon
                                  ? colorScheme.error
                                  : colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatNextBilling(),
                              style: textTheme.bodySmall?.copyWith(
                                color: subscription.isDueSoon
                                    ? colorScheme.error
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isInactive) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.pause,
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Paused',
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${subscription.currency} ${subscription.amount.toStringAsFixed(2)}',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subscription.billingCycle.label,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatNextBilling() {
    final days = subscription.daysUntilNextBilling;

    if (days == 0) return 'Due today';
    if (days == 1) return 'Due tomorrow';
    if (days < 0) return 'Overdue';
    if (days <= 7) return 'Due in $days days';

    return subscription.nextBillingDate.formatted;
  }
}
