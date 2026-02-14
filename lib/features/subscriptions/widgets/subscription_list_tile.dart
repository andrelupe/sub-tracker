import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:subtracker/core/extensions/datetime_extensions.dart';
import 'package:subtracker/core/widgets/confirm_delete_dialog.dart';
import 'package:subtracker/core/widgets/responsive_layout.dart';
import 'package:subtracker/features/subscriptions/models/subscription.dart';
import 'package:subtracker/features/subscriptions/providers/subscription_providers.dart';

class SubscriptionListTile extends ConsumerStatefulWidget {
  const SubscriptionListTile({
    super.key,
    required this.subscription,
    this.onTap,
  });

  final Subscription subscription;
  final VoidCallback? onTap;

  @override
  ConsumerState<SubscriptionListTile> createState() =>
      _SubscriptionListTileState();
}

class _SubscriptionListTileState extends ConsumerState<SubscriptionListTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    if (isDesktop) {
      return _buildDesktopTile(context);
    }

    return _buildMobileTile(context);
  }

  // -- Desktop: Card com botões inline no hover --------------------------

  Widget _buildDesktopTile(BuildContext context) {
    final isInactive = !widget.subscription.isActive;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Opacity(
        opacity: isInactive ? 0.6 : 1.0,
        child: Card(
          child: InkWell(
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildCategoryIcon(),
                  const SizedBox(width: 16),
                  Expanded(child: _buildSubscriptionInfo()),
                  if (isInactive) ...[
                    _buildPausedBadge(),
                    const SizedBox(width: 8),
                  ],
                  if (_isHovered) ...[
                    _buildActionButtons(),
                    const SizedBox(width: 12),
                  ],
                  _buildPriceInfo(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // -- Mobile: Slidable com swipe actions --------------------------------

  Widget _buildMobileTile(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isInactive = !widget.subscription.isActive;

    return Opacity(
      opacity: isInactive ? 0.6 : 1.0,
      child: Slidable(
        endActionPane: ActionPane(
          motion: const BehindMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => _toggleActive(),
              backgroundColor: colorScheme.secondary,
              foregroundColor: colorScheme.onSecondary,
              icon:
                  widget.subscription.isActive ? Icons.pause : Icons.play_arrow,
              label: widget.subscription.isActive ? 'Pause' : 'Resume',
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
            ),
            SlidableAction(
              onPressed: (_) => _confirmDelete(),
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
            onTap: widget.onTap,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildCategoryIcon(),
                  const SizedBox(width: 16),
                  Expanded(child: _buildSubscriptionInfo()),
                  if (isInactive) ...[
                    _buildPausedBadge(),
                    const SizedBox(width: 8),
                  ],
                  _buildPriceInfo(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // -- Shared widgets ----------------------------------------------------

  Widget _buildCategoryIcon() {
    final category = widget.subscription.category;

    return Tooltip(
      message: category.label,
      preferBelow: false,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: category.color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          category.icon,
          color: category.color,
        ),
      ),
    );
  }

  Widget _buildSubscriptionInfo() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sub = widget.subscription;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sub.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 14,
              color: sub.isDueSoon
                  ? colorScheme.error
                  : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              _formatNextBilling(),
              style: theme.textTheme.bodySmall?.copyWith(
                color: sub.isDueSoon
                    ? colorScheme.error
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPausedBadge() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.pause, size: 14, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(
            'Paused',
            style: theme.textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceInfo() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sub = widget.subscription;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${sub.currency} ${sub.amount.toStringAsFixed(2)}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          sub.billingCycle.label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    final colorScheme = Theme.of(context).colorScheme;
    final isInactive = !widget.subscription.isActive;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: _toggleActive,
          icon: Icon(
            isInactive ? Icons.play_arrow : Icons.pause,
            size: 20,
          ),
          tooltip: isInactive ? 'Resume' : 'Pause',
          style: IconButton.styleFrom(
            backgroundColor: colorScheme.secondaryContainer,
            foregroundColor: colorScheme.onSecondaryContainer,
            minimumSize: const Size(36, 36),
            padding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _confirmDelete,
          icon: const Icon(Icons.delete_outline, size: 20),
          tooltip: 'Delete',
          style: IconButton.styleFrom(
            backgroundColor: colorScheme.errorContainer,
            foregroundColor: colorScheme.onErrorContainer,
            minimumSize: const Size(36, 36),
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }

  // -- Actions -----------------------------------------------------------

  void _toggleActive() {
    ref
        .read(subscriptionsNotifierProvider.notifier)
        .toggleActive(widget.subscription.id);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await ConfirmDeleteDialog.show(
      context: context,
      title: 'Delete Subscription',
      itemName: widget.subscription.name,
    );

    if (confirmed == true && mounted) {
      final deleted = widget.subscription;

      await ref.read(subscriptionsNotifierProvider.notifier).delete(deleted.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${deleted.name}" deleted'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                ref.read(subscriptionsNotifierProvider.notifier).create(
                      name: deleted.name,
                      description: deleted.description,
                      amount: deleted.amount,
                      currency: deleted.currency,
                      billingCycle: deleted.billingCycle,
                      category: deleted.category,
                      startDate: deleted.startDate,
                      url: deleted.url,
                      reminderDaysBefore: deleted.reminderDaysBefore,
                    );
              },
            ),
          ),
        );
      }
    }
  }

  // -- Helpers -----------------------------------------------------------

  String _formatNextBilling() {
    final days = widget.subscription.daysUntilNextBilling;

    if (days == 0) return 'Due today';
    if (days == 1) return 'Due tomorrow';
    if (days < 0) return 'Overdue';
    if (days <= 7) return 'Due in $days days';

    return widget.subscription.nextBillingDate.formatted;
  }
}
