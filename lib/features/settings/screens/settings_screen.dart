import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:subtracker/core/widgets/centered_content.dart';
import 'package:subtracker/core/widgets/responsive_layout.dart';
import 'package:subtracker/features/settings/widgets/about_section.dart';
import 'package:subtracker/features/settings/widgets/export_button.dart';
import 'package:subtracker/features/settings/widgets/import_button.dart';
import 'package:subtracker/features/settings/widgets/theme_selector.dart';

/// Settings screen with theme selection, data management and about info.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !isDesktop,
        titleSpacing: isDesktop ? 0 : null,
        title: isDesktop
            ? CenteredContent(
                maxWidth: 1100,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.pop(),
                      tooltip: 'Back',
                    ),
                    const SizedBox(width: 8),
                    const Text('Settings'),
                  ],
                ),
              )
            : const Text('Settings'),
      ),
      body: CenteredContent(
        maxWidth: 600,
        padding: EdgeInsets.zero,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 16),
          children: [
            const ThemeSelector(),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Data',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const ExportButton(),
                  Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  const ImportButton(),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const AboutSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
