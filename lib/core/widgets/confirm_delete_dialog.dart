import 'package:flutter/material.dart';

class ConfirmDeleteDialog extends StatelessWidget {
  const ConfirmDeleteDialog({
    super.key,
    this.title = 'Delete',
    required this.itemName,
    this.message,
  });

  final String title;
  final String itemName;
  final String? message;

  static Future<bool?> show({
    required BuildContext context,
    String title = 'Delete',
    required String itemName,
    String? message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => ConfirmDeleteDialog(
        title: title,
        itemName: itemName,
        message: message,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: Text(title),
      content: Text(
        message ?? 'Are you sure you want to delete "$itemName"?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
          ),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
