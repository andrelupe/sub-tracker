import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subtracker/core/providers/api_providers.dart';
import 'package:subtracker/features/settings/services/file_service.dart';

/// Button that exports all subscriptions as a JSON file.
class ExportButton extends ConsumerStatefulWidget {
  const ExportButton({super.key});

  @override
  ConsumerState<ExportButton> createState() => _ExportButtonState();
}

class _ExportButtonState extends ConsumerState<ExportButton> {
  bool _isLoading = false;

  Future<void> _export() async {
    setState(() => _isLoading = true);

    try {
      final apiService = ref.read(subscriptionApiServiceProvider);
      final subscriptions = await apiService.getAllSubscriptions();

      const fileService = FileService();
      final jsonContent = fileService.formatExportJson(subscriptions);
      final filename = fileService.exportFilename;

      if (kIsWeb) {
        fileService.downloadJsonWeb(jsonContent, filename);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Exported ${subscriptions.length} subscriptions to $filename',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $error'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.upload_file),
      title: const Text('Export Data'),
      subtitle: const Text('Download subscriptions as JSON'),
      trailing: _isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.download_outlined),
      onTap: _isLoading ? null : _export,
    );
  }
}
