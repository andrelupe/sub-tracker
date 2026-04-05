import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Dialog that displays a generated invite code with a copy button.
///
/// Shown after the admin successfully generates a new invite code.
class GenerateInviteDialog extends StatelessWidget {
  const GenerateInviteDialog({
    required this.code,
    super.key,
  });

  final String code;

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: code));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Invite code copied to clipboard'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Invite Code Generated'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Share this code with the new user to register:'),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SelectableText(
                    code,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  tooltip: 'Copy code',
                  onPressed: () => _copyToClipboard(context),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
