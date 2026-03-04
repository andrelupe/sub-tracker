import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:subtracker/core/providers/api_providers.dart';
import 'package:subtracker/features/exchange_rates/models/exchange_rate.dart';
import 'package:subtracker/features/exchange_rates/services/exchange_rate_api_service.dart';
import 'package:subtracker/features/settings/providers/user_settings_providers.dart';

part 'exchange_rate_providers.g.dart';

/// Provides the [ExchangeRateApiService] instance.
@riverpod
ExchangeRateApiService exchangeRateApiService(ExchangeRateApiServiceRef ref) {
  final apiService = ref.read(apiServiceProvider);
  return ExchangeRateApiService(apiService);
}

/// Fetches and caches exchange rates for the user's base currency.
///
/// Rates are kept alive to avoid refetching on every screen transition.
/// Automatically rebuilds when the base currency changes.
@Riverpod(keepAlive: true)
class ExchangeRatesNotifier extends _$ExchangeRatesNotifier {
  @override
  Future<ExchangeRate> build() async {
    final service = ref.read(exchangeRateApiServiceProvider);
    final baseCurrency = ref.watch(baseCurrencyProvider);
    return service.getRates(baseCurrency: baseCurrency);
  }

  /// Force refresh rates from the API.
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
