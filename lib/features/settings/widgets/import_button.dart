import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subtracker/core/providers/api_providers.dart';
import 'package:subtracker/features/settings/services/file_service.dart';
import 'package:subtracker/features/subscriptions/providers/subscription_providers.dart';

/// Button that imports subscriptions from a JSON file.
class ImportButton extends ConsumerStatefulWidget {
  const ImportButton({super.key});

  @override
  ConsumerState<ImportButton> createState() => _ImportButtonState();
}

class _ImportButtonState extends ConsumerState<ImportButton> {
  bool _isLoading = false;

  Future<void> _import() async {
    setState(() => _isLoading = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final file = result.files.first;
      final String jsonContent;

      if (file.bytes != null) {
        jsonContent = utf8.decode(file.bytes!);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Could not read file contents'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return;
      }

      const fileService = FileService();
      final validated = fileService.validateImportJson(jsonContent);

      if (validated == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Invalid file format. Expected a JSON array of subscriptions.',
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return;
      }

      if (!mounted) return;

      final confirmed = await _showConfirmDialog(validated.length);
      if (confirmed != true) return;

      final apiService = ref.read(subscriptionApiServiceProvider);
      await apiService.importSubscriptions(validated);

      ref.invalidate(subscriptionsNotifierProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported ${validated.length} subscriptions'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $error'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool?> _showConfirmDialog(int count) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Subscriptions'),
        content: Text(
          'This will import $count subscription${count != 1 ? 's' : ''}. '
          'Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Import'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.download),
      title: const Text('Import Data'),
      subtitle: const Text('Load subscriptions from JSON file'),
      trailing: _isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chevron_right),
      onTap: _isLoading ? null : _import,
    );
  }
}
