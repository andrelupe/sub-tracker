import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:subtracker/core/providers/api_providers.dart';
import 'package:subtracker/features/settings/models/user_settings.dart';
import 'package:subtracker/features/settings/services/settings_api_service.dart';

part 'user_settings_providers.g.dart';

/// Provides the [SettingsApiService] instance.
@riverpod
SettingsApiService settingsApiService(SettingsApiServiceRef ref) {
  final apiService = ref.read(apiServiceProvider);
  return SettingsApiService(apiService);
}

/// Manages user settings (base currency) with API persistence.
@Riverpod(keepAlive: true)
class UserSettingsNotifier extends _$UserSettingsNotifier {
  @override
  Future<UserSettings> build() async {
    final service = ref.read(settingsApiServiceProvider);
    return service.getSettings();
  }

  /// Updates the base currency and refreshes exchange rates.
  Future<void> updateBaseCurrency(String currency) async {
    final service = ref.read(settingsApiServiceProvider);
    await service.updateBaseCurrency(currency);

    ref.invalidateSelf();
    await future;
  }
}

/// Derived provider that exposes just the base currency string.
/// Falls back to 'EUR' while loading or on error.
@riverpod
String baseCurrency(BaseCurrencyRef ref) {
  final settingsAsync = ref.watch(userSettingsNotifierProvider);
  return settingsAsync.when(
    data: (settings) => settings.baseCurrency,
    loading: () => 'EUR',
    error: (_, __) => 'EUR',
  );
}
