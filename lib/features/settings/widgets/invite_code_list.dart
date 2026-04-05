import 'package:flutter/material.dart';
import 'package:subtracker/features/auth/models/invite_code.dart';

/// Compact list of invite codes showing status and usage info.
///
/// Each row displays the code, a status chip (Available/Used), and
/// the email of the user who used it (if applicable).
class InviteCodeList extends StatelessWidget {
  const InviteCodeList({
    required this.codes,
    super.key,
  });

  final List<InviteCode> codes;

  @override
  Widget build(BuildContext context) {
    if (codes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No invite codes yet',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }

    return Column(
      children: codes.map((code) => _InviteCodeRow(code: code)).toList(),
    );
  }
}

class _InviteCodeRow extends StatelessWidget {
  const _InviteCodeRow({required this.code});

  final InviteCode code;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              code.code,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          if (code.isUsed) ...[
            Chip(
              label: const Text('Used'),
              labelStyle: theme.textTheme.labelSmall,
              backgroundColor: theme.colorScheme.errorContainer,
              side: BorderSide.none,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                code.usedByEmail ?? '',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ] else
            Chip(
              label: const Text('Available'),
              labelStyle: theme.textTheme.labelSmall,
              backgroundColor: theme.colorScheme.primaryContainer,
              side: BorderSide.none,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }
}
