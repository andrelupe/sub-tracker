import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:subtracker/features/settings/models/user_settings.dart';
import 'package:subtracker/features/settings/providers/user_settings_providers.dart';

/// Dropdown selector for the user's base currency preference.
class CurrencySelector extends ConsumerWidget {
  const CurrencySelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(userSettingsNotifierProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Currency',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Base Currency',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'All totals will be converted to this currency',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 12),
                settingsAsync.when(
                  data: (settings) => _CurrencyDropdown(
                    currentCurrency: settings.baseCurrency,
                    onChanged: (currency) {
                      if (currency != null) {
                        ref
                            .read(userSettingsNotifierProvider.notifier)
                            .updateBaseCurrency(currency);
                      }
                    },
                  ),
                  loading: () => const SizedBox(
                    height: 48,
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
                  error: (error, _) => Text(
                    'Failed to load settings',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CurrencyDropdown extends StatelessWidget {
  const _CurrencyDropdown({
    required this.currentCurrency,
    required this.onChanged,
  });

  final String currentCurrency;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<String>(
        segments: UserSettings.supportedCurrencies.map((currency) {
          final symbol = UserSettings.currencySymbol(currency);
          return ButtonSegment(
            value: currency,
            label: Text('$symbol $currency'),
            icon: const Icon(Icons.currency_exchange),
          );
        }).toList(),
        selected: {currentCurrency},
        onSelectionChanged: (selection) => onChanged(selection.first),
      ),
    );
  }
}
