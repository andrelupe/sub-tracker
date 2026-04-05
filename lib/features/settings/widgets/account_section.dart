import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subtracker/features/auth/providers/auth_providers.dart';
import 'package:subtracker/features/settings/widgets/change_password_dialog.dart';

/// Account section displayed at the top of the Settings screen.
///
/// Shows the user's email, role badge, a change-password button,
/// and a logout button with confirmation dialog.
class AccountSection extends ConsumerWidget {
  const AccountSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Account',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text('Email'),
                trailing: Text(
                  user.email,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: theme.colorScheme.outlineVariant,
              ),
              ListTile(
                leading: const Icon(Icons.badge_outlined),
                title: const Text('Role'),
                trailing: _RoleBadge(role: user.role),
              ),
              Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: theme.colorScheme.outlineVariant,
              ),
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Change Password'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (_) => const ChangePasswordDialog(),
                ),
              ),
              Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: theme.colorScheme.outlineVariant,
              ),
              ListTile(
                leading: Icon(
                  Icons.logout,
                  color: theme.colorScheme.error,
                ),
                title: Text(
                  'Logout',
                  style: TextStyle(color: theme.colorScheme.error),
                ),
                onTap: () => _confirmLogout(context, ref),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ref.read(authNotifierProvider.notifier).logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == 'Admin';
    final theme = Theme.of(context);

    return Chip(
      label: Text(role),
      labelStyle: theme.textTheme.labelSmall?.copyWith(
        color: isAdmin
            ? theme.colorScheme.onTertiaryContainer
            : theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: isAdmin
          ? theme.colorScheme.tertiaryContainer
          : theme.colorScheme.surfaceContainerHighest,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }
}
